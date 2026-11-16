import 'dart:typed_data';

import '../core/config/nyooom_config.dart';
import '../core/events/event_detector.dart';
import '../core/model/acoustics.dart';
import '../core/pipeline/analysis_setup.dart';
import '../core/pipeline/doppler.dart';
import '../core/pipeline/doppler_sharpness.dart';
import '../core/pipeline/event_evaluator.dart';
import '../core/pipeline/fusion.dart';
import '../core/pipeline/pass_record.dart';
import '../core/signal/pcm.dart';

/// Complete evaluation of one event window as used by the offline analysis
/// and the live mode: TDOA (Task_09), Doppler (Task_10), fusion (Task_11).
class EventPipeline {
  EventPipeline({required this.config, required this.setup})
    : _evaluator = EventEvaluator(config: config, setup: setup),
      _doppler = DopplerEstimator(
        config: config,
        speedOfSound: setup.speedOfSound,
      ),
      _sharpness = SharpnessEstimator(
        config: config,
        speedOfSound: setup.speedOfSound,
      );

  final NyooomConfig config;
  final AnalysisSetup setup;
  final EventEvaluator _evaluator;
  final DopplerEstimator _doppler;
  final SharpnessEstimator _sharpness;

  PassRecord evaluate(
    StereoBlock window,
    PassEvent event, {
    required double windowStartS,
  }) {
    final analysis = _evaluator.analyse(
      window,
      event,
      windowStartS: windowStartS,
    );
    final record = analysis.record;
    final fit = analysis.fit, fitter = analysis.fitter;
    if (record.klasse == QualityClass.c || fit == null || fitter == null) {
      return record;
    }
    // u(t) always from the smooth model curve (technik.pdf 5.4).
    double u(double t) =>
        (fitter.tdoaAt(t, kappa: fit.kappa, t0: fit.t0) - setup.channelOffset) /
        setup.maxTdoa;
    final doppler = _doppler.estimate(
      analysis.signal,
      windowStartS: windowStartS,
      receptionT0: fit.t0 + record.distanceUsedM! / setup.speedOfSound,
      directionCosine: u,
    );
    DopplerChoice? v1;
    if (doppler.hasTone) {
      v1 = DopplerChoice(
        speed: doppler.speed!,
        sigma: doppler.sigma!,
        toneCount: doppler.toneCount,
        variant: 1,
        speedWithAcceleration: doppler.speedWithAcceleration,
      );
    }
    DopplerChoice? v2;
    if (v1 == null && config.dopplerVariant2 != 0) {
      final sum = Float64List(analysis.signal.length);
      for (var i = 0; i < sum.length; i++) {
        sum[i] = 0.5 * (analysis.signal.left[i] + analysis.signal.right[i]);
      }
      final sharp = _sharpness.estimate(
        sum,
        windowStartS: windowStartS,
        kappa: fit.kappa,
        t0: fit.t0,
      );
      if (sharp.hasTone) {
        v2 = DopplerChoice(
          speed: sharp.speed!,
          sigma: sharp.sigma!,
          toneCount: 0,
          variant: 2,
        );
      }
    }
    final choice = chooseDoppler(
      v1: v1,
      v2: v2,
      variant2Enabled: config.dopplerVariant2 != 0,
    );
    // Without tone the TDOA record (class B, "kein Ton") stays unchanged.
    if (choice == null) return record;
    final fusion = fuse(
      config: config,
      vT: fromKmh(record.vLaufzeit!),
      sigmaT: fromKmh(record.sigmaLaufzeit!),
      kappa: fit.kappa,
      laneDistance: record.distanceUsedM!,
      vD: choice.speed,
      sigmaD: choice.sigma,
      vDWithAcceleration: choice.speedWithAcceleration,
    );
    return record.copyWith(
      klasse: fusion.klasse,
      reason: fusion.reason,
      clearReason: fusion.reason == null,
      v: toKmh(fusion.v),
      sigmaV: toKmh(fusion.sigma),
      vDoppler: toKmh(choice.speed),
      sigmaDoppler: toKmh(choice.sigma),
      nToene: choice.toneCount,
      dEst: fusion.dEst,
    );
  }
}

import '../core/config/nyooom_config.dart';
import '../core/events/event_detector.dart';
import '../core/model/acoustics.dart';
import '../core/pipeline/analysis_setup.dart';
import '../core/pipeline/doppler.dart';
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
      );

  final NyooomConfig config;
  final AnalysisSetup setup;
  final EventEvaluator _evaluator;
  final DopplerEstimator _doppler;

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
    // Without tone the TDOA record (class B, "kein Ton") stays unchanged.
    if (!doppler.hasTone) return record;
    final fusion = fuse(
      config: config,
      vT: fromKmh(record.vLaufzeit!),
      sigmaT: fromKmh(record.sigmaLaufzeit!),
      kappa: fit.kappa,
      laneDistance: record.distanceUsedM!,
      vD: doppler.speed,
      sigmaD: doppler.sigma,
      vDWithAcceleration: doppler.speedWithAcceleration,
    );
    return record.copyWith(
      klasse: fusion.klasse,
      reason: fusion.reason,
      clearReason: fusion.reason == null,
      v: toKmh(fusion.v),
      sigmaV: toKmh(fusion.sigma),
      vDoppler: toKmh(doppler.speed!),
      sigmaDoppler: toKmh(doppler.sigma!),
      nToene: doppler.toneCount,
      dEst: fusion.dEst,
    );
  }
}

import 'dart:math' as math;
import 'dart:typed_data';

import '../config/nyooom_config.dart';
import '../dsp/gcc_phat.dart';
import '../events/event_detector.dart';
import '../model/acoustics.dart';
import '../signal/pcm.dart';
import 'analysis_setup.dart';
import 'motion_fit.dart';
import 'pass_record.dart';
import 'reasons.dart';

/// σ_T of the TDOA speed (technik.pdf 5.5):
/// σ_T² = v_T²·[(σκ/κ)² + (σd/d_Spur)²]. Speeds in m/s.
double laufzeitSigma({
  required double speed,
  required double kappa,
  required double sigmaKappa,
  required double laneDistance,
  required double lateralSpread,
}) =>
    speed.abs() *
    math.sqrt(
      math.pow(sigmaKappa / kappa, 2) +
          math.pow(lateralSpread / laneDistance, 2),
    );

/// Intermediate results of one event, kept for later stages (Doppler).
class EventAnalysis {
  const EventAnalysis({
    required this.record,
    required this.signal,
    required this.windowStartS,
    this.fit,
    this.fitter,
    this.correlogram,
  });

  final PassRecord record;

  /// Window signal (channels already swapped if needed).
  final StereoBlock signal;
  final double windowStartS;
  final MotionFit? fit;
  final MotionFitter? fitter;
  final Correlogram? correlogram;
}

/// Evaluates one detected event by TDOA alone: correlogram, motion model,
/// v_T = κ·d_Spur, class B or C (technik.pdf 5.2, 5.3, 5.5, 5.6).
class EventEvaluator {
  EventEvaluator({required this.config, required this.setup});

  final NyooomConfig config;
  final AnalysisSetup setup;

  PassRecord evaluate(
    StereoBlock window,
    PassEvent event, {
    required double windowStartS,
  }) => analyse(window, event, windowStartS: windowStartS).record;

  EventAnalysis analyse(
    StereoBlock window,
    PassEvent event, {
    required double windowStartS,
  }) {
    final signal = setup.swapChannels ? window.swapped : window;

    PassRecord rejected(DowngradeReason reason, {MotionFit? fit}) {
      final t0 = fit?.t0 ?? event.peakTimeS;
      return PassRecord(
        zeitUtcMs: setup.startedAtUtcMs + (t0 * 1000).round(),
        offsetS: t0,
        richtung: fit?.direction ?? 0,
        klasse: QualityClass.c,
        v: null,
        sigmaV: null,
        vLaufzeit: null,
        vDoppler: null,
        kappa: fit != null && fit.kappa.isFinite ? fit.kappa : null,
        dEst: null,
        nToene: 0,
        restLaufzeitUs: fit != null && fit.residualS.isFinite
            ? fit.residualS * 1e6
            : null,
        pegel: event.levelAboveFloorDb,
        dauer: event.durationS,
        reason: reason,
        laneIndex: null,
        distanceUsedM: null,
      );
    }

    if (event.overlap) {
      return EventAnalysis(
        record: rejected(DowngradeReason.overlap),
        signal: signal,
        windowStartS: windowStartS,
      );
    }
    if (_peak(signal) > config.clipThreshold) {
      return EventAnalysis(
        record: rejected(DowngradeReason.clipping),
        signal: signal,
        windowStartS: windowStartS,
      );
    }

    final correlogram = GccPhat(
      config: config,
      micSpacing: setup.micSpacing,
      speedOfSound: setup.speedOfSound,
    ).correlogram(signal);
    final fitter = MotionFitter(
      config: config,
      maxTdoa: setup.maxTdoa,
      channelOffset: setup.channelOffset,
      speedOfSound: setup.speedOfSound,
      laneDistance: (direction) =>
          (setup.laneFor(direction) ?? setup.lanes.first).slantDistance,
    );
    final fit = fitter.fit(
      correlogram,
      timeOffsetS: windowStartS,
      peakTimeS: event.peakTimeS,
    );
    final reason = fit.reason;
    if (reason != null) {
      return EventAnalysis(
        record: rejected(reason, fit: fit),
        signal: signal,
        windowStartS: windowStartS,
        fit: fit,
        fitter: fitter,
        correlogram: correlogram,
      );
    }
    final lane = setup.laneFor(fit.direction);
    if (lane == null) {
      return EventAnalysis(
        record: rejected(DowngradeReason.noLane, fit: fit),
        signal: signal,
        windowStartS: windowStartS,
        fit: fit,
        fitter: fitter,
        correlogram: correlogram,
      );
    }
    final vT = fit.kappa.abs() * lane.slantDistance;
    final sigmaT = laufzeitSigma(
      speed: vT,
      kappa: fit.kappa,
      sigmaKappa: fit.sigmaKappa,
      laneDistance: lane.slantDistance,
      lateralSpread: config.lateralSpreadM,
    );
    final record = PassRecord(
      zeitUtcMs: setup.startedAtUtcMs + (fit.t0 * 1000).round(),
      offsetS: fit.t0,
      richtung: fit.direction,
      klasse: QualityClass.b,
      v: toKmh(vT),
      sigmaV: toKmh(sigmaT),
      vLaufzeit: toKmh(vT),
      vDoppler: null,
      kappa: fit.kappa,
      dEst: null,
      nToene: 0,
      restLaufzeitUs: fit.residualS * 1e6,
      pegel: event.levelAboveFloorDb,
      dauer: event.durationS,
      // Class B until a Doppler estimate upgrades it (Task_10/11).
      reason: DowngradeReason.noTone,
      laneIndex: lane.index,
      distanceUsedM: lane.slantDistance,
      sigmaLaufzeit: toKmh(sigmaT),
    );
    return EventAnalysis(
      record: record,
      signal: signal,
      windowStartS: windowStartS,
      fit: fit,
      fitter: fitter,
      correlogram: correlogram,
    );
  }

  static double _peak(StereoBlock s) {
    var peak = 0.0;
    for (var i = 0; i < s.length; i++) {
      peak = math.max(peak, math.max(s.left[i].abs(), s.right[i].abs()));
    }
    return peak;
  }
}

/// Cuts the window of [event] out of [signal] (times relative to its start).
StereoBlock windowOf(StereoBlock signal, PassEvent event, int sampleRate) {
  final from = (event.windowStartS * sampleRate).round().clamp(
    0,
    signal.length,
  );
  final to = (event.windowEndS * sampleRate).round().clamp(from, signal.length);
  return StereoBlock(
    Float64List.sublistView(signal.left, from, to),
    Float64List.sublistView(signal.right, from, to),
  );
}

/// Detects and evaluates all events of a complete signal.
List<PassRecord> evaluateSignal(
  StereoBlock signal, {
  required NyooomConfig config,
  required AnalysisSetup setup,
}) {
  final evaluator = EventEvaluator(config: config, setup: setup);
  return [
    for (final e in detectEvents(signal, config: config))
      evaluator.evaluate(
        windowOf(signal, e, config.sampleRate),
        e,
        windowStartS:
            (e.windowStartS * config.sampleRate).round() / config.sampleRate,
      ),
  ];
}

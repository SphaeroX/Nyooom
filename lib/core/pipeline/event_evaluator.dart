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
    this.ambiguousTones = false,
  });

  /// A second vehicle passes at the same time: tones in the window cannot
  /// be assigned to one of the two (no Doppler step).
  final bool ambiguousTones;

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

  /// Evaluation by the letter of technik.pdf 5.1: one result per event, an
  /// overlap is class C without looking at the correlogram.
  EventAnalysis analyse(
    StereoBlock window,
    PassEvent event, {
    required double windowStartS,
  }) {
    final signal = setup.swapChannels ? window.swapped : window;
    if (event.overlap) {
      return EventAnalysis(
        record: _rejected(event, DowngradeReason.overlap),
        signal: signal,
        windowStartS: windowStartS,
      );
    }
    if (_peak(signal) > config.clipThreshold) {
      return EventAnalysis(
        record: _rejected(event, DowngradeReason.clipping),
        signal: signal,
        windowStartS: windowStartS,
      );
    }
    final correlogram = _correlogram(signal);
    final fitter = _fitter();
    final fit = fitter.fit(
      correlogram,
      timeOffsetS: windowStartS,
      peakTimeS: event.peakTimeS,
    );
    return EventAnalysis(
      record: _recordOf(event, fit),
      signal: signal,
      windowStartS: windowStartS,
      fit: fit,
      fitter: fitter,
      correlogram: correlogram,
    );
  }

  /// Evaluation with track separation: every vehicle that leaves its own S
  /// curve in the correlogram of the window gets a result.
  ///
  /// - The t0 search of the event is bounded by the midpoints to the
  ///   neighbouring level maxima, so each maximum finds its own vehicle.
  /// - With the first track left out, a second one of the opposite
  ///   direction is searched (oncoming traffic at the same time, which has
  ///   only one level maximum). A mirror image of the first track (same
  ///   |κ| and t0, reflection at a side wall) is not a vehicle.
  /// - An overlap that cannot be resolved stays class C "Überlappung"
  ///   (technik.pdf 5.1). A secondary event without a valid track of its
  ///   own gives no result: it was a ripple in the level of a vehicle that
  ///   its neighbouring event reports.
  List<EventAnalysis> analyseTracks(
    StereoBlock window,
    PassEvent event, {
    required double windowStartS,
  }) {
    final signal = setup.swapChannels ? window.swapped : window;
    EventAnalysis failed(DowngradeReason reason) => EventAnalysis(
      record: _rejected(event, reason),
      signal: signal,
      windowStartS: windowStartS,
    );
    if (_peak(signal) > config.clipThreshold) {
      return event.secondary ? const [] : [failed(DowngradeReason.clipping)];
    }
    double? t0Min, t0Max;
    for (final neighbour in event.neighbourPeakTimesS) {
      final gap = neighbour - event.peakTimeS;
      if (gap.abs() < config.trackMinSeparationS) continue;
      final middle = event.peakTimeS + gap / 2;
      if (gap < 0) {
        t0Min = t0Min == null ? middle : math.max(t0Min, middle);
      } else {
        t0Max = t0Max == null ? middle : math.min(t0Max, middle);
      }
    }
    final correlogram = _correlogram(signal);
    final fitter = _fitter();
    final first = fitter.fit(
      correlogram,
      timeOffsetS: windowStartS,
      peakTimeS: event.peakTimeS,
      t0MinS: t0Min,
      t0MaxS: t0Max,
      othersPresent: event.overlap || event.neighbourPeakTimesS.isNotEmpty,
    );
    EventAnalysis track(MotionFit fit, {bool ambiguous = false}) =>
        EventAnalysis(
          record: _recordOf(event, fit),
          signal: signal,
          windowStartS: windowStartS,
          fit: fit,
          fitter: fitter,
          correlogram: correlogram,
          ambiguousTones: ambiguous,
        );
    // The fine fit is free: a track that ends beyond the midpoint or
    // outside the search range around the level maximum belongs to a
    // neighbouring maximum and is reported by its event.
    bool isOutside(MotionFit fit) =>
        (t0Min != null && fit.t0 < t0Min) ||
        (t0Max != null && fit.t0 > t0Max) ||
        (fit.t0 - event.peakTimeS).abs() > config.t0SearchRangeS;
    final outside = isOutside(first);
    if (first.reason != null || outside) {
      if (event.secondary) return const [];
      return [
        event.overlap || outside
            ? failed(DowngradeReason.overlap)
            : track(first),
      ];
    }
    final second = fitter.fit(
      correlogram,
      timeOffsetS: windowStartS,
      peakTimeS: event.peakTimeS,
      t0MinS: t0Min,
      t0MaxS: t0Max,
      direction: -first.direction,
      exclude: [first.curve],
      othersPresent: true,
    );
    final mirror =
        (second.kappa.abs() / first.kappa.abs() - 1).abs() <=
            config.mirrorKappaTolerance &&
        (second.t0 - first.t0).abs() <= config.mirrorT0ToleranceS;
    if (second.reason != null || mirror || isOutside(second)) {
      return [track(first)];
    }
    return [track(first, ambiguous: true), track(second, ambiguous: true)];
  }

  Correlogram _correlogram(StereoBlock signal) => GccPhat(
    config: config,
    micSpacing: setup.micSpacing,
    speedOfSound: setup.speedOfSound,
  ).correlogram(signal);

  MotionFitter _fitter() => MotionFitter(
    config: config,
    maxTdoa: setup.maxTdoa,
    channelOffset: setup.channelOffset,
    speedOfSound: setup.speedOfSound,
    laneDistance: (direction) =>
        (setup.laneFor(direction) ?? setup.lanes.first).slantDistance,
  );

  PassRecord _rejected(
    PassEvent event,
    DowngradeReason reason, {
    MotionFit? fit,
  }) {
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

  /// Record of a fitted track: class C with the reason of the fit, or
  /// class B with v_T = |κ|·d_Spur (technik.pdf 5.5).
  PassRecord _recordOf(PassEvent event, MotionFit fit) {
    final reason = fit.reason;
    if (reason != null) return _rejected(event, reason, fit: fit);
    final lane = setup.laneFor(fit.direction);
    if (lane == null) {
      return _rejected(event, DowngradeReason.noLane, fit: fit);
    }
    final vT = fit.kappa.abs() * lane.slantDistance;
    final sigmaT = laufzeitSigma(
      speed: vT,
      kappa: fit.kappa,
      sigmaKappa: fit.sigmaKappa,
      laneDistance: lane.slantDistance,
      lateralSpread: config.lateralSpreadM,
    );
    return PassRecord(
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

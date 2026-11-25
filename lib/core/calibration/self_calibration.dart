import 'dart:math' as math;

import '../config/nyooom_config.dart';
import '../model/acoustics.dart';
import '../pipeline/analysis_setup.dart';
import '../pipeline/event_evaluator.dart';
import '../pipeline/fusion.dart';
import '../pipeline/pass_record.dart';
import '../pipeline/reasons.dart';

/// Learned effective distance of one lane (technik.pdf 7.4).
class LaneLearning {
  const LaneLearning({
    required this.lane,
    required this.measuredDistance,
    required this.countA,
    required this.learnedDistance,
    required this.active,
    this.warnFraction = 0.2,
  });

  final int lane;

  /// Slant distance from the tape measure (7.2).
  final double measuredDistance;
  final int countA;

  /// Median of d_est of the class-A records, null without any.
  final double? learnedDistance;

  /// Enough class-A records: the learned value replaces the measured one.
  final bool active;
  final double warnFraction;

  double get effectiveDistance => active ? learnedDistance! : measuredDistance;

  /// Relative deviation learned/measured − 1.
  double? get deviation =>
      learnedDistance == null ? null : learnedDistance! / measuredDistance - 1;

  /// Deviation above the limit: lane assignment, b or the microphone axis
  /// are probably wrong (7.4).
  bool get warning => deviation != null && deviation!.abs() > warnFraction;
}

/// Median of d_est per lane over the class-A [records] (all series of a
/// site, decision Task_18).
List<LaneLearning> learnLaneDistances(
  List<PassRecord> records, {
  required List<LaneGeometry> lanes,
  required NyooomConfig config,
}) => [
  for (final lane in lanes)
    () {
      final d = [
        for (final r in records)
          if (r.klasse == QualityClass.a &&
              r.laneIndex == lane.index &&
              r.dEst != null)
            r.dEst!,
      ]..sort();
      final median = d.isEmpty
          ? null
          : d.length.isOdd
          ? d[d.length ~/ 2]
          : 0.5 * (d[d.length ~/ 2 - 1] + d[d.length ~/ 2]);
      return LaneLearning(
        lane: lane.index,
        measuredDistance: lane.slantDistance,
        countA: d.length,
        learnedDistance: median,
        active: d.length >= config.selfCalibrationMinCount,
        warnFraction: config.selfCalibrationWarnFraction,
      );
    }(),
];

/// [setup] with the effective (learned) distance for active lanes.
AnalysisSetup withLearnedDistances(
  AnalysisSetup setup,
  List<LaneLearning> learning,
) => AnalysisSetup(
  micSpacing: setup.micSpacing,
  channelOffset: setup.channelOffset,
  swapChannels: setup.swapChannels,
  speedOfSound: setup.speedOfSound,
  speedLimitKmh: setup.speedLimitKmh,
  startedAtUtcMs: setup.startedAtUtcMs,
  segments: setup.segments,
  temperatureLog: setup.temperatureLog,
  lanes: [
    for (final lane in setup.lanes)
      LaneGeometry(
        index: lane.index,
        direction: lane.direction,
        slantDistance:
            learning
                .where((l) => l.lane == lane.index && l.active)
                .map((l) => l.learnedDistance!)
                .firstOrNull ??
            lane.slantDistance,
      ),
  ],
);

/// Recomputes v_T, σ_T and the fusion of an existing record with another
/// lane distance (7.4). Class C stays untouched; an acceleration verdict is
/// kept because the record does not store the second regression.
PassRecord recomputeWithDistance(
  PassRecord r,
  double distance,
  NyooomConfig config,
) {
  if (r.klasse == QualityClass.c ||
      r.kappa == null ||
      r.sigmaLaufzeit == null) {
    return r;
  }
  final oldDistance = r.distanceUsedM ?? distance;
  final kappa = r.kappa!;
  final vT = kappa.abs() * distance;
  // σκ follows from the stored σ_T and the old distance (5.5).
  final oldVT = fromKmh(r.vLaufzeit!);
  final oldSigmaT = fromKmh(r.sigmaLaufzeit!);
  final relLateralOld = config.lateralSpreadM / oldDistance;
  final relKappaSq =
      (oldSigmaT / oldVT) * (oldSigmaT / oldVT) - relLateralOld * relLateralOld;
  final sigmaKappa = kappa.abs() * math.sqrt(math.max(0, relKappaSq));
  final sigmaT = laufzeitSigma(
    speed: vT,
    kappa: kappa,
    sigmaKappa: sigmaKappa,
    laneDistance: distance,
    lateralSpread: config.lateralSpreadM,
  );
  final base = r.copyWith(
    vLaufzeit: toKmh(vT),
    sigmaLaufzeit: toKmh(sigmaT),
    distanceUsedM: distance,
  );
  if (r.vDoppler == null || r.sigmaDoppler == null) {
    return base.copyWith(v: toKmh(vT), sigmaV: toKmh(sigmaT));
  }
  if (r.reason == DowngradeReason.acceleration) {
    return base.copyWith(v: toKmh(vT), sigmaV: toKmh(sigmaT));
  }
  final fusion = fuse(
    config: config,
    vT: vT,
    sigmaT: sigmaT,
    kappa: kappa,
    laneDistance: distance,
    vD: fromKmh(r.vDoppler!),
    sigmaD: fromKmh(r.sigmaDoppler!),
  );
  return base.copyWith(
    klasse: fusion.klasse,
    reason: fusion.reason,
    clearReason: fusion.reason == null,
    v: toKmh(fusion.v),
    sigmaV: toKmh(fusion.sigma),
    dEst: fusion.dEst,
  );
}

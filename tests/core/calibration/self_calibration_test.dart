import 'dart:math' as math;

import 'package:nyooom/core/calibration/self_calibration.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:test/test.dart';

const config = NyooomConfig();
const measured = 5.0;

/// Records of one lane whose vehicles really drive at [effective] m
/// (5 % closer than the tape-measure value): class A with d_est near the
/// effective distance, class B with v_T computed from the measured one.
List<PassRecord> synthetic({
  required int countA,
  required int countB,
  double effective = 4.75,
  int seed = 1,
}) {
  final random = math.Random(seed);
  double gauss() =>
      math.sqrt(-2 * math.log(1 - random.nextDouble())) *
      math.cos(2 * math.pi * random.nextDouble());
  PassRecord make(QualityClass k, double vTrueKmh) {
    final kappa = vTrueKmh / 3.6 / effective;
    final vT = kappa * measured * 3.6;
    return PassRecord(
      zeitUtcMs: 0,
      offsetS: 0,
      richtung: 1,
      klasse: k,
      v: k == QualityClass.a ? vTrueKmh : vT,
      sigmaV: 2,
      vLaufzeit: vT,
      vDoppler: k == QualityClass.a ? vTrueKmh : null,
      kappa: kappa,
      dEst: k == QualityClass.a ? effective + 0.2 * gauss() : null,
      nToene: k == QualityClass.a ? 2 : 0,
      restLaufzeitUs: 5,
      pegel: 20,
      dauer: 1,
      reason: k == QualityClass.b ? DowngradeReason.noTone : null,
      laneIndex: 0,
      distanceUsedM: measured,
      sigmaLaufzeit: 2.7,
      sigmaDoppler: k == QualityClass.a ? 1.9 : null,
    );
  }

  return [
    for (var i = 0; i < countA; i++)
      make(QualityClass.a, 30 + 20 * random.nextDouble()),
    for (var i = 0; i < countB; i++)
      make(QualityClass.b, 30 + 20 * random.nextDouble()),
  ];
}

const lanes = [LaneGeometry(index: 0, direction: 1, slantDistance: measured)];

void main() {
  test('after 30 class-A records the learned distance removes the bias', () {
    final records = synthetic(countA: 30, countB: 40);
    final learning = learnLaneDistances(records, lanes: lanes, config: config);
    final lane = learning.single;
    expect(lane.countA, 30);
    expect(lane.active, isTrue);
    expect(lane.learnedDistance, closeTo(4.75, 0.1));
    expect(lane.effectiveDistance, lane.learnedDistance);
    expect(lane.warning, isFalse);

    double meanErrorB(List<PassRecord> rs) {
      final b = rs.where((r) => r.klasse == QualityClass.b).toList();
      // v_true = κ·effective.
      final errors = [for (final r in b) r.v! / (r.kappa! * 4.75 * 3.6) - 1];
      return errors.reduce((a, c) => a + c) / errors.length;
    }

    expect(meanErrorB(records), closeTo(0.0526, 0.002)); // 5/4.75 − 1
    final corrected = [
      for (final r in records)
        recomputeWithDistance(r, lane.effectiveDistance, config),
    ];
    // The median of 30 values with σ = 0.2 m has a standard error of about
    // 1.25·0.2/√30 ≈ 0.05 m (1 %), so "largely removed" means below 2 %.
    expect(meanErrorB(corrected).abs(), lessThan(0.02));
    expect(corrected.first.distanceUsedM, lane.effectiveDistance);
  });

  test('with fewer than 30 class-A records the measured value stays', () {
    final lane = learnLaneDistances(
      synthetic(countA: 29, countB: 10),
      lanes: lanes,
      config: config,
    ).single;
    expect(lane.active, isFalse);
    expect(lane.effectiveDistance, measured);
    expect(lane.learnedDistance, isNotNull);
  });

  test('a deviation above 20 % raises a warning', () {
    final lane = learnLaneDistances(
      synthetic(countA: 35, countB: 0, effective: 3.8),
      lanes: lanes,
      config: config,
    ).single;
    expect(lane.warning, isTrue);
    expect(lane.deviation, closeTo(-0.24, 0.03));
  });

  test('recompute keeps class and reason logic consistent', () {
    final a = synthetic(countA: 1, countB: 0).single;
    // Lane distance far off: d_est no longer within ±25 % → class B.
    final moved = recomputeWithDistance(a, 7, config);
    expect(moved.klasse, QualityClass.b);
    expect(moved.reason, DowngradeReason.distanceCheck);
    final c = PassRecord(
      zeitUtcMs: 0,
      offsetS: 0,
      richtung: 1,
      klasse: QualityClass.c,
      v: null,
      sigmaV: null,
      vLaufzeit: null,
      vDoppler: null,
      kappa: 1,
      dEst: null,
      nToene: 0,
      restLaufzeitUs: 50,
      pegel: 20,
      dauer: 1,
      reason: DowngradeReason.residual,
      laneIndex: 0,
      distanceUsedM: null,
    );
    expect(recomputeWithDistance(c, 4, config).toJson(), c.toJson());
  });

  test('setup with learned distances replaces only active lanes', () {
    const setup = AnalysisSetup(
      micSpacing: 0.15,
      channelOffset: 0,
      swapChannels: false,
      speedOfSound: 343,
      lanes: [
        LaneGeometry(index: 0, direction: 1, slantDistance: 5),
        LaneGeometry(index: 1, direction: -1, slantDistance: 8),
      ],
      speedLimitKmh: 50,
      startedAtUtcMs: 0,
    );
    final learned = withLearnedDistances(setup, [
      const LaneLearning(
        lane: 0,
        measuredDistance: 5,
        countA: 40,
        learnedDistance: 4.8,
        active: true,
      ),
      const LaneLearning(
        lane: 1,
        measuredDistance: 8,
        countA: 3,
        learnedDistance: 7.0,
        active: false,
      ),
    ]);
    expect(learned.lanes[0].slantDistance, 4.8);
    expect(learned.lanes[1].slantDistance, 8);
  });
}

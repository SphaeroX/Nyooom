import 'dart:math' as math;

import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/stats/statistics.dart';
import 'package:test/test.dart';

PassRecord rec(
  double? v, {
  QualityClass klasse = QualityClass.b,
  int direction = 1,
  int lane = 0,
  double sigma = 2,
  DowngradeReason? reason,
  int hour = 10,
}) => PassRecord(
  zeitUtcMs: DateTime.utc(2026, 11, 16, hour).millisecondsSinceEpoch,
  offsetS: 0,
  richtung: direction,
  klasse: klasse,
  v: klasse == QualityClass.c ? null : v,
  sigmaV: klasse == QualityClass.c ? null : sigma,
  vLaufzeit: v,
  vDoppler: null,
  kappa: 1,
  dEst: null,
  nToene: 0,
  restLaufzeitUs: 5,
  pegel: 20,
  dauer: 1,
  reason: reason,
  laneIndex: lane,
  distanceUsedM: 5,
);

void main() {
  group('percentile (linear interpolation between ranks)', () {
    test('odd count', () {
      expect(percentile([30, 10, 20], 0.5), 20);
      // h = 4·0.85 = 3.4 → 40 + 0.4·10
      expect(percentile([10, 20, 30, 40, 50], 0.85), closeTo(44, 1e-12));
    });
    test('even count', () {
      expect(percentile([10, 20, 30, 40], 0.5), 25);
      expect(percentile([10, 20, 30, 40], 0.85), closeTo(35.5, 1e-12));
    });
    test('ties', () {
      expect(percentile([30, 30, 30, 50], 0.5), 30);
      // h = 3·0.85 = 2.55 → 30 + 0.55·20
      expect(percentile([30, 30, 30, 50], 0.85), closeTo(41, 1e-12));
    });
  });

  test('share over the limit counts only strictly faster vehicles', () {
    final s = speedStats([rec(49), rec(50), rec(50.1), rec(60)], limitKmh: 50);
    expect(s.overLimitShare, 0.5);
  });

  test('correction of technik.pdf 8.3: 6 km/h true, 3 km/h error', () {
    final shift = v85Shift(trueSd: 6, measurementSd: 3);
    expect(shift, closeTo(0.7, 0.05));
    final measured = math.sqrt(36 + 9);
    expect(
      correctedSd(measuredSd: measured, measurementSd: 3),
      closeTo(6, 1e-12),
    );
    expect(correctedSd(measuredSd: 2, measurementSd: 3), 0);
  });

  test('speed stats with corrected V85', () {
    final s = speedStats([
      for (final v in <double>[40, 42, 44, 46, 48]) rec(v, sigma: 1),
    ], limitKmh: 45);
    expect(s.count, 5);
    expect(s.mean, 44);
    expect(s.median, 44);
    expect(s.sd, closeTo(math.sqrt(10), 1e-12));
    expect(s.measurementSd, 1);
    expect(s.v85Corrected, lessThan(s.v85Normal!));
    expect(s.overLimitShare, 0.4);
  });

  test('empty groups and single values are handled', () {
    final empty = speedStats([], limitKmh: 50);
    expect(empty.count, 0);
    expect(empty.median, isNull);
    expect(empty.v85, isNull);
    expect(empty.overLimitShare, isNull);
    final one = speedStats([rec(42)], limitKmh: 50);
    expect(one.median, 42);
    expect(one.v85, 42);
    expect(one.sd, isNull);
    expect(one.v85Corrected, isNull);
  });

  test('grouping by class and direction gives consistent sums', () {
    final records = [
      rec(40, klasse: QualityClass.a),
      rec(45, klasse: QualityClass.a, direction: -1, lane: 1),
      rec(50),
      rec(55, direction: -1, lane: 1),
      rec(60, direction: -1, lane: 1),
      rec(null, klasse: QualityClass.c, reason: DowngradeReason.overlap),
      rec(null, klasse: QualityClass.c, reason: DowngradeReason.overlap),
      rec(null, klasse: QualityClass.c, reason: DowngradeReason.residual),
    ];
    final report = StatisticsReport.from(records, limitKmh: 50);
    expect(report.total, 8);
    expect(report.overall.a.count, 2);
    expect(report.overall.b.count, 3);
    expect(report.overall.ab.count, 5);
    expect(report.classC.count, 3);
    expect(report.classC.share, 3 / 8);
    expect(report.classC.reasons, {
      DowngradeReason.overlap: 2,
      DowngradeReason.residual: 1,
    });
    final byDir = report.byDirection;
    expect(byDir[1]!.ab.count + byDir[-1]!.ab.count, 5);
    expect(byDir[-1]!.a.count, 1);
    expect(report.byLane[1]!.ab.count, 3);
    // Hours are local time of the device.
    expect(report.byHour.keys, [DateTime.utc(2026, 11, 16, 10).toLocal().hour]);
  });

  test('histogram separates A and B', () {
    final h = speedHistogram([
      rec(41, klasse: QualityClass.a),
      rec(41.5),
      rec(44),
      rec(null, klasse: QualityClass.c),
    ], binWidthKmh: 2);
    expect(h.map((b) => b.fromKmh), [40, 42, 44]);
    expect(h[0].a, 1);
    expect(h[0].b, 1);
    expect(h[1].a + h[1].b, 0);
    expect(h[2].b, 1);
  });
}

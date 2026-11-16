import 'dart:math' as math;

import '../pipeline/pass_record.dart';
import '../pipeline/reasons.dart';

/// z value of the 85th percentile of the standard normal distribution.
const double z85 = 1.0364333894937898;

/// Percentile with linear interpolation between the closest ranks
/// (h = (n − 1)·p, "type 7", the default of most tools). [p] in 0..1.
double percentile(List<double> values, double p) {
  final s = List<double>.of(values)..sort();
  final h = (s.length - 1) * p;
  final lo = h.floor();
  final hi = math.min(lo + 1, s.length - 1);
  return s[lo] + (h - lo) * (s[hi] - s[lo]);
}

/// True spread from measured spread and measurement uncertainty
/// (technik.pdf 8.3): σ_wahr² = σ_gemessen² − σ_Messung² (0 if negative).
double correctedSd({
  required double measuredSd,
  required double measurementSd,
}) => math.sqrt(
  math.max(0, measuredSd * measuredSd - measurementSd * measurementSd),
);

/// How much too high V85 appears under a normal distribution
/// (technik.pdf 8.3: 6 km/h true, 3 km/h error → about 0.7 km/h).
double v85Shift({required double trueSd, required double measurementSd}) =>
    z85 * (math.sqrt(trueSd * trueSd + measurementSd * measurementSd) - trueSd);

/// Key figures of one group of speeds (km/h).
class SpeedStats {
  const SpeedStats({
    required this.count,
    this.mean,
    this.median,
    this.v85,
    this.sd,
    this.overLimitShare,
    this.measurementSd,
    this.trueSd,
    this.v85Normal,
    this.v85Corrected,
  });

  final int count;
  final double? mean;
  final double? median;

  /// Empirical 85th percentile.
  final double? v85;

  /// Sample standard deviation (n − 1), null for fewer than two values.
  final double? sd;

  /// Share strictly above the speed limit (equal counts as not above).
  final double? overLimitShare;

  /// RMS of the per-record uncertainties σ_v.
  final double? measurementSd;

  /// Spread corrected for the measurement uncertainty (8.3).
  final double? trueSd;

  /// V85 under a normal distribution: mean + z85·sd.
  final double? v85Normal;

  /// V85 with the corrected spread: mean + z85·trueSd (8.3).
  final double? v85Corrected;
}

/// Statistics of the records' speeds `v` (class C has no `v`).
SpeedStats speedStats(List<PassRecord> records, {required double limitKmh}) {
  final values = [
    for (final r in records)
      if (r.v != null) r.v!,
  ];
  final n = values.length;
  if (n == 0) return const SpeedStats(count: 0);
  final mean = values.reduce((a, b) => a + b) / n;
  double? sd;
  if (n >= 2) {
    var acc = 0.0;
    for (final v in values) {
      acc += (v - mean) * (v - mean);
    }
    sd = math.sqrt(acc / (n - 1));
  }
  final sigmas = [
    for (final r in records)
      if (r.v != null && r.sigmaV != null) r.sigmaV!,
  ];
  final measurementSd = sigmas.isEmpty
      ? null
      : math.sqrt(
          sigmas.map((s) => s * s).reduce((a, b) => a + b) / sigmas.length,
        );
  final trueSd = sd == null || measurementSd == null
      ? null
      : correctedSd(measuredSd: sd, measurementSd: measurementSd);
  return SpeedStats(
    count: n,
    mean: mean,
    median: percentile(values, 0.5),
    v85: percentile(values, 0.85),
    sd: sd,
    overLimitShare: values.where((v) => v > limitKmh).length / n,
    measurementSd: measurementSd,
    trueSd: trueSd,
    v85Normal: sd == null ? null : mean + z85 * sd,
    v85Corrected: trueSd == null ? null : mean + z85 * trueSd,
  );
}

/// Statistics separated by class A, B and A+B.
class ClassStats {
  const ClassStats({required this.a, required this.b, required this.ab});

  factory ClassStats.of(List<PassRecord> records, double limitKmh) =>
      ClassStats(
        a: speedStats(
          records.where((r) => r.klasse == QualityClass.a).toList(),
          limitKmh: limitKmh,
        ),
        b: speedStats(
          records.where((r) => r.klasse == QualityClass.b).toList(),
          limitKmh: limitKmh,
        ),
        ab: speedStats(
          records.where((r) => r.klasse != QualityClass.c).toList(),
          limitKmh: limitKmh,
        ),
      );

  final SpeedStats a;
  final SpeedStats b;
  final SpeedStats ab;
}

/// Rejected events (technik.pdf 5.6: the share of class C is reported).
class ClassCStats {
  const ClassCStats({
    required this.count,
    required this.share,
    required this.reasons,
  });

  final int count;
  final double? share;
  final Map<DowngradeReason, int> reasons;
}

/// Complete statistics of a series or site.
class StatisticsReport {
  const StatisticsReport({
    required this.total,
    required this.limitKmh,
    required this.overall,
    required this.byDirection,
    required this.byLane,
    required this.byHour,
    required this.classC,
  });

  factory StatisticsReport.from(
    List<PassRecord> records, {
    required double limitKmh,
  }) {
    Map<K, ClassStats> group<K>(K? Function(PassRecord) key) {
      final groups = <K, List<PassRecord>>{};
      for (final r in records) {
        final k = key(r);
        if (k == null || r.klasse == QualityClass.c) continue;
        groups.putIfAbsent(k, () => []).add(r);
      }
      final keys = groups.keys.toList()
        ..sort((x, y) => (x as Comparable).compareTo(y));
      return {for (final k in keys) k: ClassStats.of(groups[k]!, limitKmh)};
    }

    final rejected = records.where((r) => r.klasse == QualityClass.c).toList();
    final reasons = <DowngradeReason, int>{};
    for (final r in rejected) {
      final reason = r.reason;
      if (reason != null) reasons[reason] = (reasons[reason] ?? 0) + 1;
    }
    return StatisticsReport(
      total: records.length,
      limitKmh: limitKmh,
      overall: ClassStats.of(records, limitKmh),
      byDirection: group((r) => r.richtung),
      byLane: group((r) => r.laneIndex),
      byHour: group(
        (r) => DateTime.fromMillisecondsSinceEpoch(r.zeitUtcMs).hour,
      ),
      classC: ClassCStats(
        count: rejected.length,
        share: records.isEmpty ? null : rejected.length / records.length,
        reasons: reasons,
      ),
    );
  }

  final int total;
  final double limitKmh;
  final ClassStats overall;
  final Map<int, ClassStats> byDirection;
  final Map<int, ClassStats> byLane;

  /// Local hour of day → statistics.
  final Map<int, ClassStats> byHour;
  final ClassCStats classC;
}

/// One bin of the speed histogram.
class HistogramBin {
  const HistogramBin(this.fromKmh, this.a, this.b);
  final double fromKmh;
  final int a;
  final int b;
}

/// Histogram of A and B speeds with bins [k·w, (k+1)·w).
List<HistogramBin> speedHistogram(
  List<PassRecord> records, {
  required double binWidthKmh,
}) {
  final valid = records.where((r) => r.v != null).toList();
  if (valid.isEmpty) return const [];
  int bin(double v) => (v / binWidthKmh).floor();
  final first = valid.map((r) => bin(r.v!)).reduce(math.min);
  final last = valid.map((r) => bin(r.v!)).reduce(math.max);
  final a = List.filled(last - first + 1, 0),
      b = List.filled(last - first + 1, 0);
  for (final r in valid) {
    final i = bin(r.v!) - first;
    if (r.klasse == QualityClass.a) {
      a[i]++;
    } else {
      b[i]++;
    }
  }
  return [
    for (var i = 0; i <= last - first; i++)
      HistogramBin((first + i) * binWidthKmh, a[i], b[i]),
  ];
}

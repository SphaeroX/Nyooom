import 'dart:math' as math;

import '../config/nyooom_config.dart';
import '../model/acoustics.dart';
import '../pipeline/pass_record.dart';
import '../reference/reference_track.dart';

/// A reference vehicle passing the site (closest approach of the GPS track).
class ReferencePassage {
  const ReferencePassage({
    required this.timeUtcMs,
    required this.referenceSpeed,
    required this.distanceM,
    required this.bearingDeg,
  });

  final int timeUtcMs;

  /// Mean GPS speed around the passage in m/s.
  final double referenceSpeed;

  /// Smallest distance between the track and the site in m.
  final double distanceM;

  /// Direction of travel, degrees clockwise from north.
  final double bearingDeg;

  double get referenceKmh => toKmh(referenceSpeed);
}

const double _metresPerDegLat = 111195.0;

/// Closest approaches of [track] to the site position (Task_16).
List<ReferencePassage> closestApproaches(
  ReferenceTrack track, {
  required double siteLat,
  required double siteLon,
  required NyooomConfig config,
}) {
  final pts = track.points;
  if (pts.length < 2) return const [];
  final metresPerDegLon = _metresPerDegLat * math.cos(siteLat * math.pi / 180);
  final x = [for (final p in pts) (p.lon - siteLon) * metresPerDegLon];
  final y = [for (final p in pts) (p.lat - siteLat) * _metresPerDegLat];
  final d = [
    for (var i = 0; i < pts.length; i++) math.sqrt(x[i] * x[i] + y[i] * y[i]),
  ];

  final result = <ReferencePassage>[];
  for (var i = 0; i < pts.length; i++) {
    final left = i == 0 ? double.infinity : d[i - 1];
    final right = i == pts.length - 1 ? double.infinity : d[i + 1];
    if (d[i] > left || d[i] > right || d[i] > config.approachMaxDistanceM) {
      continue;
    }
    // Refine on the two neighbouring segments (linear motion in between).
    var bestD = d[i], bestT = pts[i].timeUtcMs.toDouble();
    var bestA = math.max(0, i - 1), bestB = math.min(pts.length - 1, i + 1);
    for (final (a, b) in [(i - 1, i), (i, i + 1)]) {
      if (a < 0 || b >= pts.length) continue;
      final dx = x[b] - x[a], dy = y[b] - y[a];
      final len2 = dx * dx + dy * dy;
      final tau = len2 == 0
          ? 0.0
          : (-(x[a] * dx + y[a] * dy) / len2).clamp(0.0, 1.0);
      final px = x[a] + tau * dx, py = y[a] + tau * dy;
      final dist = math.sqrt(px * px + py * py);
      if (dist <= bestD) {
        bestD = dist;
        bestT = pts[a].timeUtcMs + tau * (pts[b].timeUtcMs - pts[a].timeUtcMs);
        bestA = a;
        bestB = b;
      }
    }
    final bearing =
        (math.atan2(x[bestB] - x[bestA], y[bestB] - y[bestA]) * 180 / math.pi +
            360) %
        360;
    final t = bestT.round();
    final window = (config.referenceAverageS * 1000).round();
    final speed = track.meanSpeed(t - window, t + window) ?? track.speedAt(t);
    if (speed == null) continue;
    final passage = ReferencePassage(
      timeUtcMs: t,
      referenceSpeed: speed,
      distanceM: bestD,
      bearingDeg: bearing,
    );
    // Neighbouring minima within the match tolerance belong together.
    if (result.isNotEmpty &&
        (t - result.last.timeUtcMs).abs() < config.matchToleranceS * 2000) {
      if (bestD < result.last.distanceM) result[result.length - 1] = passage;
      continue;
    }
    result.add(passage);
  }
  return result;
}

/// Direction (+1/−1) a reference vehicle should get, from its bearing and
/// the bearing of +x at the site; null if the site bearing is unknown.
int? expectedDirection(ReferencePassage reference, double? plusXBearingDeg) {
  if (plusXBearingDeg == null) return null;
  final delta = (reference.bearingDeg - plusXBearingDeg) * math.pi / 180;
  return math.cos(delta) >= 0 ? 1 : -1;
}

class ValidationMatch {
  const ValidationMatch({required this.reference, required this.record});
  final ReferencePassage reference;
  final PassRecord record;

  /// Measured minus reference speed in km/h (null for class C).
  double? get errorKmh =>
      record.v == null ? null : record.v! - reference.referenceKmh;
}

class MatchResult {
  const MatchResult({
    required this.matches,
    required this.unmatchedReferences,
    required this.unmatchedRecords,
  });

  final List<ValidationMatch> matches;
  final List<ReferencePassage> unmatchedReferences;

  /// Records without reference (other traffic, false events).
  final List<PassRecord> unmatchedRecords;
}

/// Links each reference passage to the record closest in time within the
/// tolerance (technik.pdf 8.1: assignment by clock time).
MatchResult matchReferences(
  List<ReferencePassage> references,
  List<PassRecord> records, {
  required NyooomConfig config,
}) {
  final tolerance = config.matchToleranceS * 1000;
  final used = <int>{};
  final matches = <ValidationMatch>[];
  final unmatched = <ReferencePassage>[];
  for (final ref in references) {
    var best = -1;
    var bestDt = double.infinity;
    for (var i = 0; i < records.length; i++) {
      if (used.contains(i)) continue;
      final dt = (records[i].zeitUtcMs - ref.timeUtcMs).abs().toDouble();
      if (dt <= tolerance && dt < bestDt) {
        bestDt = dt;
        best = i;
      }
    }
    if (best < 0) {
      unmatched.add(ref);
    } else {
      used.add(best);
      matches.add(ValidationMatch(reference: ref, record: records[best]));
    }
  }
  return MatchResult(
    matches: matches,
    unmatchedReferences: unmatched,
    unmatchedRecords: [
      for (var i = 0; i < records.length; i++)
        if (!used.contains(i)) records[i],
    ],
  );
}

/// Error figures of a group (km/h).
class ErrorStats {
  const ErrorStats({required this.count, this.meanError, this.sd});

  factory ErrorStats.of(List<double> errors) {
    final n = errors.length;
    if (n == 0) return const ErrorStats(count: 0);
    final mean = errors.reduce((a, b) => a + b) / n;
    double? sd;
    if (n >= 2) {
      var acc = 0.0;
      for (final e in errors) {
        acc += (e - mean) * (e - mean);
      }
      sd = math.sqrt(acc / (n - 1));
    }
    return ErrorStats(count: n, meanError: mean, sd: sd);
  }

  final int count;
  final double? meanError;
  final double? sd;
}

enum AcceptanceCriterion {
  meanError('Mittlere Abweichung gesamt'),
  stepError('Mittlere Abweichung je Stufe, kein Trend'),
  sdClassA('Standardabweichung Klasse A'),
  sdClassB('Standardabweichung Klasse B'),
  shareC('Anteil Klasse C'),
  direction('Fahrtrichtung richtig erkannt');

  const AcceptanceCriterion(this.label);
  final String label;
}

/// Result of one acceptance criterion; [passed] null = not determinable.
class AcceptanceResult {
  const AcceptanceResult(this.criterion, this.passed, this.value);
  final AcceptanceCriterion criterion;
  final bool? passed;
  final String value;
}

/// Key figures of technik.pdf 8 and 8.3 for matched reference drives.
class ValidationReport {
  ValidationReport._({
    required this.matches,
    required this.all,
    required this.byClass,
    required this.byDirection,
    required this.byStep,
    required this.trendSlope,
    required this.shareC,
    required this.directionShare,
  });

  factory ValidationReport.from(
    List<ValidationMatch> matches, {
    required NyooomConfig config,
    required double? plusXBearingDeg,
  }) {
    final valid = matches.where((m) => m.errorKmh != null).toList();
    List<double> errors(Iterable<ValidationMatch> ms) => [
      for (final m in ms) m.errorKmh!,
    ];
    final byStep = <int, List<ValidationMatch>>{};
    for (final m in valid) {
      final step =
          ((m.reference.referenceKmh / config.speedStepKmh).round() *
                  config.speedStepKmh)
              .round();
      byStep.putIfAbsent(step, () => []).add(m);
    }
    final steps = byStep.keys.toList()..sort();
    // Least-squares slope of the error over the reference speed.
    double? slope;
    if (steps.length >= 2) {
      final xs = [for (final m in valid) m.reference.referenceKmh];
      final ys = errors(valid);
      final mx = xs.reduce((a, b) => a + b) / xs.length;
      final my = ys.reduce((a, b) => a + b) / ys.length;
      var sxy = 0.0, sxx = 0.0;
      for (var i = 0; i < xs.length; i++) {
        sxy += (xs[i] - mx) * (ys[i] - my);
        sxx += (xs[i] - mx) * (xs[i] - mx);
      }
      slope = sxx == 0 ? null : sxy / sxx;
    }
    double? directionShare;
    if (plusXBearingDeg != null && valid.isNotEmpty) {
      var right = 0;
      for (final m in valid) {
        final delta =
            (m.reference.bearingDeg - plusXBearingDeg) * math.pi / 180;
        final expected = math.cos(delta) >= 0 ? 1 : -1;
        if (m.record.richtung == expected) right++;
      }
      directionShare = right / valid.length;
    }
    return ValidationReport._(
      matches: matches,
      all: ErrorStats.of(errors(valid)),
      byClass: {
        for (final k in [QualityClass.a, QualityClass.b])
          k: ErrorStats.of(errors(valid.where((m) => m.record.klasse == k))),
      },
      byDirection: {
        for (final d in [1, -1])
          d: ErrorStats.of(errors(valid.where((m) => m.record.richtung == d))),
      },
      byStep: {for (final s in steps) s: ErrorStats.of(errors(byStep[s]!))},
      trendSlope: slope,
      shareC: matches.isEmpty
          ? null
          : matches.where((m) => m.record.klasse == QualityClass.c).length /
                matches.length,
      directionShare: directionShare,
    );
  }

  final List<ValidationMatch> matches;
  final ErrorStats all;
  final Map<QualityClass, ErrorStats> byClass;
  final Map<int, ErrorStats> byDirection;

  /// Speed step (km/h) → errors.
  final Map<int, ErrorStats> byStep;

  /// Slope of error over reference speed (km/h per km/h).
  final double? trendSlope;
  final double? shareC;
  final double? directionShare;

  /// Checks against the thresholds of technik.pdf 8.
  List<AcceptanceResult> acceptance(NyooomConfig config) {
    String kmh(double? v) => v == null ? '–' : '${v.toStringAsFixed(2)} km/h';
    String pct(double? v) =>
        v == null ? '–' : '${(v * 100).toStringAsFixed(1)} %';
    final stepMeans = byStep.values
        .where((s) => s.meanError != null)
        .map((s) => s.meanError!.abs())
        .toList();
    final worstStep = stepMeans.isEmpty ? null : stepMeans.reduce(math.max);
    bool? stepsOk;
    if (worstStep != null) {
      stepsOk =
          worstStep <= config.acceptStepErrorKmh &&
          (trendSlope == null || trendSlope!.abs() <= config.acceptTrendSlope);
    }
    final sdA = byClass[QualityClass.a]?.sd, sdB = byClass[QualityClass.b]?.sd;
    return [
      AcceptanceResult(
        AcceptanceCriterion.meanError,
        all.meanError == null
            ? null
            : all.meanError!.abs() <= config.acceptMeanErrorKmh,
        kmh(all.meanError),
      ),
      AcceptanceResult(
        AcceptanceCriterion.stepError,
        stepsOk,
        'max. ${kmh(worstStep)}, Steigung '
        '${trendSlope == null ? '–' : trendSlope!.toStringAsFixed(3)}',
      ),
      AcceptanceResult(
        AcceptanceCriterion.sdClassA,
        sdA == null ? null : sdA <= config.acceptSdAKmh,
        kmh(sdA),
      ),
      AcceptanceResult(
        AcceptanceCriterion.sdClassB,
        sdB == null ? null : sdB <= config.acceptSdBKmh,
        kmh(sdB),
      ),
      AcceptanceResult(
        AcceptanceCriterion.shareC,
        shareC == null ? null : shareC! <= config.acceptMaxShareC,
        pct(shareC),
      ),
      AcceptanceResult(
        AcceptanceCriterion.direction,
        directionShare == null
            ? null
            : directionShare! >= config.acceptMinDirectionShare,
        pct(directionShare),
      ),
    ];
  }
}

import 'dart:math' as math;

/// Origin of a reference track (technik.pdf 8.1).
enum ReferenceSource { logger, gpx, csv }

/// One GPS sample.
class ReferencePoint {
  const ReferencePoint({
    required this.timeUtcMs,
    required this.lat,
    required this.lon,
    this.speed,
    this.accuracyM,
    this.speedAccuracy,
    this.speedDerived = false,
  });

  final int timeUtcMs;
  final double lat;
  final double lon;

  /// Ground speed in m/s.
  final double? speed;
  final double? accuracyM;
  final double? speedAccuracy;

  /// The speed was derived from positions (no speed field in the source).
  final bool speedDerived;

  ReferencePoint withSpeed(double speed) => ReferencePoint(
    timeUtcMs: timeUtcMs,
    lat: lat,
    lon: lon,
    speed: speed,
    accuracyM: accuracyM,
    speedAccuracy: speedAccuracy,
    speedDerived: true,
  );
}

/// A reference drive with GPS speed over time.
class ReferenceTrack {
  const ReferenceTrack({
    required this.name,
    required this.source,
    required this.points,
  });

  final String name;
  final ReferenceSource source;
  final List<ReferencePoint> points;

  int? get startUtcMs => points.isEmpty ? null : points.first.timeUtcMs;
  int? get endUtcMs => points.isEmpty ? null : points.last.timeUtcMs;

  /// Speed at [timeUtcMs], linearly interpolated; null outside the track.
  double? speedAt(int timeUtcMs) {
    if (points.isEmpty ||
        timeUtcMs < points.first.timeUtcMs ||
        timeUtcMs > points.last.timeUtcMs) {
      return null;
    }
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      if (timeUtcMs <= b.timeUtcMs) {
        if (a.speed == null || b.speed == null) return a.speed ?? b.speed;
        final span = b.timeUtcMs - a.timeUtcMs;
        final w = span == 0 ? 0.0 : (timeUtcMs - a.timeUtcMs) / span;
        return a.speed! * (1 - w) + b.speed! * w;
      }
    }
    return points.last.speed;
  }

  /// Mean of the samples with speed between [fromMs] and [toMs].
  double? meanSpeed(int fromMs, int toMs) {
    final v = [
      for (final p in points)
        if (p.timeUtcMs >= fromMs && p.timeUtcMs <= toMs && p.speed != null)
          p.speed!,
    ];
    if (v.isEmpty) return null;
    return v.reduce((a, b) => a + b) / v.length;
  }
}

const double _earthRadiusM = 6371008.8;

/// Great-circle distance in m.
double haversineM(double lat1, double lon1, double lat2, double lon2) {
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLon = rad(lon2 - lon1);
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * _earthRadiusM * math.asin(math.sqrt(a));
}

/// Fills missing speeds from positions (central differences; one-sided at
/// the ends).
List<ReferencePoint> deriveSpeeds(List<ReferencePoint> points) {
  if (points.every((p) => p.speed != null) || points.length < 2) return points;
  double speedBetween(ReferencePoint a, ReferencePoint b) {
    final dt = (b.timeUtcMs - a.timeUtcMs) / 1000;
    return dt <= 0 ? 0 : haversineM(a.lat, a.lon, b.lat, b.lon) / dt;
  }

  return [
    for (var i = 0; i < points.length; i++)
      points[i].speed != null
          ? points[i]
          : points[i].withSpeed(
              speedBetween(
                points[math.max(0, i - 1)],
                points[math.min(points.length - 1, i + 1)],
              ),
            ),
  ];
}

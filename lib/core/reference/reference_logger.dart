import 'dart:async';

import 'reference_track.dart';

/// A position fix from the GPS (platform independent).
class PositionSample {
  const PositionSample({
    required this.timeUtcMs,
    required this.lat,
    required this.lon,
    this.speed,
    this.accuracyM,
    this.speedAccuracy,
  });

  final int timeUtcMs;
  final double lat;
  final double lon;
  final double? speed;
  final double? accuracyM;
  final double? speedAccuracy;
}

/// Logger mode (technik.pdf 8.1): records GPS fixes while running.
class ReferenceLogger {
  ReferenceLogger(this.positions);

  final Stream<PositionSample> positions;
  final List<ReferencePoint> _points = [];
  StreamSubscription<PositionSample>? _sub;

  int get count => _points.length;
  ReferencePoint? get last => _points.isEmpty ? null : _points.last;
  bool get running => _sub != null;

  void start() {
    _points.clear();
    _sub = positions.listen(
      (p) => _points.add(
        ReferencePoint(
          timeUtcMs: p.timeUtcMs,
          lat: p.lat,
          lon: p.lon,
          speed: p.speed,
          accuracyM: p.accuracyM,
          speedAccuracy: p.speedAccuracy,
        ),
      ),
    );
  }

  Future<ReferenceTrack> stop({required String name}) async {
    await _sub?.cancel();
    _sub = null;
    return ReferenceTrack(
      name: name,
      source: ReferenceSource.logger,
      points: deriveSpeeds(List.of(_points)),
    );
  }
}

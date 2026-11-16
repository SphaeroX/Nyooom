import 'dart:async';
import 'dart:math' as math;

import 'package:nyooom/core/reference/gpx.dart';
import 'package:nyooom/core/reference/reference_csv.dart';
import 'package:nyooom/core/reference/reference_logger.dart';
import 'package:nyooom/core/reference/reference_track.dart';
import 'package:test/test.dart';

/// Points along a meridian-free east-west line at constant [speed] m/s.
List<(double lat, double lon, DateTime t)> straightDrive(
  double speed, {
  int n = 11,
}) {
  const lat = 50.0;
  const metresPerDegLon = 111320 * 0.6427876096865394; // cos(50°)
  return [
    for (var i = 0; i < n; i++)
      (
        lat,
        8.0 + speed * i / metresPerDegLon,
        DateTime.utc(2026, 11, 16, 10, 0, i),
      ),
  ];
}

void main() {
  group('GPX', () {
    test('trackpoints with speed extension', () {
      const gpx = '''<?xml version="1.0"?>
<gpx version="1.1" xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v2">
 <trk><name>Fahrt 1</name><trkseg>
  <trkpt lat="50.0" lon="8.0"><time>2026-11-16T10:00:00Z</time>
   <extensions><gpxtpx:TrackPointExtension><gpxtpx:speed>8.33</gpxtpx:speed></gpxtpx:TrackPointExtension></extensions></trkpt>
  <trkpt lon="8.0001" lat="50.0"><time>2026-11-16T10:00:01.500Z</time><speed>8.4</speed></trkpt>
 </trkseg></trk></gpx>''';
      final track = parseGpx(gpx);
      expect(track.name, 'Fahrt 1');
      expect(track.points, hasLength(2));
      expect(track.points[0].speed, 8.33);
      expect(track.points[1].speed, 8.4);
      expect(track.points[1].lon, 8.0001);
      expect(
        track.points[1].timeUtcMs,
        DateTime.utc(2026, 11, 16, 10, 0, 1, 500).millisecondsSinceEpoch,
      );
    });

    test('without speed the speed is derived from positions', () {
      final pts = straightDrive(12.5);
      final gpx = StringBuffer('<gpx><trk><trkseg>');
      for (final (lat, lon, t) in pts) {
        gpx.write(
          '<trkpt lat="$lat" lon="$lon"><time>${t.toIso8601String()}</time></trkpt>',
        );
      }
      gpx.write('</trkseg></trk></gpx>');
      final track = parseGpx(gpx.toString());
      for (final p in track.points) {
        expect(p.speed, closeTo(12.5, 0.05));
        expect(p.speedDerived, isTrue);
      }
    });
  });

  group('CSV', () {
    test('ISO times, speed in km/h', () {
      final r = parseReferenceCsv('''time;lat;lon;speed_kmh
2026-11-16T10:00:00Z;50.0;8.0;30.0
2026-11-16T10:00:01Z;50.0;8.0001;30.5
''');
      expect(r.errors, isEmpty);
      expect(r.track.points[1].speed, closeTo(30.5 / 3.6, 1e-12));
    });

    test('epoch seconds and milliseconds, comma separator, m/s', () {
      final r = parseReferenceCsv('''timestamp,latitude,longitude,speed
1763287200,50.0,8.0,8.0
1763287201000,50.0,8.0001,8.1
''');
      expect(r.errors, isEmpty);
      expect(r.track.points[0].timeUtcMs, 1763287200000);
      expect(r.track.points[1].timeUtcMs, 1763287201000);
      expect(r.track.points[1].speed, 8.1);
    });

    test('local date-time format and broken lines are reported', () {
      final r = parseReferenceCsv('''zeit;lat;lon
2026-11-16 10:00:00;50.0;8.0
kaputt;50.0
2026-11-16 10:00:02;50.0;8.0002
''');
      expect(r.track.points, hasLength(2));
      expect(r.errors.single.line, 3);
      expect(r.track.points.every((p) => p.speedDerived), isTrue);
    });
  });

  test('distance between two coordinates (haversine)', () {
    expect(haversineM(50, 8, 50, 8.001), closeTo(71.55, 0.1));
    expect(haversineM(50, 8, 50.001, 8), closeTo(111.19, 0.1));
  });

  test('logger collects the mocked position stream', () async {
    final controller = StreamController<PositionSample>();
    final logger = ReferenceLogger(controller.stream);
    logger.start();
    for (final (lat, lon, t) in straightDrive(10, n: 5)) {
      controller.add(
        PositionSample(
          timeUtcMs: t.millisecondsSinceEpoch,
          lat: lat,
          lon: lon,
          speed: 10,
          accuracyM: 3,
          speedAccuracy: 0.3,
        ),
      );
    }
    await Future<void>.delayed(Duration.zero);
    expect(logger.count, 5);
    final track = await logger.stop(name: 'Test');
    await controller.close();
    expect(track.points, hasLength(5));
    expect(track.points.first.speed, 10);
    expect(track.source, ReferenceSource.logger);
    expect(track.speedAt(track.points[2].timeUtcMs), 10);
  });

  test('speedAt interpolates linearly and averages over a window', () {
    final track = ReferenceTrack(
      name: 'x',
      source: ReferenceSource.csv,
      points: [
        for (var i = 0; i <= 10; i++)
          ReferencePoint(
            timeUtcMs: i * 1000,
            lat: 0,
            lon: 0,
            speed: i.toDouble(),
          ),
      ],
    );
    expect(track.speedAt(2500), 2.5);
    expect(track.meanSpeed(3000, 7000), closeTo(5, 1e-12));
    expect(track.speedAt(-5), isNull);
    expect(math.max(1, 2), 2);
  });
}

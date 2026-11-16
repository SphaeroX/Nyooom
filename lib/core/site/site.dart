import '../model/acoustics.dart' as acoustics;

/// Recommended horizontal lane distance in m (Roadmap Task_04, technik.pdf
/// 4.1 recommends 3 to 6 m to the nearest lane).
const double recommendedLaneDistanceMin = 3;
const double recommendedLaneDistanceMax = 10;

/// Recommended microphone height in m (technik.pdf 4.1).
const double recommendedMicHeightMin = 1.0;
const double recommendedMicHeightMax = 1.5;

/// One lane of a site (technik.pdf 4.1, 7.2).
class LaneSpec {
  const LaneSpec({required this.horizontalDistance, required this.direction});

  /// Horizontal distance from the phone to the lane centre in m.
  final double horizontalDistance;

  /// Direction of travel on this lane: +1 (towards +x) or −1.
  final int direction;

  @override
  bool operator ==(Object other) =>
      other is LaneSpec &&
      other.horizontalDistance == horizontalDistance &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(horizontalDistance, direction);
}

/// A measuring site with everything technik.pdf 4.1 asks for.
class SiteSpec {
  const SiteSpec({
    required this.name,
    required this.lanes,
    required this.micHeight,
    required this.speedLimitKmh,
    this.latitude,
    this.longitude,
    this.plusXBearingDeg,
  });

  final String name;
  final List<LaneSpec> lanes;

  /// Microphone height above the road in m.
  final double micHeight;

  final double speedLimitKmh;

  /// Position of the phone (optional, used for GPS validation).
  final double? latitude;
  final double? longitude;

  /// Compass bearing (degrees from north, clockwise) of the +x direction,
  /// i.e. where vehicles of direction +1 drive to. Used to check the
  /// recognised direction against GPS reference drives (Task_16).
  final double? plusXBearingDeg;

  /// Slant distance of [lane] (technik.pdf 3.1, 7.2).
  double slantDistance(LaneSpec lane, {required double sourceHeight}) =>
      acoustics.slantDistance(
        lane.horizontalDistance,
        micHeight - sourceHeight,
      );

  /// The lane vehicles with [direction] drive on, or null.
  LaneSpec? laneForDirection(int direction) {
    for (final lane in lanes) {
      if (lane.direction == direction) return lane;
    }
    return null;
  }
}

enum SiteField { name, lanes, micHeight, speedLimit, position }

/// A validation finding; errors block saving, warnings only inform.
class SiteIssue {
  const SiteIssue(this.field, this.message, {this.isError = false, this.lane});

  final SiteField field;
  final String message;
  final bool isError;

  /// Index of the lane the issue refers to, if any.
  final int? lane;
}

/// Checks a site against the rules of technik.pdf 4.1.
List<SiteIssue> validateSite(SiteSpec site) {
  final issues = <SiteIssue>[];
  if (site.name.trim().isEmpty) {
    issues.add(const SiteIssue(SiteField.name, 'Name fehlt.', isError: true));
  }
  if (site.lanes.isEmpty) {
    issues.add(
      const SiteIssue(
        SiteField.lanes,
        'Mindestens eine Fahrspur angeben.',
        isError: true,
      ),
    );
  }
  for (var i = 0; i < site.lanes.length; i++) {
    final d = site.lanes[i].horizontalDistance;
    if (!(d > 0)) {
      issues.add(
        SiteIssue(
          SiteField.lanes,
          'Abstand muss größer als 0 m sein.',
          isError: true,
          lane: i,
        ),
      );
    } else if (d < recommendedLaneDistanceMin ||
        d > recommendedLaneDistanceMax) {
      issues.add(
        SiteIssue(
          SiteField.lanes,
          'Abstand außerhalb von 3 bis 10 m: Punktquelle bzw. Pegel werden '
          'ungünstig.',
          lane: i,
        ),
      );
    }
  }
  final directions = site.lanes.map((l) => l.direction).toList();
  if (directions.toSet().length != directions.length) {
    issues.add(
      const SiteIssue(
        SiteField.lanes,
        'Jede Fahrtrichtung darf nur einer Spur zugeordnet sein.',
        isError: true,
      ),
    );
  }
  if (!(site.micHeight > 0)) {
    issues.add(
      const SiteIssue(
        SiteField.micHeight,
        'Mikrofonhöhe muss größer als 0 m sein.',
        isError: true,
      ),
    );
  } else if (site.micHeight < recommendedMicHeightMin ||
      site.micHeight > recommendedMicHeightMax) {
    issues.add(
      const SiteIssue(
        SiteField.micHeight,
        'Empfohlen sind 1,0 bis 1,5 m Mikrofonhöhe.',
      ),
    );
  }
  if (!(site.speedLimitKmh > 0)) {
    issues.add(
      const SiteIssue(
        SiteField.speedLimit,
        'Tempolimit muss größer als 0 sein.',
        isError: true,
      ),
    );
  }
  final lat = site.latitude, lon = site.longitude;
  if ((lat == null) != (lon == null) ||
      (lat != null && !(lat >= -90 && lat <= 90)) ||
      (lon != null && !(lon >= -180 && lon <= 180))) {
    issues.add(
      const SiteIssue(
        SiteField.position,
        'Position: Breite (−90 bis 90) und Länge (−180 bis 180) zusammen '
        'angeben.',
        isError: true,
      ),
    );
  }
  final bearing = site.plusXBearingDeg;
  if (bearing != null && !(bearing >= 0 && bearing < 360)) {
    issues.add(
      const SiteIssue(
        SiteField.position,
        'Kompassrichtung muss zwischen 0 und 360° liegen.',
        isError: true,
      ),
    );
  }
  return issues;
}

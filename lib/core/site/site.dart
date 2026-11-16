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
  });

  final String name;
  final List<LaneSpec> lanes;

  /// Microphone height above the road in m.
  final double micHeight;

  final double speedLimitKmh;

  /// Position of the phone (optional, used for GPS validation).
  final double? latitude;
  final double? longitude;

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

enum SiteField { name, lanes, micHeight, speedLimit }

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
  return issues;
}

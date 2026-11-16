import 'dart:math' as math;

import 'package:nyooom/core/site/site.dart';
import 'package:test/test.dart';

void main() {
  const twoLanes = [
    LaneSpec(horizontalDistance: 4, direction: 1),
    LaneSpec(horizontalDistance: 7.5, direction: -1),
  ];
  const valid = SiteSpec(
    name: 'Hauptstraße',
    lanes: twoLanes,
    micHeight: 1.2,
    speedLimitKmh: 50,
  );

  test('slant distance uses mic height and source height (7.2, 3.1)', () {
    expect(
      valid.slantDistance(twoLanes[0], sourceHeight: 0.3),
      closeTo(math.sqrt(16 + 0.81), 1e-12),
    );
  });

  test('lane for a direction of travel', () {
    expect(valid.laneForDirection(-1), twoLanes[1]);
    expect(valid.laneForDirection(1), twoLanes[0]);
  });

  test('a valid site has no issues', () {
    expect(validateSite(valid), isEmpty);
  });

  List<SiteIssue> issuesOf(SiteSpec s) => validateSite(s);

  test('errors for missing name, lanes, non-positive values', () {
    expect(
      issuesOf(
        const SiteSpec(
          name: ' ',
          lanes: twoLanes,
          micHeight: 1.2,
          speedLimitKmh: 50,
        ),
      ).single,
      isA<SiteIssue>()
          .having((i) => i.field, 'field', SiteField.name)
          .having((i) => i.isError, 'error', isTrue),
    );
    expect(
      issuesOf(
        const SiteSpec(name: 'a', lanes: [], micHeight: 1.2, speedLimitKmh: 50),
      ).single.field,
      SiteField.lanes,
    );
    expect(
      issuesOf(
        const SiteSpec(
          name: 'a',
          lanes: [LaneSpec(horizontalDistance: 0, direction: 1)],
          micHeight: 1.2,
          speedLimitKmh: 50,
        ),
      ).single.isError,
      isTrue,
    );
    expect(
      issuesOf(
        const SiteSpec(
          name: 'a',
          lanes: twoLanes,
          micHeight: 1.2,
          speedLimitKmh: 0,
        ),
      ).single.field,
      SiteField.speedLimit,
    );
  });

  test('warnings outside the recommended ranges, none at the limits', () {
    SiteSpec withLane(double d, {double h = 1.2}) => SiteSpec(
      name: 'a',
      lanes: [LaneSpec(horizontalDistance: d, direction: 1)],
      micHeight: h,
      speedLimitKmh: 50,
    );
    expect(issuesOf(withLane(2.9)).single.isError, isFalse);
    expect(issuesOf(withLane(10.1)).single.isError, isFalse);
    expect(issuesOf(withLane(3)), isEmpty);
    expect(issuesOf(withLane(10)), isEmpty);
    expect(issuesOf(withLane(5, h: 0.9)).single.field, SiteField.micHeight);
    expect(issuesOf(withLane(5, h: 1.0)), isEmpty);
    expect(issuesOf(withLane(5, h: 1.5)), isEmpty);
    expect(issuesOf(withLane(5, h: 1.6)).single.isError, isFalse);
  });

  test('two lanes with the same direction are an error', () {
    final issues = validateSite(
      const SiteSpec(
        name: 'a',
        lanes: [
          LaneSpec(horizontalDistance: 4, direction: 1),
          LaneSpec(horizontalDistance: 7, direction: 1),
        ],
        micHeight: 1.2,
        speedLimitKmh: 50,
      ),
    );
    expect(issues.single.field, SiteField.lanes);
    expect(issues.single.isError, isTrue);
  });
}

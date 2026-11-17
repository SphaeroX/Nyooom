import 'package:nyooom/core/site/site.dart';
import 'package:test/test.dart';

void main() {
  const twoWay = LaneSpec(horizontalDistance: 4, direction: 0);
  const alley = SiteSpec(
    name: 'Seitengasse',
    lanes: [twoWay],
    micHeight: 1.2,
    speedLimitKmh: 30,
  );

  test('a two-way lane serves both directions of travel', () {
    expect(twoWay.isTwoWay, isTrue);
    expect(twoWay.serves(1), isTrue);
    expect(twoWay.serves(-1), isTrue);
    expect(
      const LaneSpec(horizontalDistance: 4, direction: 1).serves(-1),
      isFalse,
    );
    expect(alley.laneForDirection(1), twoWay);
    expect(alley.laneForDirection(-1), twoWay);
  });

  test('a single two-way lane is a valid site', () {
    expect(validateSite(alley), isEmpty);
  });

  test('a two-way lane next to another lane is an error', () {
    final issues = validateSite(
      const SiteSpec(
        name: 'A',
        lanes: [twoWay, LaneSpec(horizontalDistance: 7, direction: -1)],
        micHeight: 1.2,
        speedLimitKmh: 30,
      ),
    );
    expect(
      issues.where((i) => i.isError && i.field == SiteField.lanes),
      hasLength(1),
    );
  });

  test('a direction other than -1, 0, +1 is an error', () {
    final issues = validateSite(
      const SiteSpec(
        name: 'A',
        lanes: [LaneSpec(horizontalDistance: 4, direction: 2)],
        micHeight: 1.2,
        speedLimitKmh: 30,
      ),
    );
    expect(issues.where((i) => i.isError), hasLength(1));
  });

  test('lane label shows the direction', () {
    expect(laneDirectionLabel(1), '→');
    expect(laneDirectionLabel(-1), '←');
    expect(laneDirectionLabel(0), '⇄');
  });
}

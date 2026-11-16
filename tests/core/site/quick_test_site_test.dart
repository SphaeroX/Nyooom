import 'package:nyooom/core/site/site.dart';
import 'package:test/test.dart';

void main() {
  test('quick test site is valid without any measuring', () {
    final site = quickTestSite();
    expect(validateSite(site).where((i) => i.isError), isEmpty);
  });

  test('quick test site has one lane per direction', () {
    final site = quickTestSite();
    expect(site.lanes.map((l) => l.direction).toSet(), {1, -1});
    expect(
      site.laneForDirection(1)!.horizontalDistance,
      lessThan(site.laneForDirection(-1)!.horizontalDistance),
    );
  });
}

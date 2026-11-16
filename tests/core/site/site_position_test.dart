import 'package:nyooom/core/site/site.dart';
import 'package:test/test.dart';

void main() {
  SiteSpec site({double? lat, double? lon, double? bearing}) => SiteSpec(
    name: 'A',
    lanes: const [LaneSpec(horizontalDistance: 4, direction: 1)],
    micHeight: 1.2,
    speedLimitKmh: 50,
    latitude: lat,
    longitude: lon,
    plusXBearingDeg: bearing,
  );

  test('position and bearing are optional and checked', () {
    expect(validateSite(site()), isEmpty);
    expect(validateSite(site(lat: 50.1, lon: 8.6, bearing: 270)), isEmpty);
    expect(validateSite(site(lat: 50.1)).single.field, SiteField.position);
    expect(validateSite(site(lat: 95, lon: 8)).single.isError, isTrue);
    expect(validateSite(site(bearing: 360)).single.field, SiteField.position);
  });
}

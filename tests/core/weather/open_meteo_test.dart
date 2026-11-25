import 'package:nyooom/core/weather/open_meteo.dart';
import 'package:test/test.dart';

void main() {
  test('the request asks for the current 2 m temperature at rounded '
      'coordinates', () {
    final uri = openMeteoCurrentUri(latitude: 52.520456, longitude: 13.404954);
    expect(uri.scheme, 'https');
    expect(uri.host, 'api.open-meteo.com');
    expect(uri.path, '/v1/forecast');
    // Two decimals (about 1 km): enough for the weather, less precise
    // than the GPS fix that leaves the phone.
    expect(uri.queryParameters['latitude'], '52.52');
    expect(uri.queryParameters['longitude'], '13.40');
    expect(uri.queryParameters['current'], 'temperature_2m');
  });

  test('another base address keeps path and parameters', () {
    final uri = openMeteoCurrentUri(
      latitude: -33.8688,
      longitude: 151.2093,
      base: Uri.parse('http://127.0.0.1:8080'),
    );
    expect(uri.toString(), startsWith('http://127.0.0.1:8080/v1/forecast?'));
    expect(uri.queryParameters['latitude'], '-33.87');
    expect(uri.queryParameters['longitude'], '151.21');
  });

  test('the current temperature is read from the answer', () {
    const body =
        '{"latitude":52.52,"longitude":13.42,'
        '"current_units":{"temperature_2m":"°C"},'
        '"current":{"time":"2026-11-25T10:00","interval":900,'
        '"temperature_2m":4.7}}';
    expect(parseOpenMeteoTemperature(body), 4.7);
  });

  test('an answer without temperature is an error', () {
    expect(
      () => parseOpenMeteoTemperature('{"error":true,"reason":"x"}'),
      throwsFormatException,
    );
    expect(
      () => parseOpenMeteoTemperature('{"current":{"temperature_2m":null}}'),
      throwsFormatException,
    );
    expect(() => parseOpenMeteoTemperature('kein json'), throwsFormatException);
  });
}

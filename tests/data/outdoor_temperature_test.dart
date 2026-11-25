import 'dart:io';

import 'package:nyooom/data/outdoor_temperature.dart';
import 'package:test/test.dart';

void main() {
  late HttpServer server;
  late List<Uri> requests;
  var status = 200;
  var body = '';

  setUp(() async {
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) {
      requests.add(r.uri);
      r.response
        ..statusCode = status
        ..write(body);
      r.response.close();
    });
  });

  tearDown(() => server.close(force: true));

  Uri base() => Uri.parse('http://127.0.0.1:${server.port}');

  test('the service locates the phone and asks Open-Meteo', () async {
    status = 200;
    body = '{"current":{"temperature_2m":-3.2}}';
    final service = GpsOutdoorTemperatureService(
      locate: () async => (latitude: 48.137154, longitude: 11.576124),
      baseUri: base(),
      now: () => DateTime.utc(2026, 11, 25, 10),
    );
    final t = await service.current();
    expect(t.temperatureC, -3.2);
    expect(t.utcMs, DateTime.utc(2026, 11, 25, 10).millisecondsSinceEpoch);
    expect(requests.single.queryParameters['latitude'], '48.14');
    expect(requests.single.queryParameters['longitude'], '11.58');
  });

  test('a server error is reported in German', () async {
    status = 503;
    body = 'down';
    final service = GpsOutdoorTemperatureService(
      locate: () async => (latitude: 1.0, longitude: 2.0),
      baseUri: base(),
    );
    await expectLater(
      service.current(),
      throwsA(
        isA<OutdoorTemperatureException>().having(
          (e) => e.message,
          'message',
          contains('Wetterdienst'),
        ),
      ),
    );
  });

  test('without a position there is no request', () async {
    final service = GpsOutdoorTemperatureService(
      locate: () async => null,
      baseUri: base(),
    );
    await expectLater(
      service.current(),
      throwsA(
        isA<OutdoorTemperatureException>().having(
          (e) => e.message,
          'message',
          contains('Standort'),
        ),
      ),
    );
    expect(requests, isEmpty);
  });
}

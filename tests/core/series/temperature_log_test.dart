import 'package:nyooom/core/series/temperature_log.dart';
import 'package:test/test.dart';

void main() {
  const start = TemperatureReading(
    offsetS: 0,
    temperatureC: 12,
    utcMs: 1000,
    source: TemperatureReading.sourceStart,
  );
  const later = TemperatureReading(
    offsetS: 900,
    temperatureC: 15.5,
    utcMs: 901000,
    source: TemperatureReading.sourceGps,
  );

  test(
    'the temperature at a signal position is the last reading before it',
    () {
      final log = [start, later];
      expect(temperatureAt(log, 0, fallbackC: 99), 12);
      expect(temperatureAt(log, 899.9, fallbackC: 99), 12);
      expect(temperatureAt(log, 900, fallbackC: 99), 15.5);
      expect(temperatureAt(log, 5000, fallbackC: 99), 15.5);
    },
  );

  test('before the first reading the first one counts, without any the '
      'fallback', () {
    expect(temperatureAt([later], 10, fallbackC: 99), 15.5);
    expect(temperatureAt(const [], 10, fallbackC: 7), 7);
  });

  test('an unchanged temperature is not appended again', () {
    final same = appendTemperatureReading(
      [start],
      const TemperatureReading(
        offsetS: 600,
        temperatureC: 12,
        utcMs: 601000,
        source: TemperatureReading.sourceGps,
      ),
    );
    expect(same, [start]);
    expect(appendTemperatureReading([start], later), [start, later]);
  });

  test('the log survives a JSON round trip', () {
    final json = temperatureLogToJson([start, later]);
    expect(temperatureLogFromJson(json), [start, later]);
    expect(temperatureLogFromJson(null), isEmpty);
  });
}

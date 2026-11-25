import 'package:nyooom/core/series/series_metadata.dart';
import 'package:nyooom/core/series/temperature_log.dart';
import 'package:test/test.dart';

SeriesMetadata metadata({
  bool autoUpdate = false,
  List<TemperatureReading> log = const [],
}) => SeriesMetadata(
  seriesId: 1,
  siteName: 'A',
  deviceModel: 'Pixel',
  audioSource: 'UNPROCESSED',
  effects: const {},
  sampleRate: 48000,
  lanes: const [],
  micHeight: 1.2,
  sourceHeight: 0.3,
  temperatureC: 8,
  speedOfSound: 336.3,
  speedLimitKmh: 50,
  swapChannels: false,
  startedAtUtcMs: 0,
  calibration: null,
  config: const {},
  simulated: false,
  saveRawAudio: true,
  temperatureAutoUpdate: autoUpdate,
  temperatureLog: log,
);

void main() {
  const reading = TemperatureReading(
    offsetS: 900,
    temperatureC: 9.5,
    utcMs: 900000,
    source: TemperatureReading.sourceGps,
  );

  test('auto update and temperature log survive a JSON round trip', () {
    final json = metadata(autoUpdate: true, log: const [reading]).toJson();
    final back = SeriesMetadata.fromJson(json);
    expect(back.temperatureAutoUpdate, isTrue);
    expect(back.temperatureLog, const [reading]);
  });

  test('older metadata without the fields reads as manual, no log', () {
    final json = metadata().toJson()
      ..remove('temperatureAutoUpdate')
      ..remove('temperatureLog');
    final back = SeriesMetadata.fromJson(json);
    expect(back.temperatureAutoUpdate, isFalse);
    expect(back.temperatureLog, isEmpty);
    expect(metadata().toJson().containsKey('temperatureLog'), isFalse);
  });

  test('withTemperatureLog replaces the log', () {
    final updated = metadata().withTemperatureLog(const [reading]);
    expect(updated.temperatureLog, const [reading]);
    expect(updated.temperatureC, 8);
  });
}

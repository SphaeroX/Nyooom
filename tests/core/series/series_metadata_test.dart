import 'dart:convert';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/series/series_metadata.dart';
import 'package:test/test.dart';

void main() {
  final metadata = SeriesMetadata(
    seriesId: 7,
    siteName: 'Hauptstraße',
    deviceModel: 'Pixel 8',
    audioSource: 'UNPROCESSED',
    effects: const {'agc': 'disabled', 'ns': 'unavailable', 'aec': 'disabled'},
    sampleRate: 48000,
    lanes: const [
      LaneMetadata(horizontalDistance: 4, direction: 1, slantDistance: 4.1),
      LaneMetadata(horizontalDistance: 7.5, direction: -1, slantDistance: 7.55),
    ],
    micHeight: 1.2,
    sourceHeight: 0.3,
    temperatureC: 12.5,
    speedOfSound: 338.8,
    speedLimitKmh: 50,
    swapChannels: false,
    startedAtUtcMs: 1763300000123,
    calibration: const CalibrationMetadata(
      micSpacing: 0.148,
      channelOffset: 3e-6,
      calibratedAtUtcMs: 1763200000000,
      temperatureC: 20,
    ),
    config: const NyooomConfig().toJson(),
    simulated: true,
    saveRawAudio: true,
  );

  test('round-trips through JSON text', () {
    final text = jsonEncode(metadata.toJson());
    final restored = SeriesMetadata.fromJson(
      jsonDecode(text) as Map<String, dynamic>,
    );
    expect(restored.toJson(), metadata.toJson());
  });

  test('contains all mandatory fields of technik.pdf 4.4', () {
    final json = metadata.toJson();
    for (final key in [
      'deviceModel',
      'audioSource',
      'effects',
      'lanes',
      'micHeightM',
      'temperatureC',
      'channelMapping',
      'startedAtUtcMs',
      'speedOfSound',
      'sampleRate',
      'calibration',
      'config',
    ]) {
      expect(json, contains(key));
    }
    expect(json['channelMapping'], contains('left'));
  });

  test('missing calibration stays null', () {
    final json = metadata.toJson()..['calibration'] = null;
    expect(SeriesMetadata.fromJson(json).calibration, isNull);
  });

  test('stores the input device; older files default to internal', () {
    final json = metadata.toJson();
    expect(json['inputDevice'], 'intern');
    json.remove('inputDevice');
    expect(SeriesMetadata.fromJson(json).inputDevice, 'intern');
    json['inputDevice'] = 'USB Audio';
    expect(SeriesMetadata.fromJson(json).inputDevice, 'USB Audio');
  });
}

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/core/series/temperature_log.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/outdoor_temperature.dart';
import 'package:nyooom/data/repository.dart';
import 'package:nyooom/data/series_storage.dart';
import 'package:nyooom/ui/providers.dart';
import 'package:nyooom/ui/series/series_recording_controller.dart';
import 'package:nyooom/ui/weather/outdoor_temperature_providers.dart';

import '../../helpers/fake_stereo_recorder.dart';

/// Answers with the next value of [values] (the last one repeats).
class FakeTemperatureService implements OutdoorTemperatureService {
  FakeTemperatureService(this.values);

  final List<double> values;
  int calls = 0;

  @override
  Future<OutdoorTemperature> current() async {
    final t = values[calls < values.length ? calls : values.length - 1];
    calls++;
    return OutdoorTemperature(temperatureC: t, utcMs: 5000 + calls);
  }
}

Future<void> waitFor(bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late Directory dir;
  late NyooomDatabase db;
  late FakeStereoRecorder recorder;
  late FakeTemperatureService weather;
  late ProviderContainer container;

  ProviderContainer build(OutdoorTemperatureService service) =>
      ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          seriesStorageProvider.overrideWith((ref) async => SeriesStorage(dir)),
          liveEvaluationProvider.overrideWithValue(false),
          recorderFactoryProvider.overrideWithValue(
            ({required simulate, required lanes}) => recorder,
          ),
          outdoorTemperatureServiceProvider.overrideWithValue(service),
          temperatureRefreshIntervalProvider.overrideWithValue(
            const Duration(milliseconds: 10),
          ),
        ],
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nyooom_temperature_test');
    db = NyooomDatabase(NativeDatabase.memory());
    recorder = FakeStereoRecorder();
    weather = FakeTemperatureService([18.5]);
    container = build(weather);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<int> createSite() => NyooomRepository(db).createSite(
    const SiteSpec(
      name: 'Gasse',
      lanes: [LaneSpec(horizontalDistance: 4, direction: 0)],
      micHeight: 1.2,
      speedLimitKmh: 30,
    ),
  );

  test(
    'with auto update the temperature is refreshed while recording',
    () async {
      final siteId = await createSite();
      final controller = container.read(seriesRecordingProvider.notifier);
      await controller.start(
        SeriesStartRequest(
          siteId: siteId,
          temperatureC: 15,
          autoUpdateTemperature: true,
        ),
      );
      final id = container.read(seriesRecordingProvider).seriesId!;
      expect(container.read(seriesRecordingProvider).temperatureC, 15);
      recorder.emit(sinePcm16(leftAmplitude: 0.3, rightAmplitude: 0.2));
      await waitFor(
        () => container.read(seriesRecordingProvider).temperatureC == 18.5,
      );
      expect(container.read(seriesRecordingProvider).temperatureC, 18.5);
      await controller.stop();
      final calls = weather.calls;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(weather.calls, calls, reason: 'no refresh after stop');

      final log = (await NyooomRepository(db).series(id))!.temperatureLog;
      expect(log.map((r) => r.temperatureC), [15, 18.5]);
      expect(log[1].source, TemperatureReading.sourceGps);
      expect(log[1].offsetS, closeTo(0.1, 1e-9));
      final metadata = (await SeriesStorage(dir).readMetadata(id))!;
      expect(metadata.temperatureAutoUpdate, isTrue);
      expect(metadata.temperatureLog, log);
    },
  );

  test('without auto update the weather service is not asked', () async {
    final siteId = await createSite();
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(siteId: siteId, temperatureC: 15),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await controller.stop();
    expect(weather.calls, 0);
    final id = container.read(seriesRecordingProvider).seriesId!;
    expect((await NyooomRepository(db).series(id))!.temperatureLog, isEmpty);
  });

  test('a continued series refreshes again', () async {
    final siteId = await createSite();
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(
        siteId: siteId,
        temperatureC: 15,
        autoUpdateTemperature: true,
      ),
    );
    final id = container.read(seriesRecordingProvider).seriesId!;
    await waitFor(() => weather.calls > 0);
    await controller.stop();
    weather.values
      ..clear()
      ..add(9);
    await controller.resume(id);
    await waitFor(
      () => container.read(seriesRecordingProvider).temperatureC == 9,
    );
    await controller.stop();
    final log = (await NyooomRepository(db).series(id))!.temperatureLog;
    expect(log.last.temperatureC, 9);
  });

  test('a failing weather service keeps the last temperature', () async {
    container.dispose();
    container = build(_FailingService());
    final siteId = await createSite();
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(
        siteId: siteId,
        temperatureC: 15,
        autoUpdateTemperature: true,
      ),
    );
    await waitFor(
      () => container.read(seriesRecordingProvider).temperatureNote != null,
    );
    final state = container.read(seriesRecordingProvider);
    expect(state.running, isTrue);
    expect(state.temperatureC, 15);
    expect(state.temperatureNote, contains('kein Netz'));
    await controller.stop();
  });
}

class _FailingService implements OutdoorTemperatureService {
  @override
  Future<OutdoorTemperature> current() async =>
      throw const OutdoorTemperatureException('kein Netz');
}

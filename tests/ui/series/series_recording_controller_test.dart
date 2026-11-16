import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/wav.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:nyooom/data/series_storage.dart';
import 'package:nyooom/ui/providers.dart';
import 'package:nyooom/ui/series/series_recording_controller.dart';

import '../../helpers/fake_stereo_recorder.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late Directory dir;
  late NyooomDatabase db;
  late FakeStereoRecorder recorder;
  late ProviderContainer container;
  bool? requestedSimulation;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nyooom_series_test');
    db = NyooomDatabase(NativeDatabase.memory());
    recorder = FakeStereoRecorder();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        seriesStorageProvider.overrideWith((ref) async => SeriesStorage(dir)),
        recorderFactoryProvider.overrideWithValue(({
          required simulate,
          required lanes,
        }) {
          requestedSimulation = simulate;
          return recorder;
        }),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<int> createSite() => NyooomRepository(db).createSite(
    const SiteSpec(
      name: 'Teststraße',
      lanes: [
        LaneSpec(horizontalDistance: 4, direction: 1),
        LaneSpec(horizontalDistance: 7, direction: -1),
      ],
      micHeight: 1.2,
      speedLimitKmh: 50,
    ),
  );

  test('records a series into WAV plus metadata.json', () async {
    final siteId = await createSite();
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(siteId: siteId, temperatureC: 15, simulate: true),
    );
    var state = container.read(seriesRecordingProvider);
    expect(state.running, isTrue);
    expect(requestedSimulation, isTrue);
    final id = state.seriesId!;

    final block = sinePcm16(leftAmplitude: 0.3, rightAmplitude: 0.2);
    recorder.emit(block);
    recorder.emit(block);
    await flush();
    expect(
      container.read(seriesRecordingProvider).elapsedS,
      closeTo(0.2, 1e-9),
    );
    await controller.stop();

    state = container.read(seriesRecordingProvider);
    expect(state.running, isFalse);
    final storage = SeriesStorage(dir);
    final wav = decodeWav(await storage.wavFile(id).readAsBytes());
    expect(wav.channels, 2);
    expect(wav.sampleRate, 48000);
    expect(
      wav.samples.buffer.asUint8List(),
      Uint8List.fromList([...block, ...block]),
    );

    final metadata = (await storage.readMetadata(id))!;
    expect(metadata.siteName, 'Teststraße');
    expect(metadata.deviceModel, 'Fake Phone');
    expect(metadata.audioSource, 'UNPROCESSED');
    expect(metadata.temperatureC, 15);
    expect(metadata.lanes, hasLength(2));
    expect(metadata.lanes[0].slantDistance, closeTo(4.1, 1e-9));

    final series = (await NyooomRepository(db).series(id))!;
    expect(series.endedAtUtcMs, isNotNull);
    expect(series.row.simulated, isTrue);
  });

  test('without raw audio no WAV is written', () async {
    final siteId = await createSite();
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(siteId: siteId, temperatureC: 15, saveRawAudio: false),
    );
    final id = container.read(seriesRecordingProvider).seriesId!;
    recorder.emit(sinePcm16(leftAmplitude: 0.3, rightAmplitude: 0.2));
    await flush();
    await controller.stop();
    expect(await SeriesStorage(dir).wavFile(id).exists(), isFalse);
    expect(await SeriesStorage(dir).metadataFile(id).exists(), isTrue);
  });

  test('a start failure leaves no running series', () async {
    recorder = FakeStereoRecorder(startError: Exception('boom'));
    final siteId = await createSite();
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(siteId: siteId, temperatureC: 15),
    );
    final state = container.read(seriesRecordingProvider);
    expect(state.running, isFalse);
    expect(state.error, isNotNull);
  });

  test('a new series stores the current device calibration', () async {
    final repo = NyooomRepository(db);
    final deviceId = await repo.ensureDevice('Fake Phone');
    final calibrationId = await repo.addCalibration(
      CalibrationsCompanion.insert(
        deviceId: deviceId,
        micSpacingM: 0.147,
        channelOffsetS: 5e-6,
        temperatureC: 18,
        createdAtUtcMs: 1000,
      ),
    );
    final siteId = await createSite();
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(siteId: siteId, temperatureC: 15),
    );
    final id = container.read(seriesRecordingProvider).seriesId!;
    await controller.stop();
    expect((await repo.series(id))!.row.calibrationId, calibrationId);
    final metadata = (await SeriesStorage(dir).readMetadata(id))!;
    expect(metadata.calibration!.micSpacing, 0.147);
    expect(metadata.calibration!.channelOffset, 5e-6);
  });
}

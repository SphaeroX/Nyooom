import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/stereo_recorder.dart';
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

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nyooom_resume_test');
    db = NyooomDatabase(NativeDatabase.memory());
    recorder = FakeStereoRecorder();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        seriesStorageProvider.overrideWith((ref) async => SeriesStorage(dir)),
        liveEvaluationProvider.overrideWithValue(false),
        recorderFactoryProvider.overrideWithValue(
          ({required simulate, required lanes}) => recorder,
        ),
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
      name: 'Gasse',
      lanes: [LaneSpec(horizontalDistance: 4, direction: 0)],
      micHeight: 1.2,
      speedLimitKmh: 30,
    ),
  );

  test('a stopped series can be continued into the same files', () async {
    final siteId = await createSite();
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(siteId: siteId, temperatureC: 15),
    );
    final id = container.read(seriesRecordingProvider).seriesId!;
    final a = sinePcm16(leftAmplitude: 0.3, rightAmplitude: 0.2);
    final b = sinePcm16(leftAmplitude: 0.1, rightAmplitude: 0.4);
    recorder.emit(a);
    recorder.emit(a);
    await flush();
    await controller.stop();
    expect(container.read(seriesRecordingProvider).canResume, isTrue);

    await controller.resume(id);
    var state = container.read(seriesRecordingProvider);
    expect(state.running, isTrue);
    expect(state.seriesId, id);
    expect(state.elapsedS, closeTo(0.2, 1e-9));
    expect(recorder.startCalls, 2);
    recorder.emit(b);
    await flush();
    expect(
      container.read(seriesRecordingProvider).elapsedS,
      closeTo(0.3, 1e-9),
    );
    await controller.stop();
    state = container.read(seriesRecordingProvider);
    expect(state.running, isFalse);

    final storage = SeriesStorage(dir);
    final wav = decodeWav(await storage.wavFile(id).readAsBytes());
    expect(
      wav.samples.buffer.asUint8List(),
      Uint8List.fromList([...a, ...a, ...b]),
    );
    final series = (await NyooomRepository(db).series(id))!;
    expect(series.endedAtUtcMs, isNotNull);
    expect(series.segments, hasLength(2));
    expect(series.segments[1].offsetS, closeTo(0.2, 1e-9));
    final metadata = (await storage.readMetadata(id))!;
    expect(metadata.segments, hasLength(2));
    expect(await NyooomRepository(db).allSeries(), hasLength(1));
  });

  test('a USB input device is used and its calibration applied', () async {
    const usb = InputDevice(
      id: 7,
      name: 'USB Stereo Mic',
      type: 11,
      isExternal: true,
      channelCounts: [1, 2],
    );
    recorder.devices = const [
      InputDevice(id: 1, name: 'Intern', type: 15, isExternal: false),
      usb,
    ];
    final repo = NyooomRepository(db);
    final usbDevice = await repo.ensureDevice(
      'Fake Phone',
      inputDevice: 'USB Stereo Mic',
    );
    final calibrationId = await repo.addCalibration(
      CalibrationsCompanion.insert(
        deviceId: usbDevice,
        micSpacingM: 0.42,
        channelOffsetS: 0,
        temperatureC: 15,
        createdAtUtcMs: 1000,
      ),
    );
    final siteId = await createSite();
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(siteId: siteId, temperatureC: 15, inputDevice: usb),
    );
    final id = container.read(seriesRecordingProvider).seriesId!;
    expect(recorder.lastInputDeviceId, 7);
    final series = (await repo.series(id))!;
    expect(series.row.calibrationId, calibrationId);
    final metadata = (await SeriesStorage(dir).readMetadata(id))!;
    expect(metadata.inputDevice, 'USB Stereo Mic');

    await controller.stop();
    recorder.lastInputDeviceId = null;
    await controller.resume(id);
    expect(recorder.lastInputDeviceId, 7);
    await controller.stop();
  });

  test('preferred input device is the first external stereo device', () {
    const intern = InputDevice(
      id: 1,
      name: 'Intern',
      type: 15,
      isExternal: false,
      channelCounts: [1, 2],
    );
    const mono = InputDevice(
      id: 2,
      name: 'Headset',
      type: 3,
      isExternal: true,
      channelCounts: [1],
    );
    const usb = InputDevice(
      id: 3,
      name: 'USB',
      type: 11,
      isExternal: true,
      channelCounts: [2],
    );
    expect(preferredInputDevice([intern, mono, usb]), usb);
    expect(preferredInputDevice([intern, mono]), isNull);
    expect(usb.supportsStereo, isTrue);
    expect(mono.supportsStereo, isFalse);
    // Unknown channel counts: assume stereo is possible.
    expect(
      const InputDevice(
        id: 4,
        name: 'X',
        type: 11,
        isExternal: true,
      ).supportsStereo,
      isTrue,
    );
  });
}

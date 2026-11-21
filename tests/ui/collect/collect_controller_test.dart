import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/stereo_recorder.dart';
import 'package:nyooom/core/collect/collection_manifest.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/data/collection_storage.dart';
import 'package:nyooom/data/input_choice_store.dart';
import 'package:nyooom/ui/collect/collect_controller.dart';
import 'package:nyooom/ui/device/input_device_selection.dart';
import 'package:nyooom/ui/providers.dart';

import '../../helpers/fake_stereo_recorder.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late Directory dir;
  late FakeStereoRecorder recorder;
  late ProviderContainer container;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nyooom_collect_ui');
    recorder = FakeStereoRecorder()
      ..devices = const [
        InputDevice(id: 9, name: 'USB Audio', type: 11, isExternal: true),
      ];
    container = ProviderContainer(
      overrides: [
        stereoRecorderProvider.overrideWithValue(recorder),
        collectionStorageProvider.overrideWith(
          (ref) async => CollectionStorage(dir),
        ),
        inputChoiceStoreProvider.overrideWithValue(
          MemoryInputChoiceStore((
            id: 9,
            name: 'USB Audio',
            type: 11,
            isExternal: true,
          )),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await dir.delete(recursive: true);
  });

  /// Sends [signal] in 100 ms blocks like the platform.
  Future<void> play(StereoBlock signal) async {
    final pcm = interleavePcm16(signal).buffer.asUint8List();
    const blockBytes = 4800 * 4;
    for (var i = 0; i < pcm.length; i += blockBytes) {
      final end = i + blockBytes > pcm.length ? pcm.length : i + blockBytes;
      recorder.emit(Uint8List.sublistView(pcm, i, end));
      await flush();
    }
  }

  test(
    'records with the app-wide device and saves one clip per pass',
    () async {
      final controller = container.read(collectControllerProvider.notifier);
      await controller.start();
      final state = container.read(collectControllerProvider);
      expect(state.running, isTrue);
      expect(recorder.lastInputDeviceId, 9);

      final rec = PassBySimulator(Scenarios.setup(backgroundRms: 0.002))
          .render(40, [
            Scenarios.combustion(speedKmh: 40, distance: 4.1, t0: 10),
            Scenarios.electric(speedKmh: 30, distance: 4.1, t0: 28),
          ]);
      await play(rec.signal);
      // Both passes end more than one window before the end: found live.
      expect(container.read(collectControllerProvider).clipCount, 2);

      await controller.stop();
      final done = container.read(collectControllerProvider);
      expect(done.running, isFalse);
      expect(done.clipCount, 2);
      expect(recorder.stopCalls, 1);

      final storage = CollectionStorage(dir);
      final m = (await storage.read(done.collectionId!))!;
      expect(m.clips, hasLength(2));
      expect(m.inputDevice, 'USB Audio');
      expect(m.deviceModel, 'Fake Phone');
      expect(m.source, 'live');
      expect(m.recordedS, closeTo(40, 0.1));
      expect(m.clips.every((c) => c.label == ClipLabel.open), isTrue);
      for (final c in m.clips) {
        expect(await storage.clipFile(m.id, c.file).exists(), isTrue);
      }
    },
  );

  test('a missing permission is reported, nothing keeps running', () async {
    recorder = FakeStereoRecorder(
      startError: const MicrophonePermissionDeniedException(),
    );
    final c = ProviderContainer(
      overrides: [
        stereoRecorderProvider.overrideWithValue(recorder),
        collectionStorageProvider.overrideWith(
          (ref) async => CollectionStorage(dir),
        ),
      ],
    );
    addTearDown(c.dispose);
    await c.read(collectControllerProvider.notifier).start();
    final state = c.read(collectControllerProvider);
    expect(state.running, isFalse);
    expect(state.error, contains('Berechtigung'));
  });
}

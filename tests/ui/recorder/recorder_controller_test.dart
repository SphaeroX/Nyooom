import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/stereo_recorder.dart';
import 'package:nyooom/audio/wav.dart';
import 'package:nyooom/core/signal/level.dart';
import 'package:nyooom/core/signal/stereo_content.dart';
import 'package:nyooom/ui/device/input_device_selection.dart';
import 'package:nyooom/ui/recorder/recorder_controller.dart';

import '../../helpers/fake_stereo_recorder.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late Directory dir;
  late FakeStereoRecorder recorder;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nyooom_rec_test');
  });

  tearDown(() async {
    await dir.delete(recursive: true);
  });

  ProviderContainer makeContainer(FakeStereoRecorder fake) {
    recorder = fake;
    final container = ProviderContainer(
      overrides: [
        stereoRecorderProvider.overrideWithValue(fake),
        recordingsDirectoryProvider.overrideWith((ref) async => dir),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('start reports the audio source and levels per channel', () async {
    final container = makeContainer(FakeStereoRecorder());
    final controller = container.read(recorderControllerProvider.notifier);

    await controller.start();
    var state = container.read(recorderControllerProvider);
    expect(state.running, isTrue);
    expect(state.info!.audioSource, AudioSourceKind.unprocessed);

    recorder.emit(sinePcm16(leftAmplitude: 0.5, rightAmplitude: 0));
    await flush();
    state = container.read(recorderControllerProvider);
    expect(state.left.rmsDbfs, closeTo(-9.03, 0.05));
    expect(state.right.rmsDbfs, silenceDbfs);
    expect(state.left.clipping, isFalse);
  });

  test('flags clipping and remembers it until the next start', () async {
    final container = makeContainer(FakeStereoRecorder());
    final controller = container.read(recorderControllerProvider.notifier);
    await controller.start();

    recorder.emit(sinePcm16(leftAmplitude: 0.1, rightAmplitude: 0.95));
    await flush();
    recorder.emit(sinePcm16(leftAmplitude: 0.1, rightAmplitude: 0.1));
    await flush();
    final state = container.read(recorderControllerProvider);
    expect(state.right.clipping, isFalse);
    expect(state.rightClipSeen, isTrue);
    expect(state.leftClipSeen, isFalse);
  });

  test('missing permission shows an error and does not run', () async {
    final container = makeContainer(
      FakeStereoRecorder(
        startError: const MicrophonePermissionDeniedException('denied'),
      ),
    );
    await container.read(recorderControllerProvider.notifier).start();
    final state = container.read(recorderControllerProvider);
    expect(state.running, isFalse);
    expect(state.error, contains('Berechtigung'));
  });

  test('saving writes the received blocks as a stereo WAV', () async {
    final container = makeContainer(FakeStereoRecorder());
    final controller = container.read(recorderControllerProvider.notifier);
    await controller.start();
    await controller.startSaving();
    expect(container.read(recorderControllerProvider).saving, isTrue);

    final a = sinePcm16(leftAmplitude: 0.5, rightAmplitude: 0.25, frames: 100);
    final b = sinePcm16(leftAmplitude: 0.2, rightAmplitude: 0.4, frames: 50);
    recorder.emit(a);
    recorder.emit(b);
    await flush();
    await controller.stopSaving();

    final state = container.read(recorderControllerProvider);
    expect(state.saving, isFalse);
    final file = File(state.savedPath!);
    expect(file.parent.path, dir.path);
    final wav = decodeWav(await file.readAsBytes());
    expect(wav.channels, 2);
    expect(wav.sampleRate, 48000);
    expect(wav.bitsPerSample, 16);
    expect(wav.samples.buffer.asUint8List(), Uint8List.fromList([...a, ...b]));
  });

  test('stop ends the recording and finishes an open WAV', () async {
    final container = makeContainer(FakeStereoRecorder());
    final controller = container.read(recorderControllerProvider.notifier);
    await controller.start();
    await controller.startSaving();
    recorder.emit(sinePcm16(leftAmplitude: 0.5, rightAmplitude: 0.5));
    await flush();
    await controller.stop();

    final state = container.read(recorderControllerProvider);
    expect(recorder.stopCalls, 1);
    expect(state.running, isFalse);
    expect(state.saving, isFalse);
    expect(
      decodeWav(await File(state.savedPath!).readAsBytes()).frameCount,
      4800,
    );
  });

  test('the level test records from the chosen input device', () async {
    final fake = FakeStereoRecorder()
      ..devices = const [
        InputDevice(id: 9, name: 'USB Audio', type: 11, isExternal: true),
      ];
    final container = makeContainer(fake);
    final devices = await container.read(inputDevicesProvider.future);
    container.read(inputDeviceChoiceProvider.notifier).choose(devices.single);

    await container.read(recorderControllerProvider.notifier).start();
    expect(recorder.lastInputDeviceId, 9);
  });

  test(
    'the level test tells a duplicated mono signal from real stereo',
    () async {
      final container = makeContainer(FakeStereoRecorder());
      final controller = container.read(recorderControllerProvider.notifier);
      await controller.start();
      expect(container.read(recorderControllerProvider).stereoContent, isNull);

      // One second of the same signal on both channels (scaled): mono.
      for (var i = 0; i < 10; i++) {
        recorder.emit(sinePcm16(leftAmplitude: 0.3, rightAmplitude: 0.15));
      }
      await flush();
      expect(
        container.read(recorderControllerProvider).stereoContent?.kind,
        StereoContentKind.identical,
      );

      // Then two independent signals: distinct channels.
      for (var i = 0; i < 10; i++) {
        recorder.emit(noisePcm16(seed: i));
      }
      await flush();
      expect(
        container.read(recorderControllerProvider).stereoContent?.kind,
        StereoContentKind.distinct,
      );
    },
  );
}

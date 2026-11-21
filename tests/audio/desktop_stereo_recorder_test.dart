import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/desktop_stereo_recorder.dart';
import 'package:nyooom/audio/stereo_recorder.dart';

class FakeBackend implements DesktopAudioBackend {
  List<DesktopInput> available = const [
    (id: '{guid-headset}', label: 'Headset-Mikrofon', sampleRates: [48000]),
    (id: '{guid-usb}', label: 'USB Audio', sampleRates: []),
  ];
  bool permission = true;
  StreamController<Uint8List>? stream;
  String? startedDevice;
  int? startedRate;
  int? startedChannels;
  int stops = 0;

  @override
  Future<List<DesktopInput>> inputs() async => available;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<Stream<Uint8List>> startStream({
    required int sampleRate,
    required int channels,
    String? deviceId,
  }) async {
    startedDevice = deviceId;
    startedRate = sampleRate;
    startedChannels = channels;
    stream = StreamController<Uint8List>();
    return stream!.stream;
  }

  @override
  Future<void> stop() async {
    stops++;
    await stream?.close();
  }
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeBackend backend;
  late DesktopStereoRecorder recorder;

  setUp(() {
    backend = FakeBackend();
    recorder = DesktopStereoRecorder(
      backend: backend,
      computerName: 'Werkbank',
    );
  });

  test('lists the inputs with stable numeric ids', () async {
    final first = await recorder.inputDevices();
    final second = await recorder.inputDevices();
    expect(first.map((d) => d.name), ['Headset-Mikrofon', 'USB Audio']);
    expect(first.map((d) => d.id), second.map((d) => d.id));
    expect(first.first.id, isNot(first.last.id));
    expect(first.first.label, 'Headset-Mikrofon (PC)');
    expect(first.first.sampleRates, [48000]);
  });

  test('records stereo PCM from the chosen input', () async {
    final usb = (await recorder.inputDevices()).last;
    final blocks = <Uint8List>[];
    final sub = recorder.pcmBlocks.listen(blocks.add);
    final info = await recorder.start(sampleRate: 48000, inputDeviceId: usb.id);
    expect(backend.startedDevice, '{guid-usb}');
    expect(backend.startedRate, 48000);
    expect(backend.startedChannels, 2);
    expect(info.channels, 2);
    expect(info.sampleRate, 48000);
    expect(info.routedDevice, 'USB Audio');

    backend.stream!.add(Uint8List.fromList(List.filled(8, 1)));
    await flush();
    expect(blocks.single, hasLength(8));

    await recorder.stop();
    expect(backend.stops, 1);
    await sub.cancel();
  });

  test('without a chosen input the default device is used', () async {
    await recorder.start(sampleRate: 48000);
    expect(backend.startedDevice, isNull);
    await recorder.stop();
  });

  test('blocks are cut to whole stereo frames', () async {
    final blocks = <Uint8List>[];
    final sub = recorder.pcmBlocks.listen(blocks.add);
    await recorder.start(sampleRate: 48000);
    backend.stream!.add(Uint8List.fromList([1, 2, 3, 4, 5, 6]));
    backend.stream!.add(Uint8List.fromList([7, 8, 9, 10]));
    await flush();
    expect(blocks.map((b) => b.length), [4, 4]);
    expect(blocks.last, [5, 6, 7, 8]);
    await recorder.stop();
    await sub.cancel();
  });

  test('a refused microphone permission is reported', () async {
    backend.permission = false;
    expect(
      () => recorder.start(sampleRate: 48000),
      throwsA(isA<MicrophonePermissionDeniedException>()),
    );
  });

  test('capabilities name the computer', () async {
    final caps = await recorder.capabilities();
    expect(caps.deviceModel, 'Werkbank');
  });
}

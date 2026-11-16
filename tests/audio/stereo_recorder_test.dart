import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/stereo_recorder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel(StereoRecorder.methodChannelName);
  const eventChannel = EventChannel(StereoRecorder.eventChannelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<MethodCall> calls;

  setUp(() {
    calls = [];
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockStreamHandler(eventChannel, null);
  });

  void mockMethods(Future<Object?> Function(MethodCall call) handler) {
    messenger.setMockMethodCallHandler(methodChannel, (call) {
      calls.add(call);
      return handler(call);
    });
  }

  test('reads device capabilities', () async {
    mockMethods(
      (call) async => {
        'unprocessedSupported': true,
        'agcAvailable': true,
        'nsAvailable': false,
        'aecAvailable': true,
        'deviceModel': 'Pixel 8',
        'sdkInt': 34,
        'microphones': ['bottom', 'top'],
      },
    );
    final caps = await StereoRecorder().capabilities();
    expect(calls.single.method, 'getCapabilities');
    expect(caps.unprocessedSupported, isTrue);
    expect(caps.agcAvailable, isTrue);
    expect(caps.nsAvailable, isFalse);
    expect(caps.aecAvailable, isTrue);
    expect(caps.deviceModel, 'Pixel 8');
    expect(caps.sdkInt, 34);
    expect(caps.microphones, ['bottom', 'top']);
  });

  test('start passes the sample rate and reports source and effects', () async {
    mockMethods(
      (call) async => {
        'audioSource': 'UNPROCESSED',
        'sampleRate': 48000,
        'channels': 2,
        'effects': {'agc': 'disabled', 'ns': 'unavailable', 'aec': 'enabled'},
      },
    );
    final info = await StereoRecorder().start(sampleRate: 48000);
    expect(calls.single.method, 'start');
    expect(calls.single.arguments, {'sampleRate': 48000});
    expect(info.audioSource, AudioSourceKind.unprocessed);
    expect(info.sampleRate, 48000);
    expect(info.channels, 2);
    expect(info.effects['agc'], EffectState.disabled);
    expect(info.effects['ns'], EffectState.unavailable);
    expect(info.effects['aec'], EffectState.enabled);
  });

  test('reports the VOICE_RECOGNITION fallback', () async {
    mockMethods(
      (call) async => {
        'audioSource': 'VOICE_RECOGNITION',
        'sampleRate': 48000,
        'channels': 2,
        'effects': <String, String>{},
      },
    );
    final info = await StereoRecorder().start(sampleRate: 48000);
    expect(info.audioSource, AudioSourceKind.voiceRecognition);
  });

  test('missing permission surfaces as a typed exception', () async {
    mockMethods((call) async {
      throw PlatformException(code: 'PERMISSION_DENIED', message: 'denied');
    });
    expect(
      StereoRecorder().start(sampleRate: 48000),
      throwsA(isA<MicrophonePermissionDeniedException>()),
    );
  });

  test('other platform errors are passed through', () async {
    mockMethods((call) async {
      throw PlatformException(code: 'INIT_FAILED', message: 'boom');
    });
    expect(
      StereoRecorder().start(sampleRate: 48000),
      throwsA(isA<PlatformException>()),
    );
  });

  test('receives PCM blocks as de-interleaved stereo', () async {
    messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (arguments, sink) {
          sink.success(Uint8List.fromList([0x00, 0x40, 0x00, 0xC0]));
          sink.success(Uint8List.fromList([0x00, 0x20, 0x00, 0xE0]));
          sink.endOfStream();
        },
      ),
    );
    final blocks = await StereoRecorder().blocks.toList();
    expect(blocks, hasLength(2));
    expect(blocks[0].left, [0.5]);
    expect(blocks[0].right, [-0.5]);
    expect(blocks[1].left, [0.25]);
    expect(blocks[1].right, [-0.25]);
  });

  test('raw PCM blocks are available for writing WAV files', () async {
    final bytes = Uint8List.fromList([1, 2, 3, 4]);
    messenger.setMockStreamHandler(
      eventChannel,
      MockStreamHandler.inline(
        onListen: (arguments, sink) {
          sink.success(bytes);
          sink.endOfStream();
        },
      ),
    );
    expect(await StereoRecorder().pcmBlocks.toList(), [bytes]);
  });

  test('stop calls the platform', () async {
    mockMethods((call) async => null);
    await StereoRecorder().stop();
    expect(calls.single.method, 'stop');
  });

  test('lists input devices for the selection', () async {
    mockMethods(
      (call) async => [
        {
          'id': 3,
          'name': 'Built-in mic',
          'type': 15,
          'isExternal': false,
          'channelCounts': [1, 2],
        },
        {
          'id': 9,
          'name': 'USB Audio',
          'type': 11,
          'isExternal': true,
          'channelCounts': [2],
        },
      ],
    );
    final devices = await StereoRecorder().inputDevices();
    expect(calls.single.method, 'getInputDevices');
    expect(devices.map((d) => d.id), [3, 9]);
    expect(devices[1].isExternal, isTrue);
    expect(devices[1].name, 'USB Audio');
  });

  test('start passes the chosen input device', () async {
    mockMethods((call) async => {'audioSource': 'UNPROCESSED'});
    await StereoRecorder().start(sampleRate: 48000, inputDeviceId: 9);
    expect(calls.single.arguments, {'sampleRate': 48000, 'inputDeviceId': 9});
  });
}

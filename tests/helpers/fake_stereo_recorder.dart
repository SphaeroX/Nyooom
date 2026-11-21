import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/audio/stereo_recorder.dart';
import 'package:nyooom/core/signal/pcm.dart';

/// In-memory stand-in for the platform recorder.
class FakeStereoRecorder implements StereoRecorder {
  FakeStereoRecorder({
    this.capabilitiesResult = const AudioCapabilities(
      unprocessedSupported: true,
      agcAvailable: true,
      nsAvailable: false,
      aecAvailable: true,
      deviceModel: 'Fake Phone',
      sdkInt: 34,
      microphones: ['bottom', 'top'],
    ),
    this.startResult = const RecordingInfo(
      audioSource: AudioSourceKind.unprocessed,
      sampleRate: 48000,
      channels: 2,
      effects: {
        'agc': EffectState.disabled,
        'ns': EffectState.unavailable,
        'aec': EffectState.disabled,
      },
    ),
    this.startError,
  });

  final AudioCapabilities capabilitiesResult;
  final RecordingInfo startResult;
  final Object? startError;

  final _controller = StreamController<Uint8List>.broadcast();
  int startCalls = 0;
  int stopCalls = 0;

  /// Emits one block of interleaved little-endian 16-bit PCM.
  void emit(Uint8List bytes) => _controller.add(bytes);

  @override
  Future<AudioCapabilities> capabilities() async => capabilitiesResult;

  /// Input device id of the last start call.
  int? lastInputDeviceId;

  List<InputDevice> devices = const [
    InputDevice(id: 1, name: 'Intern', type: 15, isExternal: false),
  ];

  @override
  Future<List<InputDevice>> inputDevices() async => devices;

  final _deviceChanges = StreamController<void>.broadcast();

  /// Simulates plugging a device in or out.
  void emitDeviceChange() => _deviceChanges.add(null);

  @override
  Stream<void> get deviceChanges => _deviceChanges.stream;

  @override
  Future<RecordingInfo> start({
    required int sampleRate,
    int? inputDeviceId,
  }) async {
    startCalls++;
    lastInputDeviceId = inputDeviceId;
    final error = startError;
    if (error != null) throw error;
    return startResult;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
  }

  @override
  Stream<Uint8List> get pcmBlocks => _controller.stream;

  @override
  Stream<StereoBlock> get blocks => pcmBlocks.map(deinterleavePcm16Bytes);
}

/// Interleaved 16-bit PCM with a 1 kHz sine of [leftAmplitude] on the left
/// and [rightAmplitude] on the right channel.
Uint8List sinePcm16({
  required double leftAmplitude,
  required double rightAmplitude,
  int frames = 4800,
  int sampleRate = 48000,
}) {
  final samples = Int16List(frames * 2);
  for (var n = 0; n < frames; n++) {
    final s = math.sin(2 * math.pi * 1000 * n / sampleRate);
    samples[2 * n] = (leftAmplitude * s * 32767).round();
    samples[2 * n + 1] = (rightAmplitude * s * 32767).round();
  }
  return samples.buffer.asUint8List();
}

/// Interleaved 16-bit PCM with independent noise on both channels.
Uint8List noisePcm16({
  int seed = 1,
  double amplitude = 0.2,
  int frames = 4800,
}) {
  final rnd = math.Random(seed);
  final samples = Int16List(frames * 2);
  for (var i = 0; i < samples.length; i++) {
    samples[i] = ((rnd.nextDouble() * 2 - 1) * amplitude * 32767).round();
  }
  return samples.buffer.asUint8List();
}

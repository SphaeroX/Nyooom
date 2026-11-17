import 'package:flutter/services.dart';

import '../core/signal/pcm.dart';

/// Audio source the platform actually opened (technik.pdf 4.3).
enum AudioSourceKind {
  unprocessed('UNPROCESSED'),
  voiceRecognition('VOICE_RECOGNITION'),
  simulated('SIMULATED'),
  unknown('UNKNOWN');

  const AudioSourceKind(this.platformName);

  final String platformName;

  static AudioSourceKind fromPlatform(String? name) =>
      values.firstWhere((v) => v.platformName == name, orElse: () => unknown);
}

/// State of a pre-processing effect (AGC, NS, AEC) for the session.
enum EffectState {
  /// The device has no such effect for this session.
  unavailable,

  /// The effect exists and was switched off.
  disabled,

  /// The effect exists and could not be switched off.
  enabled;

  static EffectState fromPlatform(Object? name) =>
      values.firstWhere((v) => v.name == name, orElse: () => unavailable);
}

/// What the device reports before recording.
class AudioCapabilities {
  const AudioCapabilities({
    required this.unprocessedSupported,
    required this.agcAvailable,
    required this.nsAvailable,
    required this.aecAvailable,
    required this.deviceModel,
    required this.sdkInt,
    required this.microphones,
  });

  factory AudioCapabilities.fromMap(Map<Object?, Object?> map) =>
      AudioCapabilities(
        unprocessedSupported: map['unprocessedSupported'] == true,
        agcAvailable: map['agcAvailable'] == true,
        nsAvailable: map['nsAvailable'] == true,
        aecAvailable: map['aecAvailable'] == true,
        deviceModel: map['deviceModel'] as String? ?? '',
        sdkInt: (map['sdkInt'] as num?)?.toInt() ?? 0,
        microphones: [
          for (final m in (map['microphones'] as List?) ?? const []) '$m',
        ],
      );

  final bool unprocessedSupported;
  final bool agcAvailable;
  final bool nsAvailable;
  final bool aecAvailable;
  final String deviceModel;
  final int sdkInt;

  /// Human-readable microphone descriptions (Android 9+, may be empty).
  final List<String> microphones;
}

/// What the platform actually opened when recording started.
class RecordingInfo {
  const RecordingInfo({
    required this.audioSource,
    required this.sampleRate,
    required this.channels,
    required this.effects,
    this.preferredDevice,
  });

  factory RecordingInfo.fromMap(Map<Object?, Object?> map) => RecordingInfo(
    audioSource: AudioSourceKind.fromPlatform(map['audioSource'] as String?),
    sampleRate: (map['sampleRate'] as num?)?.toInt() ?? 0,
    channels: (map['channels'] as num?)?.toInt() ?? 0,
    effects: {
      for (final e in ((map['effects'] as Map?) ?? const {}).entries)
        '${e.key}': EffectState.fromPlatform(e.value),
    },
    preferredDevice: switch (map['preferredDevice']) {
      final String name when name.isNotEmpty => name,
      _ => null,
    },
  );

  final AudioSourceKind audioSource;
  final int sampleRate;
  final int channels;

  /// Effect states keyed by `agc`, `ns` and `aec`.
  final Map<String, EffectState> effects;

  /// External input Android routed the recording to; null for the
  /// internal microphones (or when the requested device was not accepted).
  final String? preferredDevice;
}

/// Thrown when the user did not grant the microphone permission.
/// An audio input (internal microphones or USB interface, technik.pdf 4.3).
class InputDevice {
  const InputDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.isExternal,
    this.channelCounts = const [],
  });

  factory InputDevice.fromMap(Map<Object?, Object?> map) => InputDevice(
    id: (map['id'] as num).toInt(),
    name: map['name'] as String? ?? '',
    type: (map['type'] as num?)?.toInt() ?? 0,
    isExternal: map['isExternal'] == true,
    channelCounts: [
      for (final c in map['channelCounts'] as List? ?? const [])
        (c as num).toInt(),
    ],
  );

  final int id;
  final String name;

  /// Android `AudioDeviceInfo.TYPE_*`.
  final int type;
  final bool isExternal;

  /// Channel counts the device reports; empty means any (Android reports
  /// nothing for many devices).
  final List<int> channelCounts;

  /// Whether the device can deliver two channels (two microphones).
  bool get supportsStereo =>
      channelCounts.isEmpty || channelCounts.any((c) => c >= 2);
}

/// The input a measurement series should use by default: the first
/// external device with two channels (USB stereo microphone, technik.pdf
/// 4.3), otherwise null for the internal microphones.
InputDevice? preferredInputDevice(List<InputDevice> devices) {
  for (final d in devices) {
    if (d.isExternal && d.supportsStereo) return d;
  }
  return null;
}

class MicrophonePermissionDeniedException implements Exception {
  const MicrophonePermissionDeniedException([this.message]);

  final String? message;

  @override
  String toString() => 'MicrophonePermissionDeniedException: $message';
}

/// Dart side of the Kotlin recording plugin (`NyooomAudioPlugin`).
///
/// Subscribe to [pcmBlocks] or [blocks] before calling [start]; the stream
/// carries interleaved little-endian 16-bit stereo PCM.
class StereoRecorder {
  StereoRecorder({MethodChannel? method, EventChannel? events})
    : _method = method ?? const MethodChannel(methodChannelName),
      _events = events ?? const EventChannel(eventChannelName);

  static const methodChannelName = 'de.nyooom/audio';
  static const eventChannelName = 'de.nyooom/audio_stream';

  final MethodChannel _method;
  final EventChannel _events;

  Future<AudioCapabilities> capabilities() async {
    final map = await _method.invokeMapMethod<Object?, Object?>(
      'getCapabilities',
    );
    return AudioCapabilities.fromMap(map ?? const {});
  }

  /// Starts recording; requests the microphone permission if needed.
  Future<List<InputDevice>> inputDevices() async {
    final list = await _method.invokeListMethod<Object?>('getInputDevices');
    return [
      for (final m in list ?? const [])
        InputDevice.fromMap((m as Map).cast<Object?, Object?>()),
    ];
  }

  Future<RecordingInfo> start({
    required int sampleRate,
    int? inputDeviceId,
  }) async {
    try {
      final map = await _method.invokeMapMethod<Object?, Object?>('start', {
        'sampleRate': sampleRate,
        'inputDeviceId': ?inputDeviceId,
      });
      return RecordingInfo.fromMap(map ?? const {});
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        throw MicrophonePermissionDeniedException(e.message);
      }
      rethrow;
    }
  }

  Future<void> stop() => _method.invokeMethod<void>('stop');

  /// Raw interleaved PCM blocks as delivered by the platform.
  Stream<Uint8List> get pcmBlocks =>
      _events.receiveBroadcastStream().map((event) => event as Uint8List);

  /// PCM blocks split into two normalized channels.
  Stream<StereoBlock> get blocks => pcmBlocks.map(deinterleavePcm16Bytes);
}

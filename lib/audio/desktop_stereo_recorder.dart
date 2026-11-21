import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:record/record.dart' as rec;

import '../core/signal/pcm.dart';
import 'stereo_recorder.dart';

/// An audio input as the desktop audio API reports it.
typedef DesktopInput = ({String id, String label, List<int> sampleRates});

/// The part of the desktop audio API the recorder needs (replaceable in
/// tests).
abstract interface class DesktopAudioBackend {
  Future<List<DesktopInput>> inputs();
  Future<bool> hasPermission();

  /// Interleaved little-endian 16-bit PCM; [deviceId] null means the
  /// system default input.
  Future<Stream<Uint8List>> startStream({
    required int sampleRate,
    required int channels,
    String? deviceId,
  });
  Future<void> stop();
}

/// [DesktopAudioBackend] through the `record` package (Windows: Media
/// Foundation). Automatic gain, echo cancellation and noise suppression
/// are switched off, like on Android (technik.pdf 4.2).
class RecordPackageBackend implements DesktopAudioBackend {
  /// Created on first use (the constructor talks to the platform).
  late final _recorder = rec.AudioRecorder();

  @override
  Future<List<DesktopInput>> inputs() async => [
    for (final d in await _recorder.listInputDevices())
      (id: d.id, label: d.label, sampleRates: d.sampleRates),
  ];

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<Stream<Uint8List>> startStream({
    required int sampleRate,
    required int channels,
    String? deviceId,
  }) async {
    rec.InputDevice? device;
    if (deviceId != null) {
      for (final d in await _recorder.listInputDevices()) {
        if (d.id == deviceId) device = d;
      }
    }
    return _recorder.startStream(
      rec.RecordConfig(
        encoder: rec.AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: channels,
        device: device,
        autoGain: false,
        echoCancel: false,
        noiseSuppress: false,
      ),
    );
  }

  @override
  Future<void> stop() async {
    await _recorder.stop();
  }
}

/// [StereoRecorder] for the desktop (Windows), where the Kotlin plugin does
/// not exist.
class DesktopStereoRecorder implements StereoRecorder {
  DesktopStereoRecorder({DesktopAudioBackend? backend, String? computerName})
    : _backend = backend ?? RecordPackageBackend(),
      _computerName = computerName ?? Platform.localHostname;

  final DesktopAudioBackend _backend;
  final String _computerName;
  final _pcm = StreamController<Uint8List>.broadcast();
  final _deviceChanges = StreamController<void>.broadcast();
  StreamSubscription<Uint8List>? _sub;

  /// Platform ids (strings) mapped to the numeric ids of [InputDevice].
  final Map<String, int> _ids = {};
  final Map<int, DesktopInput> _byId = {};

  /// Bytes of an incomplete stereo frame from the previous block.
  final BytesBuilder _rest = BytesBuilder(copy: false);

  @override
  Future<AudioCapabilities> capabilities() async => AudioCapabilities(
    unprocessedSupported: false,
    agcAvailable: false,
    nsAvailable: false,
    aecAvailable: false,
    deviceModel: _computerName,
    sdkInt: 0,
    microphones: const [],
  );

  @override
  Future<List<InputDevice>> inputDevices() async {
    final list = <InputDevice>[];
    for (final d in await _backend.inputs()) {
      final id = _ids.putIfAbsent(d.id, () => _ids.length + 1);
      _byId[id] = d;
      list.add(
        InputDevice(
          id: id,
          name: d.label,
          type: desktopInputType,
          isExternal: true,
          sampleRates: d.sampleRates,
        ),
      );
    }
    return list;
  }

  /// The desktop API reports no plug events; the list is reloaded with the
  /// refresh button.
  @override
  Stream<void> get deviceChanges => _deviceChanges.stream;

  @override
  Future<RecordingInfo> start({
    required int sampleRate,
    int? inputDeviceId,
  }) async {
    if (!await _backend.hasPermission()) {
      throw const MicrophonePermissionDeniedException(
        'Kein Zugriff auf das Mikrofon (Windows-Datenschutzeinstellungen).',
      );
    }
    final input = inputDeviceId == null ? null : _byId[inputDeviceId];
    _rest.clear();
    final stream = await _backend.startStream(
      sampleRate: sampleRate,
      channels: 2,
      deviceId: input?.id,
    );
    _sub = stream.listen(_onBytes);
    return RecordingInfo(
      audioSource: AudioSourceKind.unknown,
      sampleRate: sampleRate,
      channels: 2,
      effects: const {
        'agc': EffectState.unavailable,
        'ns': EffectState.unavailable,
        'aec': EffectState.unavailable,
      },
      preferredDevice: input?.label,
      routedDevice: input?.label ?? '',
      routedDeviceId: inputDeviceId,
    );
  }

  void _onBytes(Uint8List bytes) {
    _rest.add(bytes);
    final all = _rest.takeBytes();
    final whole = all.length - all.length % 4;
    if (whole < all.length) _rest.add(Uint8List.sublistView(all, whole));
    if (whole > 0) _pcm.add(Uint8List.sublistView(all, 0, whole));
  }

  @override
  Future<void> stop() async {
    await _backend.stop();
    await _sub?.cancel();
    _sub = null;
  }

  @override
  Stream<Uint8List> get pcmBlocks => _pcm.stream;

  @override
  Stream<StereoBlock> get blocks => pcmBlocks.map(deinterleavePcm16Bytes);
}

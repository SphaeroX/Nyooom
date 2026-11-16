import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../audio/stereo_recorder.dart';
import '../../audio/wav.dart';
import '../../core/config/nyooom_config.dart';
import '../../core/signal/level.dart';
import '../../core/signal/pcm.dart';

final configProvider = Provider<NyooomConfig>((ref) => const NyooomConfig());

final stereoRecorderProvider = Provider<StereoRecorder>(
  (ref) => StereoRecorder(),
);

final capabilitiesProvider = FutureProvider<AudioCapabilities>(
  (ref) => ref.watch(stereoRecorderProvider).capabilities(),
);

/// Folder for raw WAV recordings inside the app documents directory.
final recordingsDirectoryProvider = FutureProvider<Directory>((ref) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}${Platform.pathSeparator}recordings');
  await dir.create(recursive: true);
  return dir;
});

final recorderControllerProvider =
    NotifierProvider<RecorderController, RecorderState>(RecorderController.new);

const Object _unchanged = Object();

class RecorderState {
  const RecorderState({
    this.running = false,
    this.info,
    this.left = ChannelLevel.silence,
    this.right = ChannelLevel.silence,
    this.leftClipSeen = false,
    this.rightClipSeen = false,
    this.saving = false,
    this.savedPath,
    this.error,
  });

  final bool running;
  final RecordingInfo? info;
  final ChannelLevel left;
  final ChannelLevel right;

  /// Sticky clipping flags since the last start (technik.pdf 4.4, check 3).
  final bool leftClipSeen;
  final bool rightClipSeen;

  final bool saving;
  final String? savedPath;
  final String? error;

  RecorderState copyWith({
    bool? running,
    Object? info = _unchanged,
    ChannelLevel? left,
    ChannelLevel? right,
    bool? leftClipSeen,
    bool? rightClipSeen,
    bool? saving,
    Object? savedPath = _unchanged,
    Object? error = _unchanged,
  }) => RecorderState(
    running: running ?? this.running,
    info: identical(info, _unchanged) ? this.info : info as RecordingInfo?,
    left: left ?? this.left,
    right: right ?? this.right,
    leftClipSeen: leftClipSeen ?? this.leftClipSeen,
    rightClipSeen: rightClipSeen ?? this.rightClipSeen,
    saving: saving ?? this.saving,
    savedPath: identical(savedPath, _unchanged)
        ? this.savedPath
        : savedPath as String?,
    error: identical(error, _unchanged) ? this.error : error as String?,
  );
}

/// Drives the recorder: live levels per channel and optional WAV saving.
class RecorderController extends Notifier<RecorderState> {
  StreamSubscription<Uint8List>? _subscription;
  WavFileWriter? _writer;
  String? _writerPath;
  Future<void> _pendingWrites = Future.value();

  @override
  RecorderState build() {
    ref.onDispose(() {
      _subscription?.cancel();
      _subscription = null;
    });
    return const RecorderState();
  }

  Future<void> start() async {
    if (state.running) return;
    final recorder = ref.read(stereoRecorderProvider);
    final config = ref.read(configProvider);
    // Subscribe first so that the platform has a sink when audio arrives.
    _subscription = recorder.pcmBlocks.listen(
      _onPcm,
      onError: (Object e) => state = state.copyWith(error: 'Stream-Fehler: $e'),
    );
    try {
      final info = await recorder.start(sampleRate: config.sampleRate);
      if (!ref.mounted) return;
      state = RecorderState(running: true, info: info);
    } on MicrophonePermissionDeniedException {
      _failStart(
        'Mikrofon-Berechtigung fehlt. Bitte in den Einstellungen erlauben.',
      );
    } on PlatformException catch (e) {
      _failStart('Aufnahme fehlgeschlagen: ${e.message}');
    }
  }

  void _failStart(String message) {
    _cancelSubscription();
    if (ref.mounted) state = state.copyWith(error: message);
  }

  Future<void> stop() async {
    if (!state.running) return;
    await stopSaving();
    await ref.read(stereoRecorderProvider).stop();
    _cancelSubscription();
    if (!ref.mounted) return;
    state = state.copyWith(
      running: false,
      left: ChannelLevel.silence,
      right: ChannelLevel.silence,
    );
  }

  /// Starts writing the incoming audio to a new WAV file.
  Future<void> startSaving() async {
    if (!state.running || _writer != null) return;
    final dir = await ref.read(recordingsDirectoryProvider.future);
    if (!ref.mounted || !state.running || _writer != null) return;
    final path =
        '${dir.path}${Platform.pathSeparator}'
        'nyooom_${_timestamp(DateTime.now())}.wav';
    final info = state.info!;
    _writer = await WavFileWriter.open(
      File(path),
      channels: info.channels,
      sampleRate: info.sampleRate,
    );
    _writerPath = path;
    state = state.copyWith(saving: true, savedPath: null);
  }

  Future<void> stopSaving() async {
    final writer = _writer;
    if (writer == null) return;
    _writer = null;
    await _pendingWrites;
    await writer.close();
    if (!ref.mounted) return;
    state = state.copyWith(saving: false, savedPath: _writerPath);
  }

  void _onPcm(Uint8List bytes) {
    final threshold = ref.read(configProvider).clipThreshold;
    final block = deinterleavePcm16Bytes(bytes);
    final left = measureLevel(block.left, clipThreshold: threshold);
    final right = measureLevel(block.right, clipThreshold: threshold);
    final writer = _writer;
    if (writer != null) {
      _pendingWrites = _pendingWrites.then((_) => writer.addPcm16Bytes(bytes));
    }
    state = state.copyWith(
      left: left,
      right: right,
      leftClipSeen: state.leftClipSeen || left.clipping,
      rightClipSeen: state.rightClipSeen || right.clipping,
    );
  }

  /// Cancels the PCM subscription without waiting for the platform side.
  void _cancelSubscription() {
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  static String _timestamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}_'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }
}

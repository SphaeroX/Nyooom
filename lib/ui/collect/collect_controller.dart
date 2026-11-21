import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../audio/clip_player.dart';
import '../../audio/input_devices.dart';
import '../../audio/platform_audio.dart';
import '../../audio/stereo_recorder.dart';
import '../../core/collect/clip_collector.dart';
import '../../core/collect/collection_manifest.dart';
import '../../core/signal/level.dart';
import '../../core/signal/pcm.dart';
import '../../data/collection_storage.dart';
import '../device/input_device_selection.dart';
import '../providers.dart';

/// Clip collections in the app documents directory.
final collectionStorageProvider = FutureProvider<CollectionStorage>(
  (ref) async =>
      CollectionStorage(await ref.watch(appDirectoryProvider.future)),
);

/// All collections, newest first.
final collectionsProvider = FutureProvider<List<CollectionManifest>>((
  ref,
) async {
  final storage = await ref.watch(collectionStorageProvider.future);
  return storage.list();
});

final collectionProvider = FutureProvider.family<CollectionManifest?, int>((
  ref,
  id,
) async {
  final storage = await ref.watch(collectionStorageProvider.future);
  return storage.read(id);
});

final clipPlayerProvider = Provider<ClipPlayer>(
  (ref) => clipPlayerFor(android: Platform.isAndroid),
);

/// Where the ZIP of an export is written before sharing.
final collectExportDirectoryProvider = FutureProvider<Directory>((ref) async {
  final temp = await getTemporaryDirectory();
  return Directory(
    '${temp.path}/exports/sammlung_${DateTime.now().millisecondsSinceEpoch}',
  );
});

class CollectState {
  const CollectState({
    this.running = false,
    this.starting = false,
    this.collectionId,
    this.elapsedS = 0,
    this.clipCount = 0,
    this.lastClipAboveFloorDb,
    this.left = ChannelLevel.silence,
    this.right = ChannelLevel.silence,
    this.error,
  });

  final bool running;
  final bool starting;
  final int? collectionId;

  /// Recorded signal duration in s (from the sample count).
  final double elapsedS;
  final int clipCount;

  /// Level of the newest clip above the noise floor, dB.
  final double? lastClipAboveFloorDb;
  final ChannelLevel left;
  final ChannelLevel right;
  final String? error;

  CollectState copyWith({
    bool? running,
    double? elapsedS,
    int? clipCount,
    double? lastClipAboveFloorDb,
    ChannelLevel? left,
    ChannelLevel? right,
  }) => CollectState(
    running: running ?? this.running,
    collectionId: collectionId,
    elapsedS: elapsedS ?? this.elapsedS,
    clipCount: clipCount ?? this.clipCount,
    lastClipAboveFloorDb: lastClipAboveFloorDb ?? this.lastClipAboveFloorDb,
    left: left ?? this.left,
    right: right ?? this.right,
    error: error,
  );
}

final collectControllerProvider =
    NotifierProvider<CollectController, CollectState>(CollectController.new);

/// Data collection: records with the app-wide input device, cuts every
/// detected event into a clip and stores it at once; only a few windows of
/// audio stay in memory. The user labels the clips afterwards.
class CollectController extends Notifier<CollectState> {
  StreamSubscription<Uint8List>? _subscription;
  StereoRecorder? _recorder;
  ClipCollector? _collector;
  CollectionStorage? _storage;
  CollectionManifest? _manifest;
  Future<void> _writes = Future.value();
  int _frames = 0;

  @override
  CollectState build() {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      _subscription = null;
      unawaited(_recorder?.stop());
    });
    return const CollectState();
  }

  Future<void> start() async {
    if (state.running || state.starting) return;
    state = const CollectState(starting: true);
    try {
      final config = ref.read(configProvider);
      final storage = await ref.read(collectionStorageProvider.future);
      final recorder = ref.read(stereoRecorderProvider);
      final device = await readActiveInputDevice(ref);
      final caps = await recorder.capabilities();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final manifest = CollectionManifest(
        id: now,
        createdAtUtcMs: now,
        source: 'live',
        deviceModel: caps.deviceModel,
        inputDevice: calibrationInputName(device),
        sampleRate: config.sampleRate,
        clips: const [],
      );
      await storage.write(manifest);
      _storage = storage;
      _manifest = manifest;
      _collector = ClipCollector(config: config);
      _frames = 0;
      _writes = Future.value();
      _recorder = recorder;
      _subscription = recorder.pcmBlocks.listen(_onPcm);
      await recorder.start(
        sampleRate: config.sampleRate,
        inputDeviceId: device?.id,
      );
      if (!ref.mounted) return;
      state = CollectState(running: true, collectionId: manifest.id);
    } on MicrophonePermissionDeniedException {
      await _abort(
        'Mikrofon-Berechtigung fehlt. Bitte in den Einstellungen erlauben.',
      );
    } on PlatformException catch (e) {
      await _abort('Aufnahme fehlgeschlagen: ${e.message}');
    } catch (e) {
      await _abort('Aufnahme fehlgeschlagen: $e');
    }
  }

  Future<void> _abort(String message) async {
    await _subscription?.cancel();
    _subscription = null;
    _recorder = null;
    final m = _manifest;
    if (m != null && m.clips.isEmpty) await _storage?.delete(m.id);
    _manifest = null;
    if (ref.mounted) state = CollectState(error: message);
  }

  Future<void> stop() async {
    if (!state.running) return;
    await _recorder?.stop();
    await _subscription?.cancel();
    _subscription = null;
    _recorder = null;
    final collector = _collector;
    _collector = null;
    if (collector != null) _store(collector.finish());
    await _writes;
    final config = ref.read(configProvider);
    final manifest = _manifest!.withRecorded(_frames / config.sampleRate);
    _manifest = manifest;
    await _storage!.write(manifest);
    if (!ref.mounted) return;
    state = state.copyWith(running: false, clipCount: manifest.clips.length);
    ref.invalidate(collectionsProvider);
    ref.invalidate(collectionProvider(manifest.id));
  }

  void _onPcm(Uint8List bytes) {
    final config = ref.read(configProvider);
    final block = deinterleavePcm16Bytes(bytes);
    _frames += block.length;
    final clips = _collector?.add(block) ?? const [];
    _store(clips);
    state = state.copyWith(
      elapsedS: _frames / config.sampleRate,
      clipCount: _manifest?.clips.length,
      lastClipAboveFloorDb: clips.isEmpty
          ? null
          : clips.last.event.levelAboveFloorDb,
      left: measureLevel(block.left, clipThreshold: config.clipThreshold),
      right: measureLevel(block.right, clipThreshold: config.clipThreshold),
    );
  }

  /// Adds [clips] to the manifest at once and writes their files in order.
  void _store(List<CollectedClip> clips) {
    final storage = _storage;
    if (clips.isEmpty || storage == null) return;
    final rate = ref.read(configProvider).sampleRate;
    for (final clip in clips) {
      final m = _manifest!;
      final name = m.nextClipFile;
      final next = m.withClip(clipEntry(clip, name, rate));
      _manifest = next;
      _writes = _writes.then((_) async {
        await storage.writeClip(m.id, name, clip.signal, rate);
        await storage.write(next);
      });
    }
  }
}

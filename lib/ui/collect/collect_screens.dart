import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../audio/clip_player.dart';
import '../../core/collect/collection_manifest.dart';
import '../../data/collection_storage.dart';
import '../device/input_device_selection.dart';
import '../export/export_buttons.dart';
import '../providers.dart';
import '../series/series_screens.dart'
    show CompactLevel, formatDate, formatDuration;
import 'collect_controller.dart';

/// "Sammeln" tab: clip collections for labelling.
class CollectionListScreen extends ConsumerWidget {
  const CollectionListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Daten sammeln')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('collect-new'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const CollectRecordingScreen(),
          ),
        ),
        icon: const Icon(Icons.fiber_manual_record),
        label: const Text('Neue Sammlung'),
      ),
      body: collections.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (list) => list.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Noch keine Sammlung. Eine Sammlung nimmt frei auf und '
                  'schneidet jedes laute Ereignis als Clip heraus. Danach '
                  'hörst du die Clips an und markierst, ob ein Auto zu '
                  'hören war. Clips aus einer Messreihe mit Rohaudio gibt '
                  'es in deren Detailansicht.',
                ),
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 88),
                children: [for (final m in list) _CollectionTile(m)],
              ),
      ),
    );
  }
}

class _CollectionTile extends ConsumerStatefulWidget {
  const _CollectionTile(this.manifest);

  final CollectionManifest manifest;

  @override
  ConsumerState<_CollectionTile> createState() => _CollectionTileState();
}

class _CollectionTileState extends ConsumerState<_CollectionTile> {
  bool _busy = false;

  CollectionManifest get m => widget.manifest;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final storage = await ref.read(collectionStorageProvider.future);
      final target = await ref.read(collectExportDirectoryProvider.future);
      final zip = await storage.exportZip(m.id, target);
      await ref.read(fileSharerProvider)([
        zip,
      ], 'Nyooom Sammlung ${formatDate(m.createdAtUtcMs)}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export fehlgeschlagen: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sammlung löschen?'),
        content: Text(
          'Alle ${m.clips.length} Clips und ihre Markierungen werden '
          'endgültig gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final storage = await ref.read(collectionStorageProvider.future);
    await storage.delete(m.id);
    ref.invalidate(collectionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        '${formatDate(m.createdAtUtcMs)}'
        '${m.source == 'live' ? '' : ' · ${m.source}'}',
      ),
      subtitle: Text(
        '${m.clips.length} Clips · ${m.labelledCount} markiert · '
        '${formatDuration(m.recordedS)} · ${m.inputDevice}',
      ),
      onTap: m.clips.isEmpty
          ? null
          : () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ClipLabelScreen(collectionId: m.id),
              ),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            key: Key('collection-export-${m.id}'),
            tooltip: 'ZIP mit Clips und Markierungen teilen',
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.ios_share),
          ),
          IconButton(
            tooltip: 'Löschen',
            onPressed: _busy ? null : _delete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

/// Free recording that cuts every detected event into a clip.
class CollectRecordingScreen extends ConsumerWidget {
  const CollectRecordingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(collectControllerProvider);
    final controller = ref.read(collectControllerProvider.notifier);
    final id = state.collectionId;
    return Scaffold(
      appBar: AppBar(title: const Text('Sammlung aufnehmen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const InputDeviceHint(),
          const SizedBox(height: 8),
          const Text(
            'Die Aufnahme läuft frei. Jedes Ereignis, das deutlich über den '
            'Rauschboden steigt, wird mit Vor- und Nachlauf als Clip '
            'gespeichert, ob Auto oder nicht. Die übrige Aufnahme wird '
            'nicht gespeichert.',
          ),
          const SizedBox(height: 16),
          Text(
            'Dauer ${formatDuration(state.elapsedS)} · '
            '${state.clipCount} Clips',
            key: const Key('collect-status'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (state.lastClipAboveFloorDb case final db?)
            Text('Letzter Clip: ${db.toStringAsFixed(1)} dB über Rauschboden'),
          const SizedBox(height: 8),
          CompactLevel(label: 'Links', level: state.left, clipSeen: false),
          CompactLevel(label: 'Rechts', level: state.right, clipSeen: false),
          if (state.error != null)
            Text(
              state.error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('collect-start-stop'),
            onPressed: state.starting
                ? null
                : state.running
                ? controller.stop
                : controller.start,
            icon: Icon(state.running ? Icons.stop : Icons.fiber_manual_record),
            label: Text(state.running ? 'Stopp' : 'Aufnahme starten'),
          ),
          if (!state.running && id != null && state.clipCount > 0) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => ClipLabelScreen(collectionId: id),
                ),
              ),
              icon: const Icon(Icons.hearing),
              label: const Text('Clips anhören und markieren'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Plays the clips of a collection one after another; the user marks each
/// as vehicle, no vehicle or unclear.
class ClipLabelScreen extends ConsumerStatefulWidget {
  const ClipLabelScreen({
    super.key,
    required this.collectionId,
    this.initialIndex,
  });

  final int collectionId;

  /// Clip to start with; default the first one without a label.
  final int? initialIndex;

  @override
  ConsumerState<ClipLabelScreen> createState() => _ClipLabelScreenState();
}

class _ClipLabelScreenState extends ConsumerState<ClipLabelScreen> {
  CollectionStorage? _storage;
  CollectionManifest? _manifest;
  int _index = 0;
  bool _playing = false;
  String? _error;
  StreamSubscription<void>? _completions;
  late final ClipPlayer _player;

  @override
  void initState() {
    super.initState();
    _player = ref.read(clipPlayerProvider);
    _completions = _player.completions.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
    unawaited(_load());
  }

  @override
  void dispose() {
    unawaited(_completions?.cancel());
    unawaited(_player.stop().catchError((Object _) {}));
    super.dispose();
  }

  Future<void> _load() async {
    final storage = await ref.read(collectionStorageProvider.future);
    final m = await storage.read(widget.collectionId);
    if (!mounted) return;
    setState(() {
      _storage = storage;
      _manifest = m;
      _index = widget.initialIndex ?? m?.firstOpenIndex ?? 0;
    });
    if (m != null && m.clips.isNotEmpty) await _play();
  }

  Future<void> _play() async {
    final m = _manifest!;
    final path = _storage!.clipFile(m.id, m.clips[_index].file).path;
    setState(() {
      _playing = true;
      _error = null;
    });
    try {
      await _player.play(path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _playing = false;
          _error = 'Wiedergabe fehlgeschlagen: $e';
        });
      }
    }
  }

  Future<void> _stop() async {
    await _player.stop();
    if (mounted) setState(() => _playing = false);
  }

  Future<void> _go(int index) async {
    setState(() => _index = index);
    await _play();
  }

  Future<void> _label(ClipLabel label) async {
    final m = _manifest!.withLabel(_index, label);
    setState(() => _manifest = m);
    await _storage!.write(m);
    ref.invalidate(collectionsProvider);
    ref.invalidate(collectionProvider(m.id));
    ref.invalidate(seriesClipsProvider);
    if (_index < m.clips.length - 1) {
      await _go(_index + 1);
    } else {
      await _stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = _manifest;
    return Scaffold(
      appBar: AppBar(title: const Text('Clips markieren')),
      body: _storage == null
          ? const Center(child: CircularProgressIndicator())
          : m == null || m.clips.isEmpty
          ? const Center(child: Text('Keine Clips in dieser Sammlung.'))
          : _body(context, m),
    );
  }

  Widget _body(BuildContext context, CollectionManifest m) {
    final c = m.clips[_index];
    final done = m.labelledCount == m.clips.length;
    final theme = Theme.of(context);
    Widget labelButton(ClipLabel label, String text, IconData icon, Key key) {
      final selected = c.label == label;
      void onPressed() => _label(label);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: selected
              ? FilledButton.icon(
                  key: key,
                  onPressed: onPressed,
                  icon: Icon(icon),
                  label: Text(text),
                )
              : OutlinedButton.icon(
                  key: key,
                  onPressed: onPressed,
                  icon: Icon(icon),
                  label: Text(text),
                ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Clip ${_index + 1} von ${m.clips.length}',
          style: theme.textTheme.titleLarge,
        ),
        Text('${m.labelledCount} von ${m.clips.length} markiert'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: m.labelledCount / m.clips.length),
        if (done)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Alle ${m.clips.length} Clips markiert. Teilen über die Liste '
              'im Tab „Sammeln“.',
              style: const TextStyle(color: Colors.green),
            ),
          ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.file, style: theme.textTheme.titleMedium),
                Text(
                  'Maximum bei ${formatDuration(c.peakTimeS)} · '
                  '${c.levelAboveFloorDb.toStringAsFixed(1)} dB über '
                  'Rauschboden · laut für '
                  '${c.eventDurationS.toStringAsFixed(1)} s · '
                  'Clip ${c.durationS.toStringAsFixed(1)} s'
                  '${c.overlap ? ' · zweites Ereignis im Clip' : ''}',
                ),
                Text('Markierung: ${clipLabelText(c.label)}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: IconButton.filledTonal(
            key: const Key('clip-play'),
            iconSize: 40,
            tooltip: _playing ? 'Stopp' : 'Abspielen',
            onPressed: _playing ? _stop : _play,
            icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
          ),
        ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: 16),
        Row(
          children: [
            labelButton(
              ClipLabel.vehicle,
              'Auto',
              Icons.directions_car,
              const Key('label-vehicle'),
            ),
            labelButton(
              ClipLabel.noVehicle,
              'Kein Auto',
              Icons.block,
              const Key('label-no-vehicle'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            labelButton(
              ClipLabel.unclear,
              'Unklar',
              Icons.help_outline,
              const Key('label-unclear'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              key: const Key('clip-previous'),
              onPressed: _index > 0 ? () => _go(_index - 1) : null,
              icon: const Icon(Icons.chevron_left),
              label: const Text('Zurück'),
            ),
            TextButton.icon(
              key: const Key('clip-next'),
              onPressed: _index < m.clips.length - 1
                  ? () => _go(_index + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
              label: const Text('Weiter'),
            ),
          ],
        ),
      ],
    );
  }
}

/// German text of [label].
String clipLabelText(ClipLabel label) => switch (label) {
  ClipLabel.open => 'offen',
  ClipLabel.vehicle => 'Auto',
  ClipLabel.noVehicle => 'kein Auto',
  ClipLabel.unclear => 'unklar',
};

/// Section of the series detail: cut the raw audio of a series into clips.
class CollectFromSeriesSection extends ConsumerStatefulWidget {
  const CollectFromSeriesSection({super.key, required this.seriesId});

  final int seriesId;

  @override
  ConsumerState<CollectFromSeriesSection> createState() =>
      _CollectFromSeriesSectionState();
}

class _CollectFromSeriesSectionState
    extends ConsumerState<CollectFromSeriesSection> {
  double? _progress;
  String? _error;

  Future<void> _run() async {
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      final id = widget.seriesId;
      final seriesStorage = await ref.read(seriesStorageProvider.future);
      final storage = await ref.read(collectionStorageProvider.future);
      final meta = await seriesStorage.readMetadata(id);
      final config = ref.read(configProvider);
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      final m = await collectFromWav(
        storage: storage,
        wav: seriesStorage.wavFile(id),
        config: config,
        base: CollectionManifest(
          id: now,
          createdAtUtcMs: now,
          source: seriesCollectionSource(id),
          deviceModel: meta?.deviceModel ?? '',
          inputDevice: meta?.inputDevice ?? 'intern',
          sampleRate: config.sampleRate,
          clips: const [],
        ),
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      ref.invalidate(collectionsProvider);
      ref.invalidate(seriesClipsProvider(id));
      if (!mounted) return;
      setState(() => _progress = null);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ClipLabelScreen(collectionId: m.id),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _progress = null;
          _error = 'Clips konnten nicht erzeugt werden: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAudio = ref.watch(_seriesHasAudioProvider(widget.seriesId));
    if (hasAudio.value != true) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            key: const Key('collect-from-series'),
            onPressed: _progress == null ? _run : null,
            icon: const Icon(Icons.content_cut),
            label: const Text('Clips zum Markieren erzeugen'),
          ),
          if (_progress case final p?) LinearProgressIndicator(value: p),
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

final _seriesHasAudioProvider = FutureProvider.family<bool, int>((
  ref,
  id,
) async {
  final storage = await ref.watch(seriesStorageProvider.future);
  return storage.wavFile(id).exists();
});

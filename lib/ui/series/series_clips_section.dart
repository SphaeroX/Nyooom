import 'dart:async';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../audio/clip_player.dart';
import '../../audio/wav.dart';
import '../../core/collect/collection_manifest.dart';
import '../../core/signal/pcm.dart';
import '../../data/collection_evaluation.dart';
import '../collect/collect_controller.dart';
import '../collect/collect_screens.dart';
import '../evaluation/pass_widgets.dart';
import '../providers.dart';
import 'series_screens.dart' show formatDuration;

/// Evaluates one clip of the collection of series [seriesId].
typedef ClipAnalyzer = Future<ClipEvaluation> Function(
  int seriesId,
  CollectionManifest collection,
  ClipEntry clip,
);

/// Runs the complete pipeline on a clip with the constants of its series
/// (calibration, learned spacing and lane distances), in a background
/// isolate.
final clipAnalyzerProvider = Provider<ClipAnalyzer>((ref) {
  return (seriesId, collection, clip) async {
    final config = ref.read(configProvider);
    final learned = await ref
        .read(repositoryProvider)
        .learnedSetup(seriesId, config);
    if (learned == null) throw StateError('Messreihe nicht gefunden.');
    final storage = await ref.read(collectionStorageProvider.future);
    final bytes = await storage
        .clipFile(collection.id, clip.file)
        .readAsBytes();
    final setup = learned.setup;
    return Isolate.run(() {
      final wav = decodeWav(bytes);
      if (wav.channels != 2) throw FormatException('${clip.file}: kein Stereo');
      return evaluateClip(
        deinterleavePcm16(wav.samples),
        clip,
        config: config,
        setup: setup,
      );
    });
  };
});

/// Section of the series detail: the clips cut from the series, to listen
/// to, label and analyse one by one. Without clips it offers to cut them
/// from the raw audio.
class SeriesClipsSection extends ConsumerStatefulWidget {
  const SeriesClipsSection({super.key, required this.seriesId});

  final int seriesId;

  @override
  ConsumerState<SeriesClipsSection> createState() => _SeriesClipsSectionState();
}

class _SeriesClipsSectionState extends ConsumerState<SeriesClipsSection> {
  late final ClipPlayer _player;
  StreamSubscription<void>? _completions;
  String? _playing;
  String? _error;

  /// Analysis per clip file: running (null value) or done.
  final Map<String, AsyncValue<ClipEvaluation>> _results = {};

  @override
  void initState() {
    super.initState();
    _player = ref.read(clipPlayerProvider);
    _completions = _player.completions.listen((_) {
      if (mounted) setState(() => _playing = null);
    });
  }

  @override
  void dispose() {
    unawaited(_completions?.cancel());
    if (_playing != null) unawaited(_player.stop().catchError((Object _) {}));
    super.dispose();
  }

  Future<void> _toggle(CollectionManifest m, ClipEntry c) async {
    if (_playing == c.file) {
      await _player.stop();
      if (mounted) setState(() => _playing = null);
      return;
    }
    final storage = await ref.read(collectionStorageProvider.future);
    setState(() {
      _playing = c.file;
      _error = null;
    });
    try {
      await _player.play(storage.clipFile(m.id, c.file).path);
    } catch (e) {
      if (mounted) {
        setState(() {
          _playing = null;
          _error = 'Wiedergabe fehlgeschlagen: $e';
        });
      }
    }
  }

  Future<void> _analyse(CollectionManifest m, ClipEntry c) async {
    setState(() => _results[c.file] = const AsyncLoading());
    final result = await AsyncValue.guard(
      () => ref.read(clipAnalyzerProvider)(widget.seriesId, m, c),
    );
    if (mounted) setState(() => _results[c.file] = result);
  }

  Future<void> _label(CollectionManifest m, int index) async {
    if (_playing != null) {
      await _player.stop();
      setState(() => _playing = null);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ClipLabelScreen(collectionId: m.id, initialIndex: index),
      ),
    );
    ref.invalidate(seriesClipsProvider(widget.seriesId));
  }

  @override
  Widget build(BuildContext context) {
    final clips = ref.watch(seriesClipsProvider(widget.seriesId));
    return clips.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('Clips: $e'),
      data: (m) => m == null || m.clips.isEmpty
          ? CollectFromSeriesSection(seriesId: widget.seriesId)
          : _list(context, m),
    );
  }

  Widget _list(BuildContext context, CollectionManifest m) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Clips der Messreihe', style: theme.textTheme.titleMedium),
        Text(
          '${m.clips.length} Clips · ${m.labelledCount} markiert. '
          'Antippen zum Markieren.',
        ),
        if (_error != null)
          Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
        for (var i = 0; i < m.clips.length; i++) ..._clipRows(context, m, i),
      ],
    );
  }

  List<Widget> _clipRows(BuildContext context, CollectionManifest m, int i) {
    final c = m.clips[i];
    final result = _results[c.file];
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: IconButton(
          key: Key('series-clip-play-$i'),
          tooltip: _playing == c.file ? 'Stopp' : 'Abspielen',
          onPressed: () => _toggle(m, c),
          icon: Icon(_playing == c.file ? Icons.stop : Icons.play_arrow),
        ),
        title: Text('${c.file} · ${clipLabelText(c.label)}'),
        subtitle: Text(
          'bei ${formatDuration(c.peakTimeS)} · '
          '${c.levelAboveFloorDb.toStringAsFixed(1)} dB über Rauschboden'
          '${c.overlap ? ' · zweites Ereignis' : ''}',
        ),
        trailing: IconButton(
          key: Key('series-clip-analyze-$i'),
          tooltip: 'Clip auswerten',
          onPressed: result?.isLoading == true ? null : () => _analyse(m, c),
          icon: const Icon(Icons.speed),
        ),
        onTap: () => _label(m, i),
      ),
      if (result != null)
        Padding(
          padding: const EdgeInsets.only(left: 48, bottom: 8),
          child: result.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text(
              'Auswertung fehlgeschlagen: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            data: (eval) => eval.records.isEmpty
                ? const Text('Kein Fahrzeug erkannt')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final r in eval.records)
                        PassTile(record: r, showTime: false),
                    ],
                  ),
          ),
        ),
    ];
  }
}

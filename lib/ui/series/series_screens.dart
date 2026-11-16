import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/model/acoustics.dart';
import '../../core/signal/level.dart';
import '../../data/repository.dart';
import '../providers.dart';
import '../sites/site_form.dart';
import '../sites/site_screens.dart';
import '../evaluation/live_panel.dart';
import 'series_detail_screen.dart';
import 'series_recording_controller.dart';

String formatDuration(double? seconds) {
  if (seconds == null) return 'läuft';
  final s = seconds.round();
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '$m:${two(sec)}';
}

String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} kB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

String formatDate(int utcMs) {
  final t = DateTime.fromMillisecondsSinceEpoch(utcMs).toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.day)}.${two(t.month)}.${t.year} ${two(t.hour)}:${two(t.minute)}';
}

/// Opens the detail screen of a series; replaced by later tasks.
typedef SeriesOpener = void Function(BuildContext context, StoredSeries s);

final seriesOpenerProvider = Provider<SeriesOpener?>(
  (ref) =>
      (context, s) => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SeriesDetailScreen(seriesId: s.id),
        ),
      ),
);

/// List of measurement series with duration and size.
class SeriesListScreen extends ConsumerWidget {
  const SeriesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(seriesListProvider);
    final opener = ref.watch(seriesOpenerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Messreihen')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SeriesStartScreen()),
        ),
        icon: const Icon(Icons.fiber_manual_record),
        label: const Text('Neue Messreihe'),
      ),
      body: list.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (series) => series.isEmpty
            ? const Center(child: Text('Noch keine Messreihe.'))
            : ListView(
                children: [
                  for (final s in series)
                    ListTile(
                      leading: Icon(
                        s.row.simulated ? Icons.science_outlined : Icons.mic,
                      ),
                      title: Text(
                        '${s.siteName} · ${formatDate(s.startedAtUtcMs)}',
                      ),
                      subtitle: Consumer(
                        builder: (context, ref, _) {
                          final size = ref.watch(seriesSizeProvider(s.id));
                          return Text(
                            '${formatDuration(s.durationS)} · '
                            '${size.whenOrNull(data: formatBytes) ?? '…'}'
                            '${s.row.simulated ? ' · Simulation' : ''}',
                          );
                        },
                      ),
                      onTap: opener == null ? null : () => opener(context, s),
                      trailing: IconButton(
                        tooltip: 'Messreihe löschen',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final ok = await confirmDelete(
                            context,
                            'Messreihe vom ${formatDate(s.startedAtUtcMs)} '
                            'mit Aufnahme und Ergebnissen löschen?',
                          );
                          if (!ok) return;
                          await ref.read(repositoryProvider).deleteSeries(s.id);
                          final storage = await ref.read(
                            seriesStorageProvider.future,
                          );
                          await storage.delete(s.id);
                          ref.invalidate(seriesListProvider);
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Choose site and temperature, show c and slant distances, start.
class SeriesStartScreen extends ConsumerStatefulWidget {
  const SeriesStartScreen({super.key});

  @override
  ConsumerState<SeriesStartScreen> createState() => _SeriesStartScreenState();
}

class _SeriesStartScreenState extends ConsumerState<SeriesStartScreen> {
  int? _siteId;
  final _temperature = TextEditingController(text: '15');
  bool? _simulate;
  bool _saveRaw = true;

  @override
  void dispose() {
    _temperature.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sites = ref.watch(sitesProvider).value ?? const [];
    final config = ref.watch(configProvider);
    final bool simulate = _simulate ?? ref.watch(simulationDefaultProvider);
    final temperature = parseDecimal(_temperature.text);
    StoredSite? site;
    for (final s in sites) {
      if (s.id == _siteId) site = s;
    }
    site ??= sites.isEmpty ? null : sites.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Messreihe starten')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (sites.isEmpty)
            const Text('Bitte zuerst unter „Standorte“ einen Standort anlegen.')
          else
            DropdownButtonFormField<int>(
              initialValue: site!.id,
              decoration: const InputDecoration(labelText: 'Standort'),
              items: [
                for (final s in sites)
                  DropdownMenuItem(value: s.id, child: Text(s.spec.name)),
              ],
              onChanged: (id) => setState(() => _siteId = id),
            ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('temperature'),
            controller: _temperature,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: const InputDecoration(
              labelText: 'Lufttemperatur (°C)',
              helperText: 'auf etwa 2 K genau (technik.pdf 7.3)',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          if (temperature != null)
            Text(
              'Schallgeschwindigkeit c = '
              '${speedOfSound(temperature).toStringAsFixed(1)} m/s',
            ),
          if (site != null)
            for (final lane in site.spec.lanes)
              Text(
                'Spur ${lane.direction > 0 ? '→' : '←'}: Schrägabstand '
                '${site.spec.slantDistance(lane, sourceHeight: config.sourceHeightM).toStringAsFixed(2)} m',
              ),
          const SizedBox(height: 12),
          SwitchListTile(
            key: const Key('simulate'),
            title: const Text('Simulation statt Mikrofon'),
            subtitle: const Text(
              'Synthetischer Verkehr (Elektroautos und Verbrenner) für Tests '
              'ohne geeignetes Gerät.',
            ),
            value: simulate,
            onChanged: (v) => setState(() => _simulate = v),
          ),
          SwitchListTile(
            title: const Text('Rohaudio speichern'),
            subtitle: const Text('WAV-Datei für spätere Auswertung'),
            value: _saveRaw,
            onChanged: (v) => setState(() => _saveRaw = v),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('start-series'),
            onPressed: site == null || temperature == null
                ? null
                : () {
                    final request = SeriesStartRequest(
                      siteId: site!.id,
                      temperatureC: temperature,
                      simulate: simulate,
                      saveRawAudio: _saveRaw,
                    );
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => SeriesRecordingScreen(request: request),
                      ),
                    );
                  },
            icon: const Icon(Icons.fiber_manual_record),
            label: const Text('Aufnahme starten'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SiteEditScreen()),
            ),
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Neuer Standort'),
          ),
        ],
      ),
    );
  }
}

/// Extra content of the recording screen (live results, Task_12).
typedef RecordingExtras = Widget Function(BuildContext context);

final recordingExtrasProvider = Provider<RecordingExtras?>(
  (ref) =>
      (context) => const LiveResultsPanel(),
);

/// Running recording: elapsed time, levels, stop.
class SeriesRecordingScreen extends ConsumerStatefulWidget {
  const SeriesRecordingScreen({super.key, required this.request});

  final SeriesStartRequest request;

  @override
  ConsumerState<SeriesRecordingScreen> createState() =>
      _SeriesRecordingScreenState();
}

class _SeriesRecordingScreenState extends ConsumerState<SeriesRecordingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(seriesRecordingProvider.notifier).start(widget.request),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(seriesRecordingProvider);
    final extras = ref.watch(recordingExtrasProvider);
    final threshold = ref.watch(configProvider).clipThreshold;
    return PopScope(
      canPop: !state.running,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.request.simulate ? 'Messreihe (Simulation)' : 'Messreihe',
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.error != null)
              Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (state.starting) const LinearProgressIndicator(),
            Text(
              formatDuration(state.elapsedS),
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            if (state.info != null)
              Text(
                'Quelle: ${state.info!.audioSource.platformName}',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 12),
            CompactLevel(
              label: 'Links',
              level: state.left,
              clipSeen: state.leftClipSeen,
            ),
            CompactLevel(
              label: 'Rechts',
              level: state.right,
              clipSeen: state.rightClipSeen,
            ),
            if (state.leftClipSeen || state.rightClipSeen)
              Text(
                'Übersteuerung (> ${(threshold * 100).round()} % '
                'Vollaussteuerung)',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            if (state.running)
              FilledButton.icon(
                key: const Key('stop-series'),
                onPressed: () =>
                    ref.read(seriesRecordingProvider.notifier).stop(),
                icon: const Icon(Icons.stop),
                label: const Text('Aufnahme beenden'),
              )
            else if (!state.starting)
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fertig'),
              ),
            if (extras != null) extras(context),
          ],
        ),
      ),
    );
  }
}

/// One-line level bar with RMS value.
class CompactLevel extends StatelessWidget {
  const CompactLevel({
    super.key,
    required this.label,
    required this.level,
    required this.clipSeen,
  });

  final String label;
  final ChannelLevel level;
  final bool clipSeen;

  @override
  Widget build(BuildContext context) {
    const rangeDb = 60.0;
    final fraction = ((level.rmsDbfs + rangeDb) / rangeDb).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 56, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: fraction,
              color: clipSeen ? Theme.of(context).colorScheme.error : null,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              '${level.rmsDbfs.toStringAsFixed(1)} dBFS',
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

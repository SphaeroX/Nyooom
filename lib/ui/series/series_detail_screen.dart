import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/site/site.dart' show laneDirectionLabel;
import '../../data/repository.dart';
import '../evaluation/pass_widgets.dart';
import '../inspection/inspection_screen.dart';
import '../providers.dart';
import 'series_clips_section.dart';
import 'series_recording_controller.dart';
import 'series_screens.dart';

/// Builds an additional section of the series detail screen.
typedef SeriesSection = Widget Function(BuildContext context, StoredSeries s);

/// Sections added by later tasks (evaluation, statistics, export, …).
final seriesSectionsProvider = Provider<List<SeriesSection>>(
  (ref) => [
    (context, s) => EvaluationSection(series: s),
    (context, s) => SeriesClipsSection(seriesId: s.id),
  ],
);

/// Detail of one measurement series.
class SeriesDetailScreen extends ConsumerWidget {
  const SeriesDetailScreen({super.key, required this.seriesId});

  final int seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(seriesProvider(seriesId));
    final sections = ref.watch(seriesSectionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Messreihe')),
      body: series.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (s) => s == null
            ? const Center(child: Text('Messreihe nicht gefunden.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    s.siteName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${formatDate(s.startedAtUtcMs)} · '
                    'Dauer ${formatDuration(s.durationS)} · '
                    '${s.temperatureC.toStringAsFixed(1)} °C, '
                    'c = ${s.speedOfSound.toStringAsFixed(1)} m/s'
                    '${s.row.simulated ? ' · Simulation' : ''}',
                  ),
                  for (var i = 0; i < s.site.spec.lanes.length; i++)
                    Text(
                      'Spur ${laneDirectionLabel(s.site.spec.lanes[i].direction)}: '
                      'd = ${s.slantDistances[i].toStringAsFixed(2)} m',
                    ),
                  if (s.segments.length > 1)
                    Text(
                      '${s.segments.length} Aufnahmeabschnitte '
                      '(fortgesetzt)',
                    ),
                  const SizedBox(height: 12),
                  if (s.endedAtUtcMs != null &&
                      !ref.watch(seriesRecordingProvider).running)
                    FilledButton.tonalIcon(
                      key: const Key('detail-resume-series'),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SeriesRecordingScreen.resume(
                              seriesId: s.id,
                              simulated: s.row.simulated,
                            ),
                          ),
                        );
                        ref.invalidate(seriesProvider(s.id));
                      },
                      icon: const Icon(Icons.fiber_manual_record),
                      label: const Text('Weiter aufnehmen'),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => InspectionScreen(seriesId: s.id),
                      ),
                    ),
                    icon: const Icon(Icons.insights),
                    label: const Text(
                      'Sichtprüfung (Korrelogramm, Spektrogramm)',
                    ),
                  ),
                  for (final section in sections) section(context, s),
                ],
              ),
      ),
    );
  }
}

final seriesProvider = FutureProvider.family<StoredSeries?, int>(
  (ref, id) => ref.watch(repositoryProvider).series(id),
);

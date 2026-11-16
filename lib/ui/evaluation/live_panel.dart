import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../audio/simulated_stereo_recorder.dart';
import '../../core/model/acoustics.dart';
import '../../core/sim/passby_simulator.dart';
import '../series/series_recording_controller.dart';
import 'pass_widgets.dart';

/// Live results under the running recording (Task_12): counters A/B/C,
/// queue state, latest vehicles; in simulation also the true values.
class LiveResultsPanel extends ConsumerWidget {
  const LiveResultsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(seriesRecordingProvider);
    final recorder = ref.read(seriesRecordingProvider.notifier).recorder;
    final records = state.liveRecords.reversed.take(30).toList();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Live-Auswertung', style: theme.textTheme.titleMedium),
        Text(
          'Ergebnis ca. 4 s nach der Vorbeifahrt · Warteschlange '
          '${state.livePending} · verloren ${state.liveDropped}',
        ),
        if (state.liveRecords.isNotEmpty) ClassCounts(state.liveRecords),
        for (final r in records) PassTile(record: r),
        if (recorder is SimulatedStereoRecorder) ...[
          const SizedBox(height: 12),
          Text('Simulation: wahre Werte', style: theme.textTheme.titleSmall),
          for (final t in recorder.pastTruths.reversed.take(8))
            ListTile(
              dense: true,
              leading: Icon(
                t.kind == VehicleKind.electric
                    ? Icons.electric_car
                    : Icons.directions_car,
              ),
              title: Text(
                '${arrow(t.direction)}  '
                '${toKmh(t.speed.abs()).toStringAsFixed(1)} km/h'
                '${t.acceleration != 0 ? ' (beschleunigt)' : ''}',
              ),
              subtitle: Text(
                '${t.kind == VehicleKind.electric ? 'Elektro' : 'Verbrenner'}'
                '${t.toneFrequencies.isEmpty ? ', ohne Ton' : ', mit Ton'}'
                ' · d = ${t.distance.toStringAsFixed(1)} m'
                ' · t0 = ${t.t0.toStringAsFixed(1)} s',
              ),
            ),
        ],
      ],
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/calibration/self_calibration.dart';
import '../../data/repository.dart';
import '../providers.dart';
import 'evaluation_controller.dart';
import 'pass_widgets.dart' show arrow;

final laneLearningProvider = FutureProvider.family<List<LaneLearning>, int>((
  ref,
  seriesId,
) async {
  final learned = await ref
      .watch(repositoryProvider)
      .learnedSetup(seriesId, ref.watch(configProvider));
  return learned?.learning ?? const [];
});

/// Measured vs learned lane distance (technik.pdf 7.4) for the site of a
/// series, with recomputation of the stored records.
class SelfCalibrationCard extends ConsumerWidget {
  const SelfCalibrationCard({super.key, required this.series});

  final StoredSeries series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learning = ref.watch(laneLearningProvider(series.id));
    final minCount = ref.watch(configProvider).selfCalibrationMinCount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: learning.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Fehler: $e'),
          data: (lanes) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selbstkalibrierung der Spurabstände',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final l in lanes) _LaneRow(l, series, minCount),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: lanes.any((l) => l.active)
                    ? () async {
                        final n = await ref
                            .read(repositoryProvider)
                            .recomputeSiteWithLearning(
                              series.site.id,
                              ref.read(configProvider),
                            );
                        ref.invalidate(passesProvider);
                        ref.invalidate(laneLearningProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$n Datensätze neu berechnet.'),
                            ),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.refresh),
                label: const Text('Mit gelerntem Abstand neu berechnen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LaneRow extends StatelessWidget {
  const _LaneRow(this.l, this.series, this.minCount);
  final LaneLearning l;
  final StoredSeries series;
  final int minCount;

  @override
  Widget build(BuildContext context) {
    final direction = series.site.spec.lanes[l.lane].direction;
    final learned = l.learnedDistance == null
        ? '–'
        : '${l.learnedDistance!.toStringAsFixed(2)} m';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spur ${arrow(direction)}: Maßband '
            '${l.measuredDistance.toStringAsFixed(2)} m · gelernt $learned '
            '(${l.countA} × Klasse A${l.active ? ', aktiv' : ', ab $minCount aktiv'})',
          ),
          if (l.warning)
            Text(
              'Abweichung ${(l.deviation! * 100).toStringAsFixed(0)} %: '
              'Spurzuordnung, Mikrofonabstand b oder Ausrichtung der '
              'Mikrofonachse prüfen.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

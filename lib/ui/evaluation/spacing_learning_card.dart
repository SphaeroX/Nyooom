import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/calibration/plateau_calibration.dart';
import '../../core/config/nyooom_config.dart';
import '../providers.dart';

/// Calibrated and learned microphone spacing of a series.
class SpacingInfo {
  const SpacingInfo({required this.calibratedSpacing, required this.learned});

  /// b from the calibration (or the default) in m.
  final double calibratedSpacing;

  /// b and Δ0 learned from the passes, null if the calibration is in use.
  final LearnedSpacing? learned;
}

final spacingInfoProvider = FutureProvider.family<SpacingInfo, int>((
  ref,
  seriesId,
) async {
  final repo = ref.watch(repositoryProvider);
  final calibrated = await repo.analysisSetup(seriesId, learnedSpacing: false);
  return SpacingInfo(
    calibratedSpacing: calibrated!.micSpacing,
    learned: await repo.learnedSpacing(seriesId),
  );
});

String _cm(double metres) => '${(metres * 100).toStringAsFixed(1)} cm';

/// What to tell the user after an evaluation that did not take over the
/// spacing learned from the passes; null if it was taken over.
String? spacingNote(SpacingLearning learning, NyooomConfig config) {
  if (learning.active) return null;
  if (learning.warning) {
    return 'Mikrofonabstand aus den Vorbeifahrten '
        '(${_cm(learning.estimate!.micSpacing)}) weicht '
        '${(learning.deviation!.abs() * 100).round()} % von der '
        'Kalibrierung ab und wurde nicht übernommen. Ausrichtung der '
        'Mikrofone (parallel zur Straße) und Kalibrierung prüfen.';
  }
  return 'Mikrofonabstand nicht gelernt: ${learning.passCount} von '
      'mindestens ${config.plateauMinCount} Vorbeifahrten mit vollständiger '
      'Kurve. Es gilt die Kalibrierung.';
}

/// Shows whether the series is evaluated with the calibrated microphone
/// spacing or with the one learned from its passes.
class SpacingLearningCard extends ConsumerWidget {
  const SpacingLearningCard({super.key, required this.seriesId});

  final int seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(spacingInfoProvider(seriesId));
    final minCount = ref.watch(configProvider).plateauMinCount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: info.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Fehler: $e'),
          data: (info) {
            final learned = info.learned;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mikrofonabstand aus den Vorbeifahrten',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                if (learned != null)
                  Text(
                    'Gelernt: ${_cm(learned.micSpacing)}, Kanalversatz '
                    '${(learned.channelOffset * 1e6).round()} µs '
                    '(${learned.passCount} Vorbeifahrten). Kalibrierung: '
                    '${_cm(info.calibratedSpacing)}. Die Auswertung rechnet '
                    'mit dem gelernten Wert.',
                  )
                else
                  Text(
                    'Noch nicht gelernt, es gilt die Kalibrierung '
                    '(${_cm(info.calibratedSpacing)}). „Messreihe '
                    'auswerten“ liest Abstand und Kanalversatz aus den '
                    'Vorbeifahrten, sobald mindestens $minCount eine '
                    'vollständige Kurve zeigen.',
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

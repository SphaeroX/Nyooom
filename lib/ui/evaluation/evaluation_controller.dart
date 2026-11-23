import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pipeline/pass_record.dart';
import '../../data/series_analysis.dart';
import '../providers.dart';
import 'spacing_learning_card.dart';

/// Pass records of a series.
final passesProvider = FutureProvider.family<List<PassRecord>, int>(
  (ref, seriesId) => ref.watch(repositoryProvider).passes(seriesId),
);

class EvaluationState {
  const EvaluationState({
    this.running = false,
    this.fraction = 0,
    this.phase = '',
    this.error,
    this.note,
  });

  final bool running;
  final double fraction;
  final String phase;
  final String? error;

  /// Hint after a finished run (spacing not learned or not taken over).
  final String? note;
}

final evaluationProvider =
    NotifierProvider.family<EvaluationController, EvaluationState, int>(
      EvaluationController.new,
    );

/// Runs the offline evaluation of a stored series in the background and
/// stores the records. The run learns the effective microphone spacing and
/// the channel offset from the passes, starting from the calibration, and
/// stores them with the series if there are enough passes.
class EvaluationController extends Notifier<EvaluationState> {
  EvaluationController(this.seriesId);

  final int seriesId;

  @override
  EvaluationState build() => const EvaluationState();

  Future<void> run() async {
    if (state.running) return;
    state = const EvaluationState(running: true, phase: 'Start');
    try {
      final repo = ref.read(repositoryProvider);
      final config = ref.read(configProvider);
      final setup = (await repo.learnedSetup(
        seriesId,
        config,
        learnedSpacing: false,
      ))?.setup;
      final storage = await ref.read(seriesStorageProvider.future);
      final wav = storage.wavFile(seriesId);
      if (setup == null || !await wav.exists()) {
        state = const EvaluationState(
          error: 'Keine Rohaufnahme vorhanden; Auswertung nicht möglich.',
        );
        return;
      }
      final stream = analyseSeriesInBackground(
        wavPath: wav.path,
        setup: setup,
        config: config,
        learnSpacing: true,
      );
      await for (final p in stream) {
        if (!ref.mounted) return;
        if (p.error != null) {
          state = EvaluationState(
            error: 'Auswertung fehlgeschlagen: ${p.error}',
          );
          return;
        }
        final result = p.result;
        if (result != null) {
          final learning = p.learning;
          await repo.setLearnedSpacing(seriesId, learning?.learned);
          await repo.replacePasses(seriesId, result);
          if (!ref.mounted) return;
          ref.invalidate(passesProvider(seriesId));
          ref.invalidate(spacingInfoProvider(seriesId));
          state = EvaluationState(
            fraction: 1,
            phase: 'fertig',
            note: learning == null ? null : spacingNote(learning, config),
          );
          return;
        }
        state = EvaluationState(
          running: true,
          fraction: p.fraction,
          phase: p.phase,
        );
      }
    } catch (e) {
      if (ref.mounted) {
        state = EvaluationState(error: 'Auswertung fehlgeschlagen: $e');
      }
    }
  }
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/pipeline/pass_record.dart';
import '../../data/series_analysis.dart';
import '../providers.dart';

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
  });

  final bool running;
  final double fraction;
  final String phase;
  final String? error;
}

final evaluationProvider =
    NotifierProvider.family<EvaluationController, EvaluationState, int>(
      EvaluationController.new,
    );

/// Runs the offline evaluation of a stored series in the background and
/// stores the records.
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
      final setup = (await repo.learnedSetup(
        seriesId,
        ref.read(configProvider),
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
        config: ref.read(configProvider),
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
          await repo.replacePasses(seriesId, result);
          if (!ref.mounted) return;
          ref.invalidate(passesProvider(seriesId));
          state = const EvaluationState(fraction: 1, phase: 'fertig');
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

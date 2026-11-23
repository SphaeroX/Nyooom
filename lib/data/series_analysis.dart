import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import '../audio/wav.dart';
import '../core/calibration/plateau_calibration.dart';
import '../core/config/nyooom_config.dart';
import '../core/events/event_detector.dart';
import '../core/pipeline/analysis_setup.dart';
import '../core/pipeline/event_evaluator.dart';
import '../core/pipeline/pass_record.dart';
import '../core/pipeline/track_dedup.dart';
import '../core/signal/pcm.dart';
import 'event_pipeline.dart';

/// Progress message of a running analysis.
class AnalysisProgress {
  const AnalysisProgress(
    this.fraction,
    this.phase, {
    this.result,
    this.error,
    this.learning,
  });

  /// 0..1 over detection (first half) and evaluation (second half).
  final double fraction;
  final String phase;
  final List<PassRecord>? result;
  final String? error;

  /// With the result of an analysis that learned b and Δ0 from the passes:
  /// what was found and whether it was used.
  final SpacingLearning? learning;
}

/// Streams a stored WAV through the event detector in 1-s chunks (never
/// the whole file in memory).
Future<List<PassEvent>> detectSeriesEvents({
  required String wavPath,
  required NyooomConfig config,
  void Function(AnalysisProgress)? onProgress,
}) async {
  final file = File(wavPath);
  final info = await readWavInfo(file);
  final detector = EventDetector(config: config, secondaryEvents: true);
  final events = <PassEvent>[];
  const chunkS = 1.0;
  for (var start = 0.0; start < info.durationS; start += chunkS) {
    final block = await readWavStereoRange(
      file,
      startS: start,
      durationS: math.min(chunkS, info.durationS - start),
    );
    events.addAll(detector.add(block));
    onProgress?.call(
      AnalysisProgress(0.5 * start / info.durationS, 'Ereignisse suchen'),
    );
  }
  events.addAll(detector.finish());
  return events;
}

/// Window of [event] read from the file, with its start time in s.
Future<({StereoBlock window, double startS})> _readWindow(
  File file,
  int sampleRate,
  PassEvent event,
) async {
  final from = (event.windowStartS * sampleRate).round() / sampleRate;
  return (
    window: await readWavStereoRange(
      file,
      startS: from,
      durationS: event.windowEndS - from,
    ),
    startS: from,
  );
}

/// Learns the effective microphone spacing and the channel offset from
/// the plateaus of the passes of a stored WAV (see [estimatePlateaus]).
///
/// Only the TDOA track of each event is fitted, without Doppler. The first
/// round uses b and Δ0 of [setup]; if the passes say something else, a
/// second round with the learned values removes the error the first fit
/// carried over (it was made with the wrong b).
Future<SpacingLearning> learnSeriesSpacing({
  required String wavPath,
  required AnalysisSetup setup,
  required NyooomConfig config,
  List<PassEvent>? events,
  void Function(AnalysisProgress)? onProgress,
}) async {
  final file = File(wavPath);
  final info = await readWavInfo(file);
  final found =
      events ??
      await detectSeriesEvents(
        wavPath: wavPath,
        config: config,
        onProgress: onProgress,
      );
  const rounds = 2;
  var current = setup;
  late SpacingLearning learning;
  for (var round = 0; round < rounds; round++) {
    final evaluator = EventEvaluator(config: config, setup: current);
    final dedup = TrackDeduplicator(config: config);
    final estimates = <PlateauEstimate>[];
    for (var i = 0; i < found.length; i++) {
      final w = await _readWindow(file, info.sampleRate, found[i]);
      for (final track in evaluator.analyseTracks(
        w.window,
        found[i],
        windowStartS: w.startS,
      )) {
        // The same vehicle seen from two windows counts once.
        if (!dedup.accept(track.record)) continue;
        final estimate = estimateTrackPlateaus(
          track,
          setup: current,
          config: config,
        );
        if (estimate != null) estimates.add(estimate);
      }
      onProgress?.call(
        AnalysisProgress(
          0.5,
          'Mikrofonabstand lernen (${round + 1}/$rounds): '
          '${i + 1} von ${found.length}',
        ),
      );
    }
    learning = judgeSpacing(
      estimates,
      micSpacing: setup.micSpacing,
      channelOffset: setup.channelOffset,
      config: config,
    );
    if (!learning.active) break;
    current = learning.applyTo(setup);
  }
  return learning;
}

/// Evaluates a stored WAV: detects the events ([detectSeriesEvents], or
/// the given [events]), then evaluates each event window read from the
/// file.
Future<List<PassRecord>> runSeriesAnalysis({
  required String wavPath,
  required AnalysisSetup setup,
  required NyooomConfig config,
  List<PassEvent>? events,
  void Function(AnalysisProgress)? onProgress,
}) async {
  final file = File(wavPath);
  final info = await readWavInfo(file);
  final found =
      events ??
      await detectSeriesEvents(
        wavPath: wavPath,
        config: config,
        onProgress: onProgress,
      );

  final pipeline = EventPipeline(config: config, setup: setup);
  final dedup = TrackDeduplicator(config: config);
  final records = <PassRecord>[];
  for (var i = 0; i < found.length; i++) {
    final w = await _readWindow(file, info.sampleRate, found[i]);
    records.addAll(
      pipeline
          .evaluateAll(w.window, found[i], windowStartS: w.startS)
          .where(dedup.accept),
    );
    onProgress?.call(
      AnalysisProgress(
        0.5 + 0.5 * (i + 1) / found.length,
        'Vorbeifahrt ${i + 1} von ${found.length}',
      ),
    );
  }
  return records;
}

/// Runs [runSeriesAnalysis] in a background isolate and reports progress.
/// With [learnSpacing] b and Δ0 are first learned from the passes
/// ([learnSeriesSpacing]) and used if there are enough of them; the last
/// message then carries the verdict in [AnalysisProgress.learning].
Stream<AnalysisProgress> analyseSeriesInBackground({
  required String wavPath,
  required AnalysisSetup setup,
  required NyooomConfig config,
  bool learnSpacing = false,
}) {
  final controller = StreamController<AnalysisProgress>();
  final port = ReceivePort();
  port.listen((message) {
    final p = message as AnalysisProgress;
    controller.add(p);
    if (p.result != null || p.error != null) {
      port.close();
      controller.close();
    }
  });
  Isolate.spawn(_analysisEntry, (
    send: port.sendPort,
    wavPath: wavPath,
    setup: setup,
    config: config,
    learnSpacing: learnSpacing,
  ));
  return controller.stream;
}

typedef _AnalysisArgs = ({
  SendPort send,
  String wavPath,
  AnalysisSetup setup,
  NyooomConfig config,
  bool learnSpacing,
});

Future<void> _analysisEntry(_AnalysisArgs args) async {
  try {
    final events = await detectSeriesEvents(
      wavPath: args.wavPath,
      config: args.config,
      onProgress: args.send.send,
    );
    SpacingLearning? learning;
    if (args.learnSpacing) {
      learning = await learnSeriesSpacing(
        wavPath: args.wavPath,
        setup: args.setup,
        config: args.config,
        events: events,
        onProgress: args.send.send,
      );
    }
    final result = await runSeriesAnalysis(
      wavPath: args.wavPath,
      setup: learning?.applyTo(args.setup) ?? args.setup,
      config: args.config,
      events: events,
      onProgress: args.send.send,
    );
    args.send.send(
      AnalysisProgress(1, 'fertig', result: result, learning: learning),
    );
  } catch (e) {
    args.send.send(AnalysisProgress(1, 'Fehler', error: '$e'));
  }
}

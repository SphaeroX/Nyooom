import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import '../audio/wav.dart';
import '../core/config/nyooom_config.dart';
import '../core/events/event_detector.dart';
import '../core/pipeline/analysis_setup.dart';
import '../core/pipeline/pass_record.dart';
import 'event_pipeline.dart';

/// Progress message of a running analysis.
class AnalysisProgress {
  const AnalysisProgress(this.fraction, this.phase, {this.result, this.error});

  /// 0..1 over detection (first half) and evaluation (second half).
  final double fraction;
  final String phase;
  final List<PassRecord>? result;
  final String? error;
}

/// Evaluates a stored WAV: streams it through the event detector in 1-s
/// chunks (never the whole file in memory), then evaluates each event
/// window read from the file.
Future<List<PassRecord>> runSeriesAnalysis({
  required String wavPath,
  required AnalysisSetup setup,
  required NyooomConfig config,
  void Function(AnalysisProgress)? onProgress,
}) async {
  final file = File(wavPath);
  final info = await readWavInfo(file);
  final detector = EventDetector(config: config);
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

  final pipeline = EventPipeline(config: config, setup: setup);
  final records = <PassRecord>[];
  for (var i = 0; i < events.length; i++) {
    final e = events[i];
    final from = (e.windowStartS * info.sampleRate).round() / info.sampleRate;
    final window = await readWavStereoRange(
      file,
      startS: from,
      durationS: e.windowEndS - from,
    );
    records.add(pipeline.evaluate(window, e, windowStartS: from));
    onProgress?.call(
      AnalysisProgress(
        0.5 + 0.5 * (i + 1) / events.length,
        'Vorbeifahrt ${i + 1} von ${events.length}',
      ),
    );
  }
  return records;
}

/// Runs [runSeriesAnalysis] in a background isolate and reports progress.
Stream<AnalysisProgress> analyseSeriesInBackground({
  required String wavPath,
  required AnalysisSetup setup,
  required NyooomConfig config,
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
  ));
  return controller.stream;
}

typedef _AnalysisArgs = ({
  SendPort send,
  String wavPath,
  AnalysisSetup setup,
  NyooomConfig config,
});

Future<void> _analysisEntry(_AnalysisArgs args) async {
  try {
    final result = await runSeriesAnalysis(
      wavPath: args.wavPath,
      setup: args.setup,
      config: args.config,
      onProgress: args.send.send,
    );
    args.send.send(AnalysisProgress(1, 'fertig', result: result));
  } catch (e) {
    args.send.send(AnalysisProgress(1, 'Fehler', error: '$e'));
  }
}

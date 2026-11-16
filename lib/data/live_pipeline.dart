import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import '../core/config/nyooom_config.dart';
import '../core/events/event_detector.dart';
import '../core/pipeline/analysis_setup.dart';
import '../core/pipeline/pass_record.dart';
import '../core/pipeline/track_dedup.dart';
import '../core/signal/pcm.dart';
import 'event_pipeline.dart';

/// Evaluates one event window (normally in a worker isolate).
typedef LiveEvaluator = Future<PassRecord> Function(
  StereoBlock window,
  PassEvent event,
  double windowStartS,
);

/// Live evaluation (Roadmap Task_12): recording blocks → ring buffer →
/// event detection → evaluation per event in a long-lived worker isolate.
///
/// At most [maxPending] events are running or waiting; further events are
/// dropped and counted in [dropped] (backpressure).
class LivePipeline {
  LivePipeline({
    required this.config,
    required this.setup,
    LiveEvaluator? evaluator,
    this.maxPending = 4,
    double bufferS = 12,
  }) : _detector = EventDetector(config: config, secondaryEvents: true),
       _dedup = TrackDeduplicator(config: config),
       _capacity = (bufferS * config.sampleRate).round(),
       _left = Float64List((bufferS * config.sampleRate).round()),
       _right = Float64List((bufferS * config.sampleRate).round()) {
    if (evaluator != null) {
      _evaluate = (window, event, startS) async => [
        await evaluator(window, event, startS),
      ];
    } else {
      final worker = _IsolateWorker(config, setup);
      _worker = worker;
      _evaluate = worker.evaluate;
    }
  }

  final NyooomConfig config;
  final AnalysisSetup setup;
  final int maxPending;
  final EventDetector _detector;
  final TrackDeduplicator _dedup;
  late final Future<List<PassRecord>> Function(
    StereoBlock window,
    PassEvent event,
    double windowStartS,
  )
  _evaluate;
  _IsolateWorker? _worker;

  final int _capacity;
  final Float64List _left, _right;
  int _total = 0;

  final _records = StreamController<PassRecord>.broadcast();
  final Queue<_Job> _queue = Queue();
  bool _busy = false;
  int _pending = 0;
  int _dropped = 0;
  Completer<void>? _idle;

  /// Evaluated records in the order of the events.
  Stream<PassRecord> get records => _records.stream;

  /// Events running or waiting.
  int get pending => _pending;

  /// Events dropped because the queue was full.
  int get dropped => _dropped;

  /// Seconds of signal received.
  double get receivedS => _total / config.sampleRate;

  void add(StereoBlock block) {
    for (var i = 0; i < block.length; i++) {
      final p = (_total + i) % _capacity;
      _left[p] = block.left[i];
      _right[p] = block.right[i];
    }
    _total += block.length;
    for (final e in _detector.add(block)) {
      submit(e);
    }
  }

  /// Queues [event] for evaluation (normally called by [add]).
  void submit(PassEvent event) {
    final fs = config.sampleRate;
    final from = (event.windowStartS * fs).round();
    final to = math.min((event.windowEndS * fs).round(), _total);
    if (_pending >= maxPending || from < _total - _capacity || to <= from) {
      _dropped++;
      return;
    }
    final n = to - from;
    final left = Float64List(n), right = Float64List(n);
    for (var i = 0; i < n; i++) {
      final p = (from + i) % _capacity;
      left[i] = _left[p];
      right[i] = _right[p];
    }
    _pending++;
    _queue.add(_Job(StereoBlock(left, right), event, from / fs));
    _pump();
  }

  void _pump() {
    if (_busy || _queue.isEmpty) return;
    _busy = true;
    final job = _queue.removeFirst();
    _evaluate(job.window, job.event, job.windowStartS)
        .then((records) {
          for (final record in records) {
            if (_dedup.accept(record)) _records.add(record);
          }
        }, onError: _records.addError)
        .whenComplete(() {
          _busy = false;
          _pending--;
          if (_pending == 0) {
            _idle?.complete();
            _idle = null;
          }
          _pump();
        });
  }

  /// Evaluates the events at the end of the signal and waits for all jobs.
  Future<void> finish() async {
    for (final e in _detector.finish()) {
      submit(e);
    }
    if (_pending > 0) {
      _idle = Completer<void>();
      await _idle!.future;
    }
    await dispose();
  }

  Future<void> dispose() async {
    _worker?.dispose();
    _worker = null;
    if (!_records.isClosed) await _records.close();
  }
}

class _Job {
  _Job(this.window, this.event, this.windowStartS);
  final StereoBlock window;
  final PassEvent event;
  final double windowStartS;
}

/// Long-lived worker isolate running [EventPipeline].
class _IsolateWorker {
  _IsolateWorker(NyooomConfig config, AnalysisSetup setup) {
    _ready = _start(config, setup);
  }

  late final Future<SendPort> _ready;
  final _results = ReceivePort();
  final Map<int, Completer<List<PassRecord>>> _open = {};
  Isolate? _isolate;
  int _nextId = 0;

  Future<SendPort> _start(NyooomConfig config, AnalysisSetup setup) async {
    final portReady = Completer<SendPort>();
    _results.listen((message) {
      if (message is SendPort) {
        portReady.complete(message);
      } else if (message is _Result) {
        _open.remove(message.id)?.complete(message.records);
      } else if (message is _Failure) {
        _open.remove(message.id)?.completeError(message.error);
      }
    });
    _isolate = await Isolate.spawn(_workerEntry, (
      reply: _results.sendPort,
      config: config,
      setup: setup,
    ));
    return portReady.future;
  }

  Future<List<PassRecord>> evaluate(
    StereoBlock window,
    PassEvent event,
    double windowStartS,
  ) async {
    final port = await _ready;
    final id = _nextId++;
    final completer = Completer<List<PassRecord>>();
    _open[id] = completer;
    port.send(_Request(id, window, event, windowStartS));
    return completer.future;
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _results.close();
  }
}

class _Request {
  _Request(this.id, this.window, this.event, this.windowStartS);
  final int id;
  final StereoBlock window;
  final PassEvent event;
  final double windowStartS;
}

class _Result {
  _Result(this.id, this.records);
  final int id;
  final List<PassRecord> records;
}

class _Failure {
  _Failure(this.id, this.error);
  final int id;
  final String error;
}

void _workerEntry(
  ({SendPort reply, NyooomConfig config, AnalysisSetup setup}) args,
) {
  final pipeline = EventPipeline(config: args.config, setup: args.setup);
  final requests = ReceivePort();
  args.reply.send(requests.sendPort);
  requests.listen((message) {
    final r = message as _Request;
    try {
      args.reply.send(
        _Result(
          r.id,
          pipeline.evaluateAll(r.window, r.event, windowStartS: r.windowStartS),
        ),
      );
    } catch (e) {
      args.reply.send(_Failure(r.id, '$e'));
    }
  });
}

/// Offline reference of the live mode: all events of [signal] (including
/// secondary maxima) through the complete [EventPipeline] with track
/// separation; repeated reports of one vehicle are removed.
List<PassRecord> evaluateSignalFull(
  StereoBlock signal, {
  required NyooomConfig config,
  required AnalysisSetup setup,
}) {
  final pipeline = EventPipeline(config: config, setup: setup);
  final detector = EventDetector(config: config, secondaryEvents: true);
  final dedup = TrackDeduplicator(config: config);
  final fs = config.sampleRate;
  final records = <PassRecord>[];
  for (final e in [...detector.add(signal), ...detector.finish()]) {
    final from = (e.windowStartS * fs).round();
    final to = math.min((e.windowEndS * fs).round(), signal.length);
    final found = pipeline.evaluateAll(
      StereoBlock(
        Float64List.sublistView(signal.left, from, to),
        Float64List.sublistView(signal.right, from, to),
      ),
      e,
      windowStartS: from / fs,
    );
    records.addAll(found.where(dedup.accept));
  }
  return records;
}

import 'dart:math' as math;
import 'dart:typed_data';

import '../config/nyooom_config.dart';
import '../events/event_detector.dart';
import '../signal/pcm.dart';

/// Audio around one detected event, for listening and labelling.
class CollectedClip {
  const CollectedClip({
    required this.startS,
    required this.signal,
    required this.event,
  });

  /// Start of the clip, relative to the start of the stream.
  final double startS;
  final StereoBlock signal;
  final PassEvent event;

  double durationS(int sampleRate) => signal.length / sampleRate;
}

/// Cuts the evaluation window of every detected event (technik.pdf 5.1)
/// out of a running stream, keeping only a few windows of audio in memory.
///
/// Events are the dominant level maxima of [EventDetector]: everything that
/// rises [NyooomConfig.eventThresholdDb] above the noise floor, vehicle or
/// not. The user labels the clips afterwards.
class ClipCollector {
  ClipCollector({required this.config})
    : _detector = EventDetector(config: config),
      _keepFrames = (keptSeconds(config) * config.sampleRate).round();

  final NyooomConfig config;
  final EventDetector _detector;
  final int _keepFrames;

  /// Blocks still in memory; the first starts at frame [_firstFrame].
  final List<StereoBlock> _blocks = [];
  int _firstFrame = 0;
  int _frames = 0;

  /// Audio kept in memory: the event is reported one window after its
  /// maximum, its clip reaches one window before it, plus the level
  /// smoothing and one window of margin.
  static double keptSeconds(NyooomConfig config) =>
      3 * config.eventWindowS + config.eventLevelSmoothingS;

  double get keptS => keptSeconds(config);

  /// Seconds of audio currently held.
  double get bufferedS => (_frames - _firstFrame) / config.sampleRate;

  List<CollectedClip> add(StereoBlock block) {
    _blocks.add(block);
    _frames += block.length;
    final clips = [for (final e in _detector.add(block)) _cut(e)];
    _trim();
    return clips;
  }

  /// Events whose window reaches the end of the stream.
  List<CollectedClip> finish() => [for (final e in _detector.finish()) _cut(e)];

  CollectedClip _cut(PassEvent event) {
    final from = math.max(
      _firstFrame,
      (event.windowStartS * config.sampleRate).round(),
    );
    final to = math.min(
      _frames,
      (event.windowEndS * config.sampleRate).round(),
    );
    final n = math.max(0, to - from);
    final left = Float64List(n);
    final right = Float64List(n);
    var blockStart = _firstFrame;
    for (final b in _blocks) {
      final blockEnd = blockStart + b.length;
      final a = math.max(from, blockStart);
      final z = math.min(to, blockEnd);
      for (var f = a; f < z; f++) {
        left[f - from] = b.left[f - blockStart];
        right[f - from] = b.right[f - blockStart];
      }
      blockStart = blockEnd;
    }
    return CollectedClip(
      startS: from / config.sampleRate,
      signal: StereoBlock(left, right),
      event: event,
    );
  }

  void _trim() {
    while (_blocks.isNotEmpty &&
        _frames - (_firstFrame + _blocks.first.length) >= _keepFrames) {
      _firstFrame += _blocks.removeAt(0).length;
    }
  }
}

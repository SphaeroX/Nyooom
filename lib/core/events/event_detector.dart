import 'dart:math' as math;

import '../config/nyooom_config.dart';
import '../dsp/biquad.dart';
import '../signal/pcm.dart';

/// A detected vehicle pass (technik.pdf 5.1).
class PassEvent {
  const PassEvent({
    required this.peakTimeS,
    required this.peakLevelDb,
    required this.floorDb,
    required this.durationS,
    required this.windowStartS,
    required this.windowEndS,
    required this.overlap,
    required this.truncated,
  });

  /// Time of the level maximum, relative to the start of the stream.
  final double peakTimeS;
  final double peakLevelDb;
  final double floorDb;

  /// Time the level stays above the configured fraction of the excess
  /// (field `dauer`, 9.1).
  final double durationS;

  /// Evaluation window (clipped to the recorded signal).
  final double windowStartS;
  final double windowEndS;

  /// A second vehicle of similar level lies in the window (class C).
  final bool overlap;

  /// The window had to be clipped at the start or end of the recording.
  final bool truncated;

  /// Level maximum above the noise floor (field `pegel`, 9.1).
  double get levelAboveFloorDb => peakLevelDb - floorDb;
}

/// Block-wise event detection (technik.pdf 5.1): high-pass, short-term level
/// in the event band every [NyooomConfig.eventLevelStepS], smoothed over
/// [NyooomConfig.eventLevelSmoothingS], noise floor as running percentile,
/// maxima at least [NyooomConfig.eventThresholdDb] above the floor.
///
/// An event is reported once the signal up to the end of its window is
/// known, i.e. [NyooomConfig.eventWindowS] after the maximum. At the start
/// of a recording the floor is taken from the history available so far.
class EventDetector {
  EventDetector({required this.config})
    : _filter = BiquadChain([
        Biquad.highPass(config.sampleRate.toDouble(), config.highPassHz),
        Biquad.highPass(config.sampleRate.toDouble(), config.eventBandLowHz),
        Biquad.lowPass(config.sampleRate.toDouble(), config.eventBandHighHz),
      ]),
      _stepSamples = (config.eventLevelStepS * config.sampleRate).round(),
      _smoothSteps = math.max(
        1,
        (config.eventLevelSmoothingS / config.eventLevelStepS).round(),
      ),
      _windowSteps = (config.eventWindowS / config.eventLevelStepS).round(),
      _historySteps = (config.noiseFloorHistoryS / config.eventLevelStepS)
          .round();

  final NyooomConfig config;
  final BiquadChain _filter;
  final int _stepSamples;
  final int _smoothSteps;
  final int _windowSteps;
  final int _historySteps;

  double _acc = 0;
  int _accCount = 0;
  int _samples = 0;
  final List<double> _raw = [];

  /// Smoothed level and floor per step; index i is step [_base] + i.
  final List<double> _level = [];
  final List<double> _floor = [];
  int _base = 0;
  int _steps = 0;
  final List<double> _sorted = [];

  double get _stepS => config.eventLevelStepS;

  /// Seconds of signal consumed so far.
  double get consumedS => _samples / config.sampleRate;

  List<PassEvent> add(StereoBlock block) {
    final events = <PassEvent>[];
    for (var i = 0; i < block.length; i++) {
      final s = _filter.process(0.5 * (block.left[i] + block.right[i]));
      _acc += s * s;
      _accCount++;
      _samples++;
      if (_accCount == _stepSamples) {
        final e = _addStep(_acc / _accCount);
        if (e != null) events.add(e);
        _acc = 0;
        _accCount = 0;
      }
    }
    return events;
  }

  /// Evaluates the maxima whose window reaches past the end of the signal.
  List<PassEvent> finish() {
    final events = <PassEvent>[];
    final last = _steps - 1;
    for (var c = math.max(0, _steps - _windowSteps); c <= last; c++) {
      final e = _evaluate(c, last, atEnd: true);
      if (e != null) events.add(e);
    }
    return events;
  }

  PassEvent? _addStep(double meanSquare) {
    _raw.add(meanSquare);
    if (_raw.length > _smoothSteps) _raw.removeAt(0);
    final smoothed = _raw.reduce((a, b) => a + b) / _raw.length;
    final db = 10 * math.log(smoothed + 1e-20) / math.ln10;
    _level.add(db);
    _insertSorted(db);
    final k = _steps++;
    if (k - _historySteps >= _base) {
      _removeSorted(_at(_level, k - _historySteps));
    }
    final rank = (config.noiseFloorPercentile / 100 * (_sorted.length - 1))
        .floor();
    _floor.add(_sorted[rank]);
    _trim();
    final c = k - _windowSteps;
    return c >= 0 ? _evaluate(c, k, atEnd: false) : null;
  }

  double _at(List<double> list, int step) => list[step - _base];

  /// Time of step [i]: centre of its smoothing window.
  double _timeOf(int i) => (i + 1) * _stepS - _smoothSteps * _stepS / 2;

  PassEvent? _evaluate(int c, int last, {required bool atEnd}) {
    final peak = _at(_level, c);
    final from = math.max(0, c - _windowSteps);
    final to = math.min(last, c + _windowSteps);
    for (var j = from; j <= to; j++) {
      if (j < c && _at(_level, j) >= peak) return null;
      if (j > c && _at(_level, j) > peak) return null;
    }
    final floor = _at(_floor, last);
    if (peak - floor < config.eventThresholdDb) return null;

    var overlap = false;
    for (var j = from + 1; j < to && !overlap; j++) {
      if (j == c) continue;
      final v = _at(_level, j);
      final isMax = v >= _at(_level, j - 1) && v >= _at(_level, j + 1);
      if (!isMax || v < peak - config.overlapThresholdDb) continue;
      var dip = double.infinity;
      for (var m = math.min(j, c); m <= math.max(j, c); m++) {
        dip = math.min(dip, _at(_level, m));
      }
      if (dip <= v - config.overlapMinDipDb) overlap = true;
    }

    final half = floor + config.eventDurationFraction * (peak - floor);
    var l = c, r = c;
    while (l > from && _at(_level, l - 1) > half) {
      l--;
    }
    while (r < to && _at(_level, r + 1) > half) {
      r++;
    }

    final t = _timeOf(c);
    final start = t - config.eventWindowS;
    final end = t + config.eventWindowS;
    final recorded = consumedS;
    return PassEvent(
      peakTimeS: t,
      peakLevelDb: peak,
      floorDb: floor,
      durationS: (r - l + 1) * _stepS,
      windowStartS: math.max(0, start),
      windowEndS: math.min(end, recorded),
      overlap: overlap,
      truncated: start < 0 || (atEnd && end > recorded),
    );
  }

  void _insertSorted(double v) {
    var lo = 0, hi = _sorted.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_sorted[mid] < v) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    _sorted.insert(lo, v);
  }

  void _removeSorted(double v) {
    var lo = 0, hi = _sorted.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_sorted[mid] < v) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    if (lo < _sorted.length) _sorted.removeAt(lo);
  }

  /// Keeps the floor history plus two windows of levels.
  void _trim() {
    final keep = _historySteps + 2 * _windowSteps + 2;
    final excess = _level.length - keep;
    if (excess > keep) {
      _level.removeRange(0, excess);
      _floor.removeRange(0, excess);
      _base += excess;
    }
  }
}

/// Convenience: all events of a complete signal.
List<PassEvent> detectEvents(
  StereoBlock signal, {
  required NyooomConfig config,
}) {
  final detector = EventDetector(config: config);
  return [...detector.add(signal), ...detector.finish()];
}

import 'dart:math' as math;

import 'pcm.dart';

/// What the two channels of a recording actually contain.
enum StereoContentKind {
  /// Too little signal for a verdict.
  tooQuiet,

  /// Both channels carry the same signal (up to a gain): duplicated mono,
  /// e.g. a receiver in mono/mix mode or Android upmixing a mono input.
  identical,

  /// The left channel stays silent (e.g. first transmitter off).
  leftSilent,

  /// The right channel stays silent (e.g. second transmitter off).
  rightSilent,

  /// Two different signals: two separate microphones.
  distinct,
}

/// Thresholds of [analyseStereoContent]. Not part of the technik.pdf 9.2
/// table; chosen so that real ambient noise of two microphones never counts
/// as identical.
class StereoContentLimits {
  StereoContentLimits._();

  /// Below this RMS a channel carries no usable signal.
  static const minRmsDbfs = -60.0;

  /// A channel this far below the other counts as silent.
  static const silentGapDb = 30.0;

  /// Zero-lag correlation from which both channels count as one signal.
  static const identicalCorrelation = 0.999;
}

class StereoContent {
  const StereoContent({
    required this.kind,
    required this.correlation,
    required this.leftRmsDbfs,
    required this.rightRmsDbfs,
  });

  final StereoContentKind kind;

  /// Normalized correlation of the channels at lag 0 (1 = same signal).
  final double correlation;
  final double leftRmsDbfs;
  final double rightRmsDbfs;

  String get message => switch (kind) {
    StereoContentKind.tooQuiet =>
      'Zu leise für eine Aussage. In beide Mikrofone sprechen oder reiben.',
    StereoContentKind.identical =>
      'Beide Kanäle sind identisch (Korrelation '
          '${correlation.toStringAsFixed(4)}): Das Gerät liefert Mono, '
          'das doppelt ausgegeben wird.',
    StereoContentKind.leftSilent =>
      'Nur der rechte Kanal hat Signal, der linke ist stumm.',
    StereoContentKind.rightSilent =>
      'Nur der linke Kanal hat Signal, der rechte ist stumm.',
    StereoContentKind.distinct =>
      'Zwei verschiedene Kanäle (Korrelation '
          '${correlation.toStringAsFixed(3)}): echtes Stereo.',
  };
}

/// Tells duplicated mono from two separate microphones (technik.pdf 4.4,
/// check 1, without claps): level per channel and zero-lag correlation.
StereoContent analyseStereoContent(StereoBlock block) {
  var ll = 0.0, rr = 0.0, lr = 0.0;
  for (var i = 0; i < block.length; i++) {
    final l = block.left[i], r = block.right[i];
    ll += l * l;
    rr += r * r;
    lr += l * r;
  }
  final n = math.max(block.length, 1);
  double db(double energy) =>
      energy <= 0 ? -200.0 : 10 * math.log(energy / n) / math.ln10;
  final leftDb = db(ll), rightDb = db(rr);
  final correlation = ll > 0 && rr > 0 ? lr / math.sqrt(ll * rr) : 0.0;
  StereoContent result(StereoContentKind kind) => StereoContent(
    kind: kind,
    correlation: correlation,
    leftRmsDbfs: leftDb,
    rightRmsDbfs: rightDb,
  );

  const min = StereoContentLimits.minRmsDbfs;
  if (leftDb < min && rightDb < min) return result(StereoContentKind.tooQuiet);
  if (rightDb < leftDb - StereoContentLimits.silentGapDb) {
    return result(StereoContentKind.rightSilent);
  }
  if (leftDb < rightDb - StereoContentLimits.silentGapDb) {
    return result(StereoContentKind.leftSilent);
  }
  if (correlation.abs() >= StereoContentLimits.identicalCorrelation) {
    return result(StereoContentKind.identical);
  }
  return result(StereoContentKind.distinct);
}

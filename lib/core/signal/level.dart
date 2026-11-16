import 'dart:math' as math;
import 'dart:typed_data';

/// Level reported for silence and the floor for all level values.
const double silenceDbfs = -120.0;

/// Level of one channel over one block.
class ChannelLevel {
  const ChannelLevel({
    required this.rmsDbfs,
    required this.peakDbfs,
    required this.clipping,
  });

  static const silence = ChannelLevel(
    rmsDbfs: silenceDbfs,
    peakDbfs: silenceDbfs,
    clipping: false,
  );

  final double rmsDbfs;
  final double peakDbfs;

  /// True if any sample exceeds the clip threshold (technik.pdf 4.4).
  final bool clipping;
}

/// RMS and peak level of [samples] (normalized to [-1, 1]) in dBFS.
///
/// [clipThreshold] is the fraction of full scale above which the block is
/// flagged as clipping; it comes from the configuration.
ChannelLevel measureLevel(
  Float64List samples, {
  required double clipThreshold,
}) {
  if (samples.isEmpty) return ChannelLevel.silence;
  var sumSquares = 0.0;
  var peak = 0.0;
  for (final s in samples) {
    sumSquares += s * s;
    final magnitude = s.abs();
    if (magnitude > peak) peak = magnitude;
  }
  final rms = math.sqrt(sumSquares / samples.length);
  return ChannelLevel(
    rmsDbfs: _toDbfs(rms),
    peakDbfs: _toDbfs(peak),
    clipping: peak > clipThreshold,
  );
}

double _toDbfs(double amplitude) {
  if (amplitude <= 0) return silenceDbfs;
  return math.max(silenceDbfs, 20 * math.log(amplitude) / math.ln10);
}

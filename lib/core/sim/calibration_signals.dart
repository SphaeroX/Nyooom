import 'dart:math' as math;
import 'dart:typed_data';

import '../dsp/biquad.dart';
import '../dsp/fractional_delay.dart';
import '../signal/pcm.dart';

/// Synthetic claps in the extension of the microphone axis (technik.pdf 7.1).
///
/// [side] +1: source beyond the right microphone (x > 0, Δ = +b/c);
/// −1: beyond the left one. Claps are decaying noise bursts at 0.5 s,
/// 1.3 s, 2.1 s, …
StereoBlock axialBursts({
  required double micSpacing,
  required double speedOfSound,
  required int side,
  double channelOffset = 0,
  bool swapChannels = false,
  bool mono = false,
  int count = 3,
  double distance = 3,
  double durationS = 3,
  double backgroundRms = 0.001,
  int sampleRate = 48000,
  int seed = 1,
}) {
  final fs = sampleRate.toDouble();
  final n = (durationS * fs).round();
  final random = math.Random(seed);
  double gauss() =>
      math.sqrt(-2 * math.log(1 - random.nextDouble())) *
      math.cos(2 * math.pi * random.nextDouble());

  final source = Float64List(n + 400);
  for (var k = 0; k < count; k++) {
    final start = ((0.5 + 0.8 * k) * fs).round();
    for (var i = 0; i < (0.08 * fs).round() && start + i < n; i++) {
      source[start + i] = 0.4 * gauss() * math.exp(-i / (0.012 * fs));
    }
  }
  final shaped = BiquadChain([
    Biquad.lowPass(fs, 0.2 * fs),
    Biquad.lowPass(fs, 0.2 * fs),
  ]).processBlock(source);

  // Arrival times along the axis: the nearer microphone hears it first.
  final nearDelay = (distance - micSpacing / 2) / speedOfSound;
  final farDelay = (distance + micSpacing / 2) / speedOfSound;
  final rightDelay = side > 0 ? nearDelay : farDelay;
  final leftDelay = (side > 0 ? farDelay : nearDelay) + channelOffset;
  final left = Float64List(n), right = Float64List(n);
  for (var i = 0; i < n; i++) {
    right[i] = fractionalSample(shaped, i - (rightDelay - nearDelay) * fs);
    left[i] = mono
        ? right[i]
        : fractionalSample(shaped, i - (leftDelay - nearDelay) * fs);
    right[i] += backgroundRms * gauss();
    left[i] += backgroundRms * gauss();
  }
  return swapChannels ? StereoBlock(right, left) : StereoBlock(left, right);
}

/// Constant noise from a loudspeaker (technik.pdf 4.4, check 2).
///
/// With [agcDropDb] a simulated automatic gain control lowers the level
/// linearly by that amount between 2 s and 5 s.
StereoBlock constantNoise({
  double durationS = 10,
  double rms = 0.05,
  double agcDropDb = 0,
  int sampleRate = 48000,
  int seed = 2,
}) {
  final fs = sampleRate.toDouble();
  final n = (durationS * fs).round();
  final random = math.Random(seed);
  double gauss() =>
      math.sqrt(-2 * math.log(1 - random.nextDouble())) *
      math.cos(2 * math.pi * random.nextDouble());
  final left = Float64List(n), right = Float64List(n);
  for (var i = 0; i < n; i++) {
    final t = i / fs;
    final dropDb = agcDropDb * ((t - 2) / 3).clamp(0.0, 1.0);
    final gain = math.pow(10, -dropDb / 20).toDouble();
    final s = rms * gauss();
    left[i] = gain * s;
    right[i] = gain * (0.7 * s + 0.3 * rms * gauss());
  }
  return StereoBlock(left, right);
}

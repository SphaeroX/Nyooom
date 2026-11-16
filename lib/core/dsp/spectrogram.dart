import 'dart:math' as math;
import 'dart:typed_data';

import '../config/nyooom_config.dart';
import 'fft.dart';

/// Power spectrogram of a mono signal (technik.pdf 5.4 variant 1 step 1):
/// Hann window [NyooomConfig.spectrogramWindow], hop
/// [NyooomConfig.spectrogramHop], zero-padded to
/// [NyooomConfig.spectrogramFftSize], limited to the tone band.
class Spectrogram {
  Spectrogram._({
    required this.times,
    required this.firstBin,
    required this.binCount,
    required this.binHz,
    required this.powerDb,
  });

  /// Spectrogram of [signal] between sample [from] and [to]. Times are frame
  /// centres relative to [from].
  factory Spectrogram.compute(
    Float64List signal, {
    required NyooomConfig config,
    int from = 0,
    int? to,
  }) {
    final end = to ?? signal.length;
    final window = config.spectrogramWindow;
    final size = config.spectrogramFftSize;
    final fs = config.sampleRate;
    final binHz = fs / size;
    final lo = (config.toneBandLowHz / binHz).floor();
    final hi = math.min(size ~/ 2, (config.toneBandHighHz / binHz).ceil());
    final bins = hi - lo + 1;
    final starts = blockStarts(end - from, window, config.spectrogramHop);
    final w = hannWindow(window);
    final fft = Fft.of(size);
    final power = Float64List(starts.length * bins);
    final times = Float64List(starts.length);
    final re = Float64List(size), im = Float64List(size);
    for (var r = 0; r < starts.length; r++) {
      re.fillRange(0, size, 0);
      im.fillRange(0, size, 0);
      final s = from + starts[r];
      for (var i = 0; i < window; i++) {
        re[i] = signal[s + i] * w[i];
      }
      fft.transform(re, im);
      for (var k = 0; k < bins; k++) {
        final b = lo + k;
        final p = re[b] * re[b] + im[b] * im[b];
        power[r * bins + k] = 10 * math.log(p + 1e-30) / math.ln10;
      }
      times[r] = (starts[r] + window / 2) / fs;
    }
    return Spectrogram._(
      times: times,
      firstBin: lo,
      binCount: bins,
      binHz: binHz,
      powerDb: power,
    );
  }

  /// Frame centre times in s.
  final Float64List times;

  /// FFT bin of column 0.
  final int firstBin;
  final int binCount;
  final double binHz;

  /// Row-major power in dB (rowCount × binCount).
  final Float64List powerDb;

  int get rowCount => times.length;
  double get lowHz => firstBin * binHz;
  double get highHz => (firstBin + binCount - 1) * binHz;

  double frequencyOf(int column) => (firstBin + column) * binHz;

  Float64List row(int r) =>
      Float64List.sublistView(powerDb, r * binCount, (r + 1) * binCount);

  /// Frequency of the strongest bin between [lowHz] and [highHz] in row [r],
  /// refined by parabolic interpolation of the dB values.
  double peakFrequency(int r, double lowHz, double highHz) {
    final values = row(r);
    final a = math.max(1, (lowHz / binHz).round() - firstBin);
    final b = math.min(binCount - 2, (highHz / binHz).round() - firstBin);
    var best = a;
    for (var k = a; k <= b; k++) {
      if (values[k] > values[best]) best = k;
    }
    return (firstBin + best + parabolicOffset(values, best)) * binHz;
  }
}

/// Offset in (−0.5, 0.5) of the vertex of the parabola through
/// values[i−1], values[i], values[i+1].
double parabolicOffset(Float64List values, int i) {
  if (i <= 0 || i >= values.length - 1) return 0;
  final a = values[i - 1], b = values[i], c = values[i + 1];
  final denom = a - 2 * b + c;
  if (denom >= 0) return 0;
  return (0.5 * (a - c) / denom).clamp(-0.5, 0.5);
}

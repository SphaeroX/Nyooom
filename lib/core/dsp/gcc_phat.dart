import 'dart:math' as math;
import 'dart:typed_data';

import '../config/nyooom_config.dart';
import '../signal/pcm.dart';
import 'fft.dart';
import 'fractional_delay.dart';

/// TDOA estimate of a whole signal piece.
class TdoaEstimate {
  const TdoaEstimate(this.delay, this.weight);

  /// Delay of the left channel relative to the right in s.
  final double delay;

  /// Peak height of the normalised correlation (1 = perfect coherence).
  final double weight;
}

/// Correlogram R(Δ, t_i) over block centre times and lags (technik.pdf 5.2).
class Correlogram {
  Correlogram({
    required this.times,
    required this.lagStep,
    required this.maxLagIndex,
    required this.values,
    required this.peakDelays,
    required this.peakWeights,
  });

  /// Block centre times in s, relative to the start of the analysed signal.
  final Float64List times;

  /// Lag resolution in s.
  final double lagStep;

  /// Lags run from −maxLagIndex to +maxLagIndex times [lagStep].
  final int maxLagIndex;

  /// Row-major matrix rowCount × lagCount.
  final Float64List values;

  /// Interpolated position of the maximum per block in s.
  final Float64List peakDelays;

  /// Height of the maximum per block (weight).
  final Float64List peakWeights;

  int get rowCount => times.length;
  int get lagCount => 2 * maxLagIndex + 1;
  double get maxLag => maxLagIndex * lagStep;

  double lagAt(int column) => (column - maxLagIndex) * lagStep;

  Float64List row(int index) =>
      Float64List.sublistView(values, index * lagCount, (index + 1) * lagCount);

  /// R at [lag] in block [rowIndex], linearly interpolated; 0 outside.
  double valueAt(int rowIndex, double lag) {
    final pos = lag / lagStep + maxLagIndex;
    if (pos < 0 || pos > lagCount - 1) return 0;
    final i = pos.floor();
    final base = rowIndex * lagCount;
    if (i >= lagCount - 1) return values[base + lagCount - 1];
    final w = pos - i;
    return values[base + i] * (1 - w) + values[base + i + 1] * w;
  }
}

/// GCC-PHAT time-delay estimation (technik.pdf 5.2).
///
/// Per block: Hann window, normalised cross spectrum X1·X2*/(|X1·X2*| + ε)
/// limited to the band, inverse transform. The 16-fold zero-padded inverse
/// transform is computed as its exact equivalent, band-limited (trigonometric)
/// interpolation of the unpadded inverse, evaluated only within ±1.2·b/c.
/// That keeps the lag resolution 1/(fs·padding) at a fraction of the cost.
class GccPhat {
  GccPhat({
    required this.config,
    required this.micSpacing,
    required this.speedOfSound,
  }) : _window = hannWindow(config.gccBlockLength),
       _fft = Fft.of(config.gccBlockLength) {
    final n = config.gccBlockLength;
    final fs = config.sampleRate;
    _lowBin = math.max(1, (config.gccBandLowHz / fs * n).ceil());
    _highBin = math.min(n ~/ 2 - 1, (config.gccBandHighHz / fs * n).floor());
    maxLagIndex = (config.gccSearchFactor * micSpacing / speedOfSound / lagStep)
        .floor();
    _baseHalf =
        (maxLagIndex / config.gccZeroPadding).ceil() +
        fractionalDelayHalfWidth +
        1;
  }

  final NyooomConfig config;
  final double micSpacing;
  final double speedOfSound;
  final Float64List _window;
  final Fft _fft;
  late final int _lowBin, _highBin, _baseHalf;

  /// Largest lag index of the search range ±gccSearchFactor·b/c.
  late final int maxLagIndex;

  /// Lag resolution 1/(fs·padding) in s.
  double get lagStep => 1 / (config.sampleRate * config.gccZeroPadding);

  int get lagCount => 2 * maxLagIndex + 1;

  /// Normalised correlation of one block starting at [start], over the lags
  /// −maxLagIndex..+maxLagIndex.
  Float64List blockCorrelation(Float64List left, Float64List right, int start) {
    final n = config.gccBlockLength;
    final re = Float64List(n), im = Float64List(n);
    for (var k = 0; k < n; k++) {
      re[k] = left[start + k] * _window[k];
      im[k] = right[start + k] * _window[k];
    }
    // Two real FFTs in one complex FFT.
    _fft.transform(re, im);
    final gr = Float64List(n), gi = Float64List(n);
    for (var k = _lowBin; k <= _highBin; k++) {
      final a = re[k], b = im[k], c = re[n - k], d = im[n - k];
      final x1r = (a + c) / 2, x1i = (b - d) / 2;
      final x2r = (b + d) / 2, x2i = (c - a) / 2;
      final pr = x1r * x2r + x1i * x2i;
      final pi = x1i * x2r - x1r * x2i;
      final mag = math.sqrt(pr * pr + pi * pi) + config.gccEpsilon;
      gr[k] = pr / mag;
      gi[k] = pi / mag;
    }
    _fft.transform(gr, gi, inverse: true);
    final scale = n / (_highBin - _lowBin + 1);
    // Base lags −_baseHalf.._baseHalf gathered from the circular result.
    final base = Float64List(2 * _baseHalf + 1);
    for (var i = 0; i < base.length; i++) {
      base[i] = gr[(i - _baseHalf + n) % n] * scale;
    }
    final pad = config.gccZeroPadding;
    final row = Float64List(lagCount);
    for (var j = 0; j < lagCount; j++) {
      row[j] = fractionalSample(base, (j - maxLagIndex) / pad + _baseHalf);
    }
    return row;
  }

  /// Correlogram over all complete blocks of [signal] between [from] and
  /// [to] (sample indices). Times are block centres relative to [from].
  Correlogram correlogram(StereoBlock signal, {int from = 0, int? to}) {
    final end = to ?? signal.length;
    final n = config.gccBlockLength;
    final starts = blockStarts(end - from, n, config.gccHop);
    final values = Float64List(starts.length * lagCount);
    final times = Float64List(starts.length);
    final delays = Float64List(starts.length);
    final weights = Float64List(starts.length);
    for (var b = 0; b < starts.length; b++) {
      final row = blockCorrelation(signal.left, signal.right, from + starts[b]);
      values.setAll(b * lagCount, row);
      times[b] = (starts[b] + n / 2) / config.sampleRate;
      final peak = _peak(row);
      delays[b] = peak.delay;
      weights[b] = peak.weight;
    }
    return Correlogram(
      times: times,
      lagStep: lagStep,
      maxLagIndex: maxLagIndex,
      values: values,
      peakDelays: delays,
      peakWeights: weights,
    );
  }

  /// One TDOA for a whole signal piece: maximum of the mean correlation.
  TdoaEstimate singleTdoa(StereoBlock signal, {int from = 0, int? to}) {
    final c = correlogram(signal, from: from, to: to);
    final mean = Float64List(lagCount);
    for (var b = 0; b < c.rowCount; b++) {
      final row = c.row(b);
      for (var j = 0; j < lagCount; j++) {
        mean[j] += row[j] / c.rowCount;
      }
    }
    return _peak(mean);
  }

  TdoaEstimate _peak(Float64List row) {
    var best = 0;
    for (var j = 1; j < row.length; j++) {
      if (row[j] > row[best]) best = j;
    }
    var offset = 0.0, height = row[best];
    if (best > 0 && best < row.length - 1) {
      final a = row[best - 1], b = row[best], c = row[best + 1];
      final denom = a - 2 * b + c;
      if (denom < 0) {
        offset = 0.5 * (a - c) / denom;
        height = b - 0.25 * (a - c) * offset;
      }
    }
    return TdoaEstimate((best - maxLagIndex + offset) * lagStep, height);
  }
}

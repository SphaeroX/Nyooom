import 'dart:math' as math;
import 'dart:typed_data';

/// In-place iterative radix-2 complex FFT.
///
/// Own implementation instead of a pub package: small, no licence questions,
/// and fast enough for the block sizes of technik.pdf (benchmark in
/// Roadmap Task_03). Instances cache twiddles and the bit-reversal table.
class Fft {
  Fft(this.size)
    : _cos = Float64List(size ~/ 2),
      _sin = Float64List(size ~/ 2),
      _reverse = Int32List(size) {
    if (size < 2 || size & (size - 1) != 0) {
      throw ArgumentError.value(size, 'size', 'must be a power of two');
    }
    for (var i = 0; i < size ~/ 2; i++) {
      _cos[i] = math.cos(2 * math.pi * i / size);
      _sin[i] = math.sin(2 * math.pi * i / size);
    }
    var bits = 0;
    while (1 << bits < size) {
      bits++;
    }
    for (var i = 0; i < size; i++) {
      var r = 0;
      for (var b = 0; b < bits; b++) {
        r |= ((i >> b) & 1) << (bits - 1 - b);
      }
      _reverse[i] = r;
    }
  }

  final int size;
  final Float64List _cos, _sin;
  final Int32List _reverse;

  static final Map<int, Fft> _cache = {};

  /// Shared instance for [size].
  static Fft of(int size) => _cache.putIfAbsent(size, () => Fft(size));

  /// Forward transform X[k] = Σ x[n]·e^(−j2πkn/N); with [inverse] the
  /// inverse including the 1/N factor.
  void transform(Float64List re, Float64List im, {bool inverse = false}) {
    final n = size;
    for (var i = 0; i < n; i++) {
      final j = _reverse[i];
      if (j > i) {
        final tr = re[i];
        re[i] = re[j];
        re[j] = tr;
        final ti = im[i];
        im[i] = im[j];
        im[j] = ti;
      }
    }
    final sign = inverse ? 1.0 : -1.0;
    for (var len = 2; len <= n; len <<= 1) {
      final half = len >> 1;
      final step = n ~/ len;
      for (var start = 0; start < n; start += len) {
        var t = 0;
        for (var k = 0; k < half; k++) {
          final wr = _cos[t];
          final wi = sign * _sin[t];
          t += step;
          final a = start + k, b = a + half;
          final xr = re[b] * wr - im[b] * wi;
          final xi = re[b] * wi + im[b] * wr;
          re[b] = re[a] - xr;
          im[b] = im[a] - xi;
          re[a] += xr;
          im[a] += xi;
        }
      }
    }
    if (inverse) {
      final scale = 1 / n;
      for (var i = 0; i < n; i++) {
        re[i] *= scale;
        im[i] *= scale;
      }
    }
  }
}

/// Periodic Hann window of length [n] (w[0] = 0, w[n/2] = 1).
Float64List hannWindow(int n) => Float64List.fromList(
  List.generate(n, (i) => 0.5 * (1 - math.cos(2 * math.pi * i / n))),
);

/// Start indices of all complete blocks of [blockLength] with [hop] in a
/// signal of [length] samples.
List<int> blockStarts(int length, int blockLength, int hop) => [
  for (var s = 0; s + blockLength <= length; s += hop) s,
];

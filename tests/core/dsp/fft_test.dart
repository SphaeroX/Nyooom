import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/dsp/fft.dart';
import 'package:test/test.dart';

void main() {
  final random = math.Random(3);

  (Float64List, Float64List) randomSignal(int n) => (
    Float64List.fromList(List.generate(n, (_) => random.nextDouble() - 0.5)),
    Float64List.fromList(List.generate(n, (_) => random.nextDouble() - 0.5)),
  );

  test('matches a naive DFT for small sizes', () {
    for (final n in [8, 16, 64]) {
      final (re, im) = randomSignal(n);
      final outRe = Float64List.fromList(re), outIm = Float64List.fromList(im);
      Fft(n).transform(outRe, outIm);
      for (var k = 0; k < n; k++) {
        var sr = 0.0, si = 0.0;
        for (var t = 0; t < n; t++) {
          final a = -2 * math.pi * k * t / n;
          sr += re[t] * math.cos(a) - im[t] * math.sin(a);
          si += re[t] * math.sin(a) + im[t] * math.cos(a);
        }
        expect(outRe[k], closeTo(sr, 1e-9));
        expect(outIm[k], closeTo(si, 1e-9));
      }
    }
  });

  test('Parseval holds', () {
    const n = 1024;
    final (re, im) = randomSignal(n);
    var timeEnergy = 0.0;
    for (var i = 0; i < n; i++) {
      timeEnergy += re[i] * re[i] + im[i] * im[i];
    }
    Fft(n).transform(re, im);
    var freqEnergy = 0.0;
    for (var i = 0; i < n; i++) {
      freqEnergy += re[i] * re[i] + im[i] * im[i];
    }
    expect(freqEnergy / n, closeTo(timeEnergy, 1e-8));
  });

  test('inverse transform restores the signal', () {
    const n = 2048;
    final (re, im) = randomSignal(n);
    final r = Float64List.fromList(re), i = Float64List.fromList(im);
    final fft = Fft(n);
    fft.transform(r, i);
    fft.transform(r, i, inverse: true);
    for (var k = 0; k < n; k++) {
      expect(r[k], closeTo(re[k], 1e-12));
      expect(i[k], closeTo(im[k], 1e-12));
    }
  });

  test('rejects sizes that are not a power of two', () {
    expect(() => Fft(1000), throwsArgumentError);
  });

  test('Hann window is periodic, zero at the start, one in the middle', () {
    final w = hannWindow(8);
    expect(w.first, 0);
    expect(w[1], closeTo(w[7], 1e-15));
    expect(w[4], closeTo(1, 1e-15));
  });

  test('block starts cover the signal with the given hop', () {
    expect(blockStarts(5000, 2048, 512), [0, 512, 1024, 1536, 2048, 2560]);
    expect(blockStarts(1000, 2048, 512), isEmpty);
  });
}

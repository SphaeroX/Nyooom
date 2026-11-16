import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/dsp/biquad.dart';
import 'package:nyooom/core/dsp/fft.dart';
import 'package:nyooom/core/dsp/fractional_delay.dart';
import 'package:nyooom/core/dsp/gcc_phat.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:test/test.dart';

const fs = 48000.0;
const micSpacing = 0.15;
const c = 343.0;

Float64List bandNoise(int n, int seed) {
  final random = math.Random(seed);
  final x = Float64List.fromList(
    List.generate(n, (_) => random.nextDouble() - 0.5),
  );
  return BiquadChain([
    Biquad.lowPass(fs, 0.2 * fs),
    Biquad.lowPass(fs, 0.2 * fs),
  ]).processBlock(x);
}

/// Left channel is the right channel delayed by [delay] seconds.
StereoBlock delayed(double delay, {int n = 16384, int seed = 1}) {
  final source = bandNoise(n + 200, seed);
  final right = Float64List(n), left = Float64List(n);
  for (var i = 0; i < n; i++) {
    right[i] = source[i + 100];
    left[i] = fractionalSample(source, i + 100 - delay * fs);
  }
  return StereoBlock(left, right);
}

void main() {
  const config = NyooomConfig();
  final gcc = GccPhat(config: config, micSpacing: micSpacing, speedOfSound: c);

  test('lag resolution is 1/(48 kHz * 16), about 1.3 us', () {
    expect(gcc.lagStep, closeTo(1 / (48000 * 16), 1e-15));
    expect(gcc.lagStep, closeTo(1.3e-6, 0.05e-6));
  });

  test('finds constant delays in noise to better than 3 us', () {
    for (final delay in [200e-6, -350e-6, 0.0]) {
      final signal = delayed(delay);
      final correlogram = gcc.correlogram(signal);
      expect(correlogram.rowCount, greaterThan(10));
      for (var i = 0; i < correlogram.rowCount; i++) {
        expect(correlogram.peakDelays[i], closeTo(delay, 3e-6));
      }
      expect(gcc.singleTdoa(signal).delay, closeTo(delay, 3e-6));
    }
  });

  test('delays outside +-1.2 b/c are never reported', () {
    final signal = delayed(800e-6);
    final limit = config.gccSearchFactor * micSpacing / c;
    final correlogram = gcc.correlogram(signal);
    for (final d in correlogram.peakDelays) {
      expect(d.abs(), lessThanOrEqualTo(limit + 1e-12));
      expect((d - 800e-6).abs(), greaterThan(100e-6));
    }
  });

  test('interpolated rows equal an explicit 16-fold zero-padded IFFT', () {
    final signal = delayed(123e-6, n: 4096);
    final row = gcc.blockCorrelation(signal.left, signal.right, 1000);
    final n = config.gccBlockLength, big = n * config.gccZeroPadding;
    final w = hannWindow(n);
    final r1 = Float64List(n), i1 = Float64List(n);
    final r2 = Float64List(n), i2 = Float64List(n);
    for (var k = 0; k < n; k++) {
      r1[k] = signal.left[1000 + k] * w[k];
      r2[k] = signal.right[1000 + k] * w[k];
    }
    Fft(n).transform(r1, i1);
    Fft(n).transform(r2, i2);
    final pr = Float64List(big), pi = Float64List(big);
    final lo = (config.gccBandLowHz / fs * n).ceil();
    final hi = (config.gccBandHighHz / fs * n).floor();
    for (var k = lo; k <= hi; k++) {
      final gr = r1[k] * r2[k] + i1[k] * i2[k];
      final gi = i1[k] * r2[k] - r1[k] * i2[k];
      final mag = math.sqrt(gr * gr + gi * gi) + config.gccEpsilon;
      pr[k] = gr / mag;
      pi[k] = gi / mag;
    }
    Fft(big).transform(pr, pi, inverse: true);
    final bins = hi - lo + 1;
    for (var j = 0; j < row.length; j++) {
      final lagIndex = j - gcc.maxLagIndex;
      // Normalised so that perfect coherence gives 1.
      final explicit = pr[(lagIndex + big) % big] * big / bins;
      expect(row[j], closeTo(explicit, 2e-3), reason: 'lag $lagIndex');
    }
  });

  test('block maxima follow the model near t0 (RMS below 10 us)', () {
    for (final (kmh, d) in [(30.0, 5.0), (50.0, 4.0)]) {
      for (final direction in [1, -1]) {
        final pass = Scenarios.electric(
          speedKmh: kmh,
          distance: d,
          direction: direction,
          t0: 2,
        );
        final rec = Scenarios.render(pass, durationS: 4, snrDb: 30);
        final truth = rec.truths.single;
        final g = GccPhat(
          config: config,
          micSpacing: Scenarios.defaultMicSpacing,
          speedOfSound: truth.speedOfSound,
        );
        final correlogram = g.correlogram(rec.signal);
        var sum = 0.0, count = 0;
        for (var i = 0; i < correlogram.rowCount; i++) {
          final t = correlogram.times[i];
          if ((t - truth.receptionT0).abs() > 1) continue;
          final e = correlogram.peakDelays[i] - truth.model.tdoa(t);
          sum += e * e;
          count++;
        }
        expect(
          math.sqrt(sum / count),
          lessThan(10e-6),
          reason: '$kmh km/h, $d m, direction $direction',
        );
      }
    }
  });

  test(
    'the weight is much smaller for uncorrelated noise than for a source',
    () {
      final random = math.Random(5);
      final n = 16384;
      final noise = StereoBlock(
        Float64List.fromList(List.generate(n, (_) => random.nextDouble() - .5)),
        Float64List.fromList(List.generate(n, (_) => random.nextDouble() - .5)),
      );
      double meanWeight(StereoBlock s) {
        final w = gcc.correlogram(s).peakWeights;
        return w.reduce((a, b) => a + b) / w.length;
      }

      expect(meanWeight(noise), lessThan(0.3 * meanWeight(delayed(100e-6))));
    },
  );

  test('correlogram value lookup interpolates between lags', () {
    final correlogram = gcc.correlogram(delayed(50e-6));
    final peak = correlogram.valueAt(0, 50e-6);
    expect(peak, greaterThan(correlogram.valueAt(0, -200e-6)));
    expect(correlogram.valueAt(0, 1), 0); // outside the range
  });

  test('an 8 s window is evaluated within the recorded bound', () {
    final rec = Scenarios.render(
      Scenarios.combustion(speedKmh: 30, distance: 5),
      durationS: 8,
    );
    final watch = Stopwatch()..start();
    final correlogram = gcc.correlogram(rec.signal);
    watch.stop();
    // ignore: avoid_print
    print(
      'GCC-PHAT 8 s window: ${watch.elapsedMilliseconds} ms, '
      '${correlogram.rowCount} blocks',
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
  });
}

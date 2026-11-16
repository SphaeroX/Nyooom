import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/dsp/fractional_delay.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

/// Delay of [left] relative to [right] in seconds around sample [centre],
/// found by brute-force cross-correlation with sinc interpolation.
double bruteForceDelay(
  Float64List left,
  Float64List right,
  int centre, {
  int half = 512,
  double fs = 48000,
}) {
  double corr(double lag) {
    var acc = 0.0;
    for (var n = centre - half; n < centre + half; n++) {
      acc += left[n] * fractionalSample(right, n - lag);
    }
    return acc;
  }

  var best = 0;
  var bestValue = -double.infinity;
  for (var lag = -30; lag <= 30; lag++) {
    final v = corr(lag.toDouble());
    if (v > bestValue) {
      bestValue = v;
      best = lag;
    }
  }
  // Golden-section refinement within one sample.
  var a = best - 1.0, b = best + 1.0;
  const g = 0.6180339887;
  var c = b - g * (b - a), d = a + g * (b - a);
  var fc = corr(c), fd = corr(d);
  while (b - a > 1e-3) {
    if (fc > fd) {
      b = d;
      d = c;
      fd = fc;
      c = b - g * (b - a);
      fc = corr(c);
    } else {
      a = c;
      c = d;
      fc = fd;
      d = a + g * (b - a);
      fd = corr(d);
    }
  }
  return (a + b) / 2 / fs;
}

/// Mean frequency of [x] between two sample indices from zero crossings.
double zeroCrossingFrequency(Float64List x, int from, int to, double fs) {
  final crossings = <double>[];
  for (var n = from; n < to - 1; n++) {
    if (x[n] <= 0 && x[n + 1] > 0) {
      crossings.add(n + x[n] / (x[n] - x[n + 1]));
    }
  }
  return (crossings.length - 1) / ((crossings.last - crossings.first) / fs);
}

void main() {
  const fs = 48000.0;

  group('PassBySimulator', () {
    test('channel delay follows the TDOA model to better than 2 us', () {
      for (final offset in [0.0, 25e-6]) {
        final pass = Scenarios.combustion(
          speedKmh: 50,
          distance: 4,
          t0: 1.5,
          tone: false,
        );
        final rec = PassBySimulator(
          Scenarios.setup(channelOffset: offset, backgroundRms: 0),
        ).render(3, [pass]);
        final model = rec.truths.single.model;
        for (final t in [0.7, rec.truths.single.receptionT0, 2.3]) {
          final centre = (t * fs).round();
          final measured = bruteForceDelay(
            rec.signal.left,
            rec.signal.right,
            centre,
            half: 256,
          );
          expect(
            measured,
            closeTo(model.tdoa(centre / fs), 2e-6),
            reason: 'offset $offset at t=$t',
          );
        }
      }
    });

    test('tone frequency far before and after the pass is f_an / f_ab', () {
      final pass = VehiclePass(
        speed: fromKmh(30),
        distance: 5,
        t0: 4,
        noiseRms: 0,
        tones: const [ToneSpec(1000, 0.2)],
      );
      final rec = PassBySimulator(Scenarios.setup(backgroundRms: 0))
          .render(8, [pass]);
      final model = rec.truths.single.model;
      final before = zeroCrossingFrequency(rec.signal.left, 9600, 28800, fs);
      final after = zeroCrossingFrequency(rec.signal.left, 355200, 374400, fs);
      expect(before, closeTo(model.dopplerFrequency(1000, 0.4), 0.2));
      expect(after, closeTo(model.dopplerFrequency(1000, 7.6), 0.2));
      final v = fromKmh(30), c = model.speedOfSound;
      expect(before, closeTo(1000 / (1 - v / c), 1.0));
      expect(after, closeTo(1000 / (1 + v / c), 1.0));
    });

    test('the opposite direction mirrors the TDOA', () {
      final pass = Scenarios.electric(
        speedKmh: 30,
        distance: 5,
        direction: -1,
        t0: 1.5,
      );
      final rec = PassBySimulator(Scenarios.setup(backgroundRms: 0))
          .render(3, [pass]);
      final early = bruteForceDelay(rec.signal.left, rec.signal.right, 24000);
      expect(early, greaterThan(100e-6));
      expect(rec.truths.single.direction, -1);
    });

    test('background noise has the requested RMS and is uncorrelated', () {
      final rec = PassBySimulator(Scenarios.setup(backgroundRms: 0.01))
          .render(1, const []);
      var l = 0.0, r = 0.0, lr = 0.0;
      for (var i = 0; i < rec.signal.length; i++) {
        l += rec.signal.left[i] * rec.signal.left[i];
        r += rec.signal.right[i] * rec.signal.right[i];
        lr += rec.signal.left[i] * rec.signal.right[i];
      }
      final n = rec.signal.length;
      expect(math.sqrt(l / n), closeTo(0.01, 0.0005));
      expect(math.sqrt(r / n), closeTo(0.01, 0.0005));
      expect((lr / n).abs() / (l / n), lessThan(0.02));
    });

    test(
      'snr sets the background relative to the source at closest approach',
      () {
        final pass = Scenarios.combustion(speedKmh: 30, distance: 5);
        final quiet = backgroundRmsForSnr(pass, 20);
        final loud = backgroundRmsForSnr(pass, 0);
        expect(loud / quiet, closeTo(10, 1e-9));
        expect(loud, closeTo(pass.sourceRms / 5, 1e-12));
      },
    );

    test('acceleration raises the engine tone over time', () {
      final pass = VehiclePass(
        speed: fromKmh(30),
        distance: 5,
        t0: 4,
        acceleration: 1,
        noiseRms: 0,
        tones: const [ToneSpec(800, 0.2)],
      );
      final rec = PassBySimulator(Scenarios.setup(backgroundRms: 0))
          .render(8, [pass]);
      // Far after the pass the Doppler factor is nearly constant, so the
      // rising pitch dominates: compare two late segments.
      final early = zeroCrossingFrequency(rec.signal.left, 316800, 326400, fs);
      final late = zeroCrossingFrequency(rec.signal.left, 364800, 374400, fs);
      expect(late, greaterThan(early + 10));
      expect(rec.truths.single.acceleration, 1);
    });

    test('two overlapping vehicles produce two ground truths', () {
      final rec = PassBySimulator(Scenarios.setup()).render(4, [
        Scenarios.combustion(speedKmh: 30, distance: 5, t0: 1.5),
        Scenarios.electric(speedKmh: 40, distance: 6, t0: 2.5, direction: -1),
      ]);
      expect(rec.truths, hasLength(2));
      expect(rec.truths[0].kind, VehicleKind.combustion);
      expect(rec.truths[1].kind, VehicleKind.electric);
      expect(rec.signal.length, 4 * 48000);
    });

    test('tone lead shifts the tone source ahead of the noise source', () {
      final pass = Scenarios.combustion(
        speedKmh: 30,
        distance: 5,
        toneLeadS: 0.2,
      );
      final rec = PassBySimulator(Scenarios.setup()).render(1, [pass]);
      expect(rec.truths.single.toneLeadS, 0.2);
      expect(rec.truths.single.toneModel.t0, closeTo(pass.t0 - 0.2, 1e-12));
    });
  });

  group('Scenarios', () {
    test('standard fixtures in both directions, with and without tone', () {
      for (final direction in [1, -1]) {
        for (final tone in [true, false]) {
          for (final (kmh, d) in [(30.0, 5.0), (50.0, 4.0)]) {
            final pass = Scenarios.combustion(
              speedKmh: kmh,
              distance: d,
              direction: direction,
              tone: tone,
            );
            expect(pass.speed, closeTo(direction * fromKmh(kmh), 1e-12));
            expect(pass.distance, d);
            expect(pass.tones.isNotEmpty, tone);
          }
        }
      }
    });

    test(
      'electric cars are quieter and only have a tone with warning sound',
      () {
        final ev = Scenarios.electric(speedKmh: 30, distance: 5);
        final evAvas = Scenarios.electric(
          speedKmh: 30,
          distance: 5,
          warningTone: true,
        );
        final ice = Scenarios.combustion(speedKmh: 30, distance: 5);
        expect(ev.tones, isEmpty);
        expect(evAvas.tones, isNotEmpty);
        expect(ev.sourceRms, lessThan(ice.sourceRms));
        expect(ev.kind, VehicleKind.electric);
      },
    );
  });
}

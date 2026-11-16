import 'dart:math' as math;

import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/model/passby_model.dart';
import 'package:test/test.dart';

double kmh(double v) => v / 3.6;

void main() {
  group('acoustics', () {
    test('speed of sound follows technik.pdf 3.5', () {
      expect(speedOfSound(0), closeTo(331.3, 1e-9));
      expect(speedOfSound(20), closeTo(343.2, 0.05));
    });

    test('slant distance includes the height difference (3.1)', () {
      expect(slantDistance(4, 0.9), closeTo(math.sqrt(16 + 0.81), 1e-12));
      expect(slantDistance(5, 0), 5);
    });
  });

  group('PassByModel', () {
    PassByModel model({
      double speedKmh = 30,
      double distance = 5,
      double micSpacing = 0.15,
      double c = 343,
      double channelOffset = 0,
    }) => PassByModel(
      speed: kmh(speedKmh),
      distance: distance,
      t0: 10,
      micSpacing: micSpacing,
      speedOfSound: c,
      channelOffset: channelOffset,
    );

    test('direction cosine is zero at t0, monotonic and tends to +-1', () {
      final m = model();
      expect(m.directionCosineAtEmission(10), 0);
      var last = -2.0;
      for (var te = 0.0; te <= 20; te += 0.01) {
        final u = m.directionCosineAtEmission(te);
        expect(u, greaterThan(last));
        last = u;
      }
      expect(m.directionCosineAtEmission(-1000), closeTo(-1, 1e-4));
      expect(m.directionCosineAtEmission(1000), closeTo(1, 1e-4));
    });

    test('the sign of u follows the direction of travel', () {
      final backwards = model(speedKmh: -30);
      expect(backwards.directionCosineAtEmission(9), greaterThan(0));
      expect(backwards.directionCosineAtEmission(11), lessThan(0));
    });

    test('reception time is emission time plus r/c', () {
      final m = model();
      const te = 9.3;
      final t = m.receptionTime(te);
      expect(t, closeTo(te + m.range(te) / 343, 1e-12));
      expect(m.emissionTime(t), closeTo(te, 1e-9));
    });

    test('emission grid is interpolated onto reception times', () {
      final m = model();
      final te = List.generate(2001, (i) => 8 + i * 0.002);
      final values = te.map(m.directionCosineAtEmission).toList();
      final t = [9.0, 10.0, 10.02, 11.5];
      final interpolated = interpolateEmissionGrid(
        emissionTimes: te,
        values: values,
        receptionTimes: t,
        model: m,
      );
      for (var i = 0; i < t.length; i++) {
        expect(interpolated[i], closeTo(m.directionCosine(t[i]), 1e-5));
      }
    });

    test('magnitudes of technik.pdf 3.5 are reproduced', () {
      final slow = model();
      expect(slow.micSpacing / slow.speedOfSound, closeTo(437e-6, 0.5e-6));
      expect(slow.kappa, closeTo(1.67, 0.005));
      // Slope of the TDOA at t0: 0.73 ms/s.
      final arrivalT0 = slow.receptionTime(10);
      const h = 1e-4;
      final slope =
          (slow.tdoa(arrivalT0 + h) - slow.tdoa(arrivalT0 - h)) / (2 * h);
      expect(slope, closeTo(0.73e-3, 0.005e-3));
      expect(slow.frequencyJump, closeTo(0.050, 0.0005));

      final fast = model(speedKmh: 50, distance: 4);
      expect(fast.kappa, closeTo(3.47, 0.005));
      expect(fast.frequencyJump, closeTo(0.084, 0.0005));
    });

    test('Doppler limits far before and after the pass', () {
      final m = model();
      const f0 = 1000.0;
      final v = kmh(30);
      expect(m.dopplerFrequency(f0, -1e5), closeTo(f0 / (1 - v / 343), 1e-3));
      expect(m.dopplerFrequency(f0, 1e5), closeTo(f0 / (1 + v / 343), 1e-3));
    });

    test('fusion relation 3.4: 1/f over TDOA is a line with v = b*B/A', () {
      final m = model(speedKmh: 47);
      const f0 = 812.0;
      final xs = <double>[];
      final ys = <double>[];
      for (var t = 7.0; t < 13; t += 0.05) {
        xs.add(m.tdoa(t));
        ys.add(1 / m.dopplerFrequency(f0, t));
      }
      final n = xs.length;
      final mx = xs.reduce((a, b) => a + b) / n;
      final my = ys.reduce((a, b) => a + b) / n;
      var sxy = 0.0, sxx = 0.0;
      for (var i = 0; i < n; i++) {
        sxy += (xs[i] - mx) * (ys[i] - my);
        sxx += (xs[i] - mx) * (xs[i] - mx);
      }
      final slopeB = sxy / sxx;
      final interceptA = my - slopeB * mx;
      expect(m.micSpacing * slopeB / interceptA, closeTo(kmh(47), 1e-9));
    });

    test('channel offset shifts the TDOA', () {
      final m = model(channelOffset: 20e-6);
      expect(m.tdoa(m.receptionTime(10)), closeTo(20e-6, 1e-12));
    });
  });
}

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/pipeline/doppler_sharpness.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

// Counter-check of Doppler variant 2 (found with the real recordings of
// 2026-11-23): what stays equally sharp when the signal is warped the
// wrong way round is not a tone of the passing vehicle.

const config = NyooomConfig();

void main() {
  test('a tone that does not move with the vehicle is no Doppler tone', () {
    // Tyre noise of a passing car plus a weak stationary 1.2 kHz tone in
    // the background (fan, transformer). Its line is sharpest without any
    // warping, so the sharpness is largest at the slowest candidate.
    final pass = VehiclePass(
      speed: fromKmh(40),
      distance: 5,
      t0: 4,
      noiseRms: 0.15,
    );
    final rec = Scenarios.render(pass, durationS: 8, snrDb: 30);
    final truth = rec.truths.single;
    final sum = Float64List(rec.signal.length);
    for (var i = 0; i < sum.length; i++) {
      sum[i] =
          0.5 * (rec.signal.left[i] + rec.signal.right[i]) +
          0.0015 * math.sin(2 * math.pi * 1200 * i / config.sampleRate);
    }
    final estimator = SharpnessEstimator(
      config: config,
      speedOfSound: truth.speedOfSound,
    );
    // Precondition: the line is there and fades as the warping grows.
    double s(double v) => estimator.sharpness(
      sum,
      windowStartS: 0,
      speed: v,
      kappa: truth.kappa,
      t0: truth.t0,
    );
    expect(s(config.dopplerSpeedMin), greaterThan(config.sharpnessMinPeak));
    expect(s(config.dopplerSpeedMin), greaterThan(3 * s(15)));

    final result = estimator.estimate(
      sum,
      windowStartS: 0,
      kappa: truth.kappa,
      t0: truth.t0,
    );
    expect(result.hasTone, isFalse);
  });

  test('warping the wrong way round blurs a tone of the vehicle', () {
    final pass = VehiclePass(
      speed: fromKmh(40),
      distance: 5,
      t0: 4,
      noiseRms: 0.15,
      tones: const [ToneSpec(1800, 0.015)],
    );
    final rec = Scenarios.render(pass, durationS: 8, snrDb: 30);
    final truth = rec.truths.single;
    final sum = Float64List.fromList([
      for (var i = 0; i < rec.signal.length; i++)
        0.5 * (rec.signal.left[i] + rec.signal.right[i]),
    ]);
    final estimator = SharpnessEstimator(
      config: config,
      speedOfSound: truth.speedOfSound,
    );
    double s(double v, {bool reversed = false}) => estimator.sharpness(
      sum,
      windowStartS: 0,
      speed: v,
      kappa: truth.kappa,
      t0: truth.t0,
      reversed: reversed,
    );
    // Same amount of warping, wrong sign: the Doppler shift is doubled
    // instead of removed.
    final v = fromKmh(40);
    expect(
      s(v) - config.sharpnessPeakFactor * s(v, reversed: true),
      greaterThan(config.sharpnessMinPeak),
    );
    final result = estimator.estimate(
      sum,
      windowStartS: 0,
      kappa: truth.kappa,
      t0: truth.t0,
    );
    expect(result.hasTone, isTrue);
  });
}

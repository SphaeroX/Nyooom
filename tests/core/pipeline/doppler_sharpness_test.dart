import 'dart:typed_data';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/pipeline/doppler.dart';
import 'package:nyooom/core/pipeline/doppler_sharpness.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

({SimulatedRecording rec, GroundTruth truth}) render(
  List<ToneSpec> tones, {
  double kmh = 40,
  double d = 5,
  int direction = 1,
}) {
  final pass = VehiclePass(
    speed: direction * fromKmh(kmh),
    distance: d,
    t0: 4,
    noiseRms: 0.15,
    tones: tones,
  );
  final rec = Scenarios.render(pass, durationS: 8, snrDb: 30);
  return (rec: rec, truth: rec.truths.single);
}

SharpnessEstimator estimator(GroundTruth t) =>
    SharpnessEstimator(config: config, speedOfSound: t.speedOfSound);

Float64List sum(SimulatedRecording rec) => Float64List.fromList([
  for (var i = 0; i < rec.signal.length; i++)
    0.5 * (rec.signal.left[i] + rec.signal.right[i]),
]);

void main() {
  // A weak 1.8 kHz tone: below the 8-dB threshold of variant 1 per frame,
  // but a sharp line after dewarping and averaging.
  const weak = [ToneSpec(1800, 0.015)];

  test('a weak tone below the variant-1 threshold is found within 2 km/h', () {
    final r = render(weak);
    final v1 =
        DopplerEstimator(
          config: config,
          speedOfSound: r.truth.speedOfSound,
        ).estimate(
          r.rec.signal,
          windowStartS: 0,
          receptionT0: r.truth.receptionT0,
          directionCosine: r.truth.model.directionCosine,
        );
    expect(v1.hasTone, isFalse, reason: 'precondition: too weak for variant 1');
    final v2 = estimator(r.truth).estimate(
      sum(r.rec),
      windowStartS: 0,
      kappa: r.truth.kappa,
      t0: r.truth.t0,
    );
    expect(v2.hasTone, isTrue);
    expect(toKmh(v2.speed!), closeTo(40, 2));
    expect(v2.sigma, greaterThan(0));
  });

  test('without tone the criterion "no tone" applies', () {
    final r = render(const []);
    final v2 = estimator(r.truth).estimate(
      sum(r.rec),
      windowStartS: 0,
      kappa: r.truth.kappa,
      t0: r.truth.t0,
    );
    expect(v2.hasTone, isFalse);
    expect(v2.speed, isNull);
  });

  test('the dewarped spectrum is sharpest at the true speed', () {
    final r = render(const [ToneSpec(1500, 0.02), ToneSpec(3000, 0.01)]);
    final e = estimator(r.truth);
    final signal = sum(r.rec);
    final v = fromKmh(40);
    double s(double speed) => e.sharpness(
      signal,
      windowStartS: 0,
      speed: speed,
      kappa: r.truth.kappa,
      t0: r.truth.t0,
    );
    expect(s(v), greaterThan(s(v - 2)));
    expect(s(v), greaterThan(s(v + 2)));
  });

  test('also the opposite direction with a weak tone', () {
    // Variant 2 is meant for weak tones (strong ones go to variant 1).
    final r = render(weak, kmh: 30, direction: -1);
    final v2 = estimator(r.truth).estimate(
      sum(r.rec),
      windowStartS: 0,
      kappa: r.truth.kappa,
      t0: r.truth.t0,
    );
    expect(toKmh(v2.speed!), closeTo(30, 2));
  });

  group('choice between variant 1 and 2', () {
    const v1Tone = DopplerChoice(
      speed: 11,
      sigma: 0.4,
      toneCount: 2,
      variant: 1,
    );
    const v2Tone = DopplerChoice(
      speed: 11.5,
      sigma: 0.6,
      toneCount: 0,
      variant: 2,
    );
    test('variant 1 wins when it has a tone', () {
      expect(
        chooseDoppler(v1: v1Tone, v2: v2Tone, variant2Enabled: true),
        v1Tone,
      );
    });
    test('variant 2 is used only without variant-1 tone', () {
      expect(
        chooseDoppler(v1: null, v2: v2Tone, variant2Enabled: true),
        v2Tone,
      );
      expect(
        chooseDoppler(v1: null, v2: v2Tone, variant2Enabled: false),
        isNull,
      );
      expect(chooseDoppler(v1: null, v2: null, variant2Enabled: true), isNull);
    });
  });
}

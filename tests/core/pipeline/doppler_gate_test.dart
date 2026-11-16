import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/pipeline/doppler.dart';
import 'package:nyooom/core/pipeline/fusion.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

const engine = [
  ToneSpec(800, 0.05),
  ToneSpec(1600, 0.03),
  ToneSpec(2400, 0.02),
];

void main() {
  test('a tone that rises during the pass is flagged, not turned into a '
      'speed', () {
    // technik.pdf 6.1: only the falling S shape is a Doppler curve. With
    // 2 m/s² at 30 km/h the engine pitch rises by 24 % per second, far
    // more than the Doppler fall of about 4 % per second: the regression
    // gives v with the sign against the direction of travel. Taking |v|
    // would report it as a speed.
    for (final direction in [1, -1]) {
      DopplerResult run(double acceleration) {
        final rec = Scenarios.render(
          VehiclePass(
            speed: direction * fromKmh(30),
            distance: 5,
            t0: 4,
            acceleration: direction * acceleration,
            noiseRms: 0.15,
            tones: engine,
          ),
          durationS: 8,
        );
        final truth = rec.truths.single;
        return DopplerEstimator(
          config: config,
          speedOfSound: truth.speedOfSound,
        ).estimate(
          rec.signal,
          windowStartS: 0,
          receptionT0: truth.receptionT0,
          directionCosine: truth.model.directionCosine,
        );
      }

      final constant = run(0);
      expect(constant.hasTone, isTrue);
      expect(constant.frequencyRises, isFalse);
      final accelerating = run(2);
      expect(accelerating.hasTone, isTrue);
      expect(accelerating.frequencyRises, isTrue);
    }
  });

  test('a rising tone downgrades to class B like an acceleration', () {
    final result = fuse(
      config: config,
      vT: 11,
      sigmaT: 0.8,
      kappa: 2.2,
      laneDistance: 5,
      vD: 11.1,
      sigmaD: 0.4,
      vDWithAcceleration: 11.1,
      frequencyRises: true,
    );
    expect(result.klasse, QualityClass.b);
    expect(result.reason, DowngradeReason.acceleration);
    expect(result.v, 11);
  });

  test('tones of a following vehicle are left out by the distance check '
      'per tone track', () {
    // Electric car with warning tone, a combustion car 2.5 s behind. The
    // engine tones of the second car are audible while the first passes;
    // against u(t) of the first car they hardly move, which drags a common
    // regression towards a much lower speed.
    final sim = Scenarios.setup(backgroundRms: 0.002);
    const lane = 4.1;
    final rec = PassBySimulator(sim).render(14, [
      Scenarios.electric(
        speedKmh: 40,
        distance: lane,
        t0: 6,
        warningTone: true,
      ),
      Scenarios.combustion(
        speedKmh: 40,
        distance: lane,
        t0: 8.5,
        fundamentalHz: 180,
        noiseRms: 0.1,
        toneAmplitude: 0.1,
      ),
    ]);
    final truth = rec.truths.first;
    final estimator = DopplerEstimator(
      config: config,
      speedOfSound: sim.speedOfSound,
    );
    DopplerResult run({ToneGate? gate}) => estimator.estimate(
      rec.signal,
      windowStartS: 0,
      receptionT0: truth.receptionT0,
      directionCosine: truth.model.directionCosine,
      gate: gate,
    );
    final open = run();
    final gated = run(
      gate: ToneGate(kappa: truth.kappa, laneDistance: lane),
    );
    expect(gated.hasTone, isTrue);
    expect(toKmh(gated.speed!), closeTo(40, 1.5));
    expect(gated.toneCount, lessThan(open.toneCount));
    expect(
      (toKmh(gated.speed!) - 40).abs(),
      lessThan((toKmh(open.speed!) - 40).abs()),
    );
  });

  test('if no tone track passes the gate all of them are kept', () {
    // Lane distance 40 % off: the distance check of 5.5 must still see the
    // estimate (class B "Abstandsprüfung" with d_est), not "kein Ton".
    final rec = Scenarios.render(
      VehiclePass(
        speed: fromKmh(40),
        distance: 5,
        t0: 4,
        noiseRms: 0.15,
        tones: engine,
      ),
      durationS: 8,
    );
    final truth = rec.truths.single;
    final result =
        DopplerEstimator(
          config: config,
          speedOfSound: truth.speedOfSound,
        ).estimate(
          rec.signal,
          windowStartS: 0,
          receptionT0: truth.receptionT0,
          directionCosine: truth.model.directionCosine,
          gate: ToneGate(kappa: truth.kappa, laneDistance: 7),
        );
    expect(result.hasTone, isTrue);
    expect(toKmh(result.speed!), closeTo(40, 1.5));
  });
}

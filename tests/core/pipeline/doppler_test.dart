import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/pipeline/doppler.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

const engine = [
  ToneSpec(800, 0.05),
  ToneSpec(1600, 0.03),
  ToneSpec(2400, 0.02),
];

({SimulatedRecording rec, DopplerResult result}) run(
  VehiclePass pass, {
  double snrDb = 30,
}) {
  final rec = Scenarios.render(pass, durationS: 8, snrDb: snrDb);
  final truth = rec.truths.single;
  final model = truth.model; // u(t) of the noise source, as from the TDOA fit
  final result =
      DopplerEstimator(
        config: config,
        speedOfSound: truth.speedOfSound,
      ).estimate(
        rec.signal,
        windowStartS: 0,
        receptionT0: truth.receptionT0,
        directionCosine: model.directionCosine,
      );
  return (rec: rec, result: result);
}

VehiclePass car(double kmh, double d, int direction, {double lead = 0}) =>
    VehiclePass(
      speed: direction * fromKmh(kmh),
      distance: d,
      t0: 4,
      noiseRms: 0.15,
      tones: engine,
      toneLeadS: lead,
    );

void main() {
  test('one engine tone with harmonics: v_D within 1.5 km/h', () {
    for (final (kmh, d) in [(30.0, 5.0), (50.0, 4.0)]) {
      for (final direction in [1, -1]) {
        final r = run(car(kmh, d, direction)).result;
        expect(r.hasTone, isTrue, reason: '$kmh $d $direction');
        expect(
          toKmh(r.speed!),
          closeTo(kmh, 1.5),
          reason: '$kmh $d $direction',
        );
        expect(r.toneCount, greaterThanOrEqualTo(2));
        expect(r.sigma, greaterThan(0));
      }
    }
  });

  test('more tones give a smaller sigma than one tone', () {
    final many = run(car(40, 5, 1)).result;
    final one = run(
      VehiclePass(
        speed: fromKmh(40),
        distance: 5,
        t0: 4,
        noiseRms: 0.15,
        tones: const [ToneSpec(800, 0.05)],
      ),
    ).result;
    expect(one.toneCount, 1);
    expect(many.toneCount, greaterThan(one.toneCount));
    expect(many.sigma!, lessThan(one.sigma!));
  });

  test('a tone source 0.2 s ahead is found and v_D stays in tolerance', () {
    final r = run(car(40, 5, 1, lead: 0.2)).result;
    expect(r.offsetS, closeTo(0.2, 0.051));
    expect(toKmh(r.speed!), closeTo(40, 1.5));
  });

  test('no tone gives no estimate', () {
    final r = run(Scenarios.electric(speedKmh: 40, distance: 5)).result;
    expect(r.hasTone, isFalse);
    expect(r.speed, isNull);
    expect(r.toneCount, 0);
  });

  group('track selection', () {
    ToneTrack track(double start, double end) => ToneTrack([
      for (var t = start; t <= end + 1e-9; t += 0.01) (t: t, f: 1000.0),
    ]);

    test('tracks shorter than 0.5 s are dropped', () {
      final kept = selectTracks(
        [track(3.8, 4.2)],
        receptionT0: 4,
        config: config,
      );
      expect(kept, isEmpty);
    });

    test('tracks not covering t0 are dropped', () {
      final kept = selectTracks(
        [track(1, 3.5)],
        receptionT0: 4,
        config: config,
      );
      expect(kept, isEmpty);
    });

    test('long tracks over t0 are kept', () {
      final kept = selectTracks([track(3, 5)], receptionT0: 4, config: config);
      expect(kept, hasLength(1));
    });
  });
}

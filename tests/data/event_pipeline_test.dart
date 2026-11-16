import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/events/event_detector.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/event_evaluator.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/data/event_pipeline.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

PassRecord evaluate(VehiclePass pass, {double laneDistance = 5}) {
  final sim = Scenarios.setup(backgroundRms: 0.002);
  final rec = PassBySimulator(sim).render(12, [pass]);
  final setup = AnalysisSetup(
    micSpacing: sim.micSpacing,
    channelOffset: 0,
    swapChannels: false,
    speedOfSound: sim.speedOfSound,
    speedLimitKmh: 50,
    startedAtUtcMs: 0,
    lanes: [
      LaneGeometry(index: 0, direction: 1, slantDistance: laneDistance),
      LaneGeometry(index: 1, direction: -1, slantDistance: laneDistance),
    ],
  );
  final event = detectEvents(rec.signal, config: config).single;
  final from = (event.windowStartS * 48000).round() / 48000;
  return EventPipeline(
    config: config,
    setup: setup,
  ).evaluate(windowOf(rec.signal, event, 48000), event, windowStartS: from);
}

void main() {
  test('a combustion car gets a Doppler speed and tone count', () {
    final r = evaluate(
      Scenarios.combustion(
        speedKmh: 40,
        distance: 5,
        t0: 6,
        fundamentalHz: 200,
      ),
    );
    expect(r.vDoppler, closeTo(40, 1.5));
    expect(r.sigmaDoppler, greaterThan(0));
    expect(r.nToene, greaterThanOrEqualTo(1));
    expect(r.vLaufzeit, closeTo(40, 1.5));
  });

  test('an electric car without warning tone has empty Doppler fields', () {
    final r = evaluate(Scenarios.electric(speedKmh: 40, distance: 5, t0: 6));
    expect(r.vDoppler, isNull);
    expect(r.sigmaDoppler, isNull);
    expect(r.nToene, 0);
    expect(r.klasse, isNot(QualityClass.c));
  });

  test('constant drive with tone and 0.4 m lateral offset is class A', () {
    final r = evaluate(
      Scenarios.combustion(speedKmh: 40, distance: 5.4, t0: 6),
      laneDistance: 5,
    );
    expect(r.klasse, QualityClass.a, reason: r.grund);
    expect(r.reason, isNull);
    expect((r.v! - 40).abs(), lessThan((r.vLaufzeit! - 40).abs()));
    expect(r.dEst, closeTo(5.4, 0.3));
    expect(r.sigmaV, lessThan(r.sigmaLaufzeit!));
  });

  test('acceleration of 0.5 m/s² rejects the Doppler estimate', () {
    final r = evaluate(
      Scenarios.combustion(speedKmh: 30, distance: 5, t0: 6, acceleration: 0.5),
    );
    expect(r.klasse, QualityClass.b);
    expect(r.reason, DowngradeReason.acceleration);
    expect(r.v, r.vLaufzeit);
  });

  test('a lane distance 40 % off fails the distance check', () {
    final r = evaluate(
      Scenarios.combustion(speedKmh: 40, distance: 5, t0: 6),
      laneDistance: 7,
    );
    expect(r.klasse, QualityClass.b);
    expect(r.reason, DowngradeReason.distanceCheck);
    expect(r.dEst, closeTo(5, 0.3));
  });

  test('an electric car without tone is class B "kein Ton"', () {
    final r = evaluate(Scenarios.electric(speedKmh: 40, distance: 5, t0: 6));
    expect(r.klasse, QualityClass.b);
    expect(r.reason, DowngradeReason.noTone);
    expect(r.grund, 'kein Ton');
  });

  test('a weak tone reaches class A through Doppler variant 2', () {
    final watch = Stopwatch()..start();
    final r = evaluate(
      VehiclePass(
        speed: 40 / 3.6,
        distance: 5,
        t0: 6,
        noiseRms: 0.15,
        tones: const [ToneSpec(1800, 0.015)],
      ),
    );
    // ignore: avoid_print
    print('Event with variant 2: ${watch.elapsedMilliseconds} ms');
    expect(r.klasse, QualityClass.a, reason: r.grund);
    expect(r.vDoppler, closeTo(40, 2));
    expect(r.nToene, 0); // variant 2 has no tone tracks
  });
}

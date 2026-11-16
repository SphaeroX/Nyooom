import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/events/event_detector.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/event_evaluator.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

const config = NyooomConfig();
const nearLane = 4.1, farLane = 7.3;

AnalysisSetup setupFor(SimulationSetup sim) => AnalysisSetup(
  micSpacing: sim.micSpacing,
  channelOffset: sim.channelOffset,
  swapChannels: false,
  speedOfSound: sim.speedOfSound,
  speedLimitKmh: 50,
  startedAtUtcMs: 1700000000000,
  lanes: const [
    LaneGeometry(index: 0, direction: 1, slantDistance: nearLane),
    LaneGeometry(index: 1, direction: -1, slantDistance: farLane),
  ],
);

VehiclePass spanned(VehiclePass p, int seed) => VehiclePass(
  kind: p.kind,
  speed: p.speed,
  distance: p.distance,
  t0: p.t0,
  acceleration: p.acceleration,
  noiseRms: p.noiseRms,
  tones: p.tones,
  noiseSeed: seed,
  audibleSpanS: 9,
);

void main() {
  test('several passes at known speeds on two lanes', () {
    final speeds = [20.0, 35.0, 60.0, 45.0, 28.0, 52.0];
    final passes = <VehiclePass>[];
    for (var i = 0; i < speeds.length; i++) {
      final direction = i.isEven ? 1 : -1;
      final p = i % 3 == 0
          ? Scenarios.electric(
              speedKmh: speeds[i],
              distance: direction > 0 ? nearLane : farLane,
              direction: direction,
              t0: 6 + 11.0 * i,
            )
          : Scenarios.combustion(
              speedKmh: speeds[i],
              distance: direction > 0 ? nearLane : farLane,
              direction: direction,
              t0: 6 + 11.0 * i,
            );
      passes.add(spanned(p, i));
    }
    final sim = Scenarios.setup(backgroundRms: 0.002);
    final rec = PassBySimulator(sim).render(6 + 11.0 * speeds.length, passes);
    final records = evaluateSignal(
      rec.signal,
      config: config,
      setup: setupFor(sim),
    );
    expect(records, hasLength(speeds.length));
    for (var i = 0; i < speeds.length; i++) {
      final r = records[i];
      final direction = i.isEven ? 1 : -1;
      expect(r.klasse, QualityClass.b, reason: 'pass $i: ${r.grund}');
      expect(r.richtung, direction);
      expect(r.laneIndex, direction > 0 ? 0 : 1);
      expect(r.vLaufzeit, closeTo(speeds[i], 1), reason: 'pass $i');
      expect(r.v, r.vLaufzeit);
      expect(r.vDoppler, isNull);
      expect(r.dEst, isNull);
      expect(r.offsetS, closeTo(6 + 11.0 * i, 0.02));
      expect(r.zeitUtcMs, closeTo(1700000000000 + (6 + 11.0 * i) * 1000, 20));
      expect(r.restLaufzeitUs, lessThan(30));
      expect(r.pegel, greaterThan(10));
    }
  });

  test('a lateral offset of 0.4 m is covered by sigma_T', () {
    final sim = Scenarios.setup(backgroundRms: 0.002);
    final truthDistance = nearLane + 0.4;
    final pass = spanned(
      Scenarios.electric(speedKmh: 40, distance: truthDistance, t0: 6),
      1,
    );
    final rec = PassBySimulator(sim).render(12, [pass]);
    final r = evaluateSignal(
      rec.signal,
      config: config,
      setup: setupFor(sim),
    ).single;
    // κ is right, the assumed lane distance is 0.4 m short: v_T too small
    // by about 0.4/4.1 (technik.pdf 6.1/6.2).
    final error = r.vLaufzeit! - 40;
    expect(error / 40, closeTo(-0.4 / truthDistance, 0.02));
    expect(error.abs(), lessThan(1.2 * r.sigmaV!));
  });

  test('overlap, clipping and pure noise give class C with a reason', () {
    final sim = Scenarios.setup(backgroundRms: 0.002);
    final overlapRec = PassBySimulator(sim).render(16, [
      spanned(
        Scenarios.combustion(speedKmh: 50, distance: nearLane, t0: 7.5),
        1,
      ),
      spanned(
        Scenarios.combustion(
          speedKmh: 50,
          distance: farLane,
          t0: 8.5,
          direction: -1,
          noiseRms: 0.3,
        ),
        2,
      ),
    ]);
    final overlap = evaluateSignal(
      overlapRec.signal,
      config: config,
      setup: setupFor(sim),
    );
    expect(overlap.single.klasse, QualityClass.c);
    expect(overlap.single.reason, DowngradeReason.overlap);

    final loud = PassBySimulator(sim).render(12, [
      spanned(
        Scenarios.combustion(
          speedKmh: 40,
          distance: nearLane,
          t0: 6,
          noiseRms: 6,
        ),
        3,
      ),
    ]);
    final clipped = evaluateSignal(
      loud.signal,
      config: config,
      setup: setupFor(sim),
    );
    expect(clipped.single.klasse, QualityClass.c);
    expect(clipped.single.reason, DowngradeReason.clipping);

    final random = math.Random(1);
    final n = 8 * 48000;
    final noise = StereoBlock(
      Float64List.fromList(
        List.generate(n, (_) => 0.1 * (random.nextDouble() - .5)),
      ),
      Float64List.fromList(
        List.generate(n, (_) => 0.1 * (random.nextDouble() - .5)),
      ),
    );
    final record = EventEvaluator(config: config, setup: setupFor(sim))
        .evaluate(
          noise,
          const PassEvent(
            peakTimeS: 4,
            peakLevelDb: -20,
            floorDb: -35,
            durationS: 1,
            windowStartS: 0,
            windowEndS: 8,
            overlap: false,
            truncated: false,
          ),
          windowStartS: 0,
        );
    expect(record.klasse, QualityClass.c);
    expect(record.reason!.isClassC, isTrue);
    expect(record.v, isNull);
  });

  test('swapped channels are corrected before the evaluation', () {
    final sim = Scenarios.setup(backgroundRms: 0.002);
    final rec = PassBySimulator(sim).render(12, [
      spanned(Scenarios.electric(speedKmh: 30, distance: nearLane, t0: 6), 1),
    ]);
    final setup = setupFor(sim);
    final swappedSetup = AnalysisSetup(
      micSpacing: setup.micSpacing,
      channelOffset: setup.channelOffset,
      swapChannels: true,
      speedOfSound: setup.speedOfSound,
      speedLimitKmh: setup.speedLimitKmh,
      startedAtUtcMs: setup.startedAtUtcMs,
      lanes: setup.lanes,
    );
    final r = evaluateSignal(
      rec.signal.swapped,
      config: config,
      setup: swappedSetup,
    ).single;
    expect(r.richtung, 1);
    expect(r.vLaufzeit, closeTo(30, 1));
  });

  test('sigma_T follows technik.pdf 5.5', () {
    final s = laufzeitSigma(
      speed: fromKmh(30),
      kappa: 1.667,
      sigmaKappa: 0.05,
      laneDistance: 5,
      lateralSpread: 0.4,
    );
    final expected =
        fromKmh(30) * math.sqrt(math.pow(0.05 / 1.667, 2) + math.pow(0.08, 2));
    expect(s, closeTo(expected, 1e-12));
  });
}

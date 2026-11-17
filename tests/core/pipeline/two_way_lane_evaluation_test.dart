import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/event_evaluator.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

void main() {
  const config = NyooomConfig();
  const lane = 4.1;

  test('laneFor returns a two-way lane for both directions', () {
    const setup = AnalysisSetup(
      micSpacing: 0.15,
      channelOffset: 0,
      swapChannels: false,
      speedOfSound: 343,
      speedLimitKmh: 30,
      startedAtUtcMs: 0,
      lanes: [LaneGeometry(index: 0, direction: 0, slantDistance: lane)],
    );
    expect(setup.laneFor(1)!.index, 0);
    expect(setup.laneFor(-1)!.index, 0);
  });

  test('passes in both directions on a two-way lane get a speed', () {
    final sim = Scenarios.setup(backgroundRms: 0.002);
    VehiclePass pass(double kmh, int direction, double t0, int seed) {
      final p = Scenarios.combustion(
        speedKmh: kmh,
        distance: lane,
        direction: direction,
        t0: t0,
      );
      return VehiclePass(
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
    }

    final rec = PassBySimulator(sim)
        .render(28, [pass(30, 1, 6, 1), pass(25, -1, 17, 2)]);
    final records = evaluateSignal(
      rec.signal,
      config: config,
      setup: AnalysisSetup(
        micSpacing: sim.micSpacing,
        channelOffset: sim.channelOffset,
        swapChannels: false,
        speedOfSound: sim.speedOfSound,
        speedLimitKmh: 30,
        startedAtUtcMs: 1700000000000,
        lanes: const [
          LaneGeometry(index: 0, direction: 0, slantDistance: lane),
        ],
      ),
    );
    expect(records, hasLength(2));
    expect(records.map((r) => r.richtung), [1, -1]);
    for (final r in records) {
      expect(r.klasse, isNot(QualityClass.c), reason: r.grund);
      expect(r.laneIndex, 0);
    }
    expect(records[0].vLaufzeit, closeTo(30, 1));
    expect(records[1].vLaufzeit, closeTo(25, 1));
  });
}

import 'dart:math' as math;

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/reference/reference_track.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/core/validation/validation.dart';
import 'package:nyooom/data/live_pipeline.dart';
import 'package:test/test.dart';

const config = NyooomConfig();
const siteLat = 50.0, siteLon = 8.0;

/// GPS track of a simulated vehicle: the road runs east (+x = bearing 90°),
/// the lane lies [lateral] m north of the phone.
ReferenceTrack gpsFor(GroundTruth t, int startedAtUtcMs, double lateral) {
  final mLon = 111195.0 * math.cos(siteLat * math.pi / 180);
  return ReferenceTrack(
    name: 'sim',
    source: ReferenceSource.logger,
    points: [
      for (var s = -15; s <= 15; s++)
        ReferencePoint(
          timeUtcMs: startedAtUtcMs + ((t.t0 + s) * 1000).round(),
          lat: siteLat + lateral / 111195.0,
          lon: siteLon + t.speed * s / mLon,
          speed: t.speed.abs(),
        ),
    ],
  );
}

void main() {
  test('simulated series against synthetic GPS references passes 8', () {
    const startedAt = 1763300000000;
    final sim = Scenarios.setup(backgroundRms: 0.002);
    final passes = <VehiclePass>[];
    final speeds = [20.0, 30.0, 40.0, 50.0, 30.0, 40.0];
    for (var i = 0; i < speeds.length; i++) {
      final direction = i.isEven ? 1 : -1;
      final p = Scenarios.combustion(
        speedKmh: speeds[i],
        distance: direction > 0 ? 4.1 : 7.3,
        direction: direction,
        t0: 7 + 12.0 * i,
      );
      passes.add(
        VehiclePass(
          kind: p.kind,
          speed: p.speed,
          distance: p.distance,
          t0: p.t0,
          noiseRms: p.noiseRms,
          tones: p.tones,
          noiseSeed: i,
          audibleSpanS: 9,
        ),
      );
    }
    final rec = PassBySimulator(sim).render(7 + 12.0 * speeds.length, passes);
    final setup = AnalysisSetup(
      micSpacing: sim.micSpacing,
      channelOffset: 0,
      swapChannels: false,
      speedOfSound: sim.speedOfSound,
      speedLimitKmh: 50,
      startedAtUtcMs: startedAt,
      lanes: const [
        LaneGeometry(index: 0, direction: 1, slantDistance: 4.1),
        LaneGeometry(index: 1, direction: -1, slantDistance: 7.3),
      ],
    );
    final records = evaluateSignalFull(
      rec.signal,
      config: config,
      setup: setup,
    );

    final references = <ReferencePassage>[
      for (final t in rec.truths)
        ...closestApproaches(
          gpsFor(t, startedAt, t.direction > 0 ? 4 : 7.2),
          siteLat: siteLat,
          siteLon: siteLon,
          config: config,
        ),
    ];
    final match = matchReferences(references, records, config: config);
    expect(match.matches, hasLength(speeds.length));
    final report = ValidationReport.from(
      match.matches,
      config: config,
      plusXBearingDeg: 90,
    );
    expect(report.directionShare, 1);
    expect(report.all.meanError!.abs(), lessThan(1));
    final results = {
      for (final a in report.acceptance(config)) a.criterion: a.passed,
    };
    expect(results[AcceptanceCriterion.meanError], isTrue);
    expect(results[AcceptanceCriterion.direction], isTrue);
    expect(results[AcceptanceCriterion.shareC], isTrue);
  });
}

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/events/event_detector.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/data/live_pipeline.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

AnalysisSetup setupFor(SimulationSetup sim) => AnalysisSetup(
  micSpacing: sim.micSpacing,
  channelOffset: 0,
  swapChannels: false,
  speedOfSound: sim.speedOfSound,
  speedLimitKmh: 50,
  startedAtUtcMs: 0,
  lanes: const [
    LaneGeometry(index: 0, direction: 1, slantDistance: 4.1),
    LaneGeometry(index: 1, direction: -1, slantDistance: 7.3),
  ],
);

VehiclePass spanned(VehiclePass p, int seed) => VehiclePass(
  kind: p.kind,
  speed: p.speed,
  distance: p.distance,
  t0: p.t0,
  noiseRms: p.noiseRms,
  tones: p.tones,
  noiseSeed: seed,
  audibleSpanS: 9,
);

Future<List<PassRecord>> feedLive(
  StereoBlock signal,
  LivePipeline live, {
  int seed = 1,
}) async {
  final records = <PassRecord>[];
  final sub = live.records.listen(records.add);
  final random = math.Random(seed);
  var i = 0;
  while (i < signal.length) {
    final n = math.min(signal.length - i, 500 + random.nextInt(4000));
    live.add(
      StereoBlock(
        Float64List.sublistView(signal.left, i, i + n),
        Float64List.sublistView(signal.right, i, i + n),
      ),
    );
    i += n;
    await Future<void>.delayed(Duration.zero);
  }
  await live.finish();
  await sub.cancel();
  return records;
}

void main() {
  test(
    'live results equal the offline evaluation of the same signal',
    () async {
      final sim = Scenarios.setup(backgroundRms: 0.002);
      final rec = PassBySimulator(sim).render(36, [
        spanned(Scenarios.combustion(speedKmh: 35, distance: 4.1, t0: 6), 1),
        spanned(
          Scenarios.electric(
            speedKmh: 45,
            distance: 7.3,
            t0: 17,
            direction: -1,
          ),
          2,
        ),
        spanned(Scenarios.combustion(speedKmh: 50, distance: 4.1, t0: 28), 3),
      ]);
      final setup = setupFor(sim);
      final offline = evaluateSignalFull(
        rec.signal,
        config: config,
        setup: setup,
      );
      final live = LivePipeline(config: config, setup: setup);
      final online = await feedLive(rec.signal, live);
      expect(online.map((r) => r.toJson()), offline.map((r) => r.toJson()));
      expect(online, hasLength(3));
      expect(live.dropped, 0);
    },
  );

  test(
    'events at the start and the end are evaluated without errors',
    () async {
      final sim = Scenarios.setup(backgroundRms: 0.002);
      final rec = PassBySimulator(sim).render(10, [
        spanned(Scenarios.combustion(speedKmh: 40, distance: 4.1, t0: 1.2), 1),
        spanned(
          Scenarios.combustion(
            speedKmh: 40,
            distance: 7.3,
            t0: 8.8,
            direction: -1,
          ),
          2,
        ),
      ]);
      final online = await feedLive(
        rec.signal,
        LivePipeline(config: config, setup: setupFor(sim)),
      );
      expect(online, hasLength(2));
    },
  );

  test('a full queue drops events and counts them', () async {
    final release = Completer<void>();
    var started = 0;
    final live = LivePipeline(
      config: config,
      setup: setupFor(Scenarios.setup()),
      maxPending: 2,
      evaluator: (window, event, startS) async {
        started++;
        await release.future;
        return PassRecord(
          zeitUtcMs: 0,
          offsetS: event.peakTimeS,
          richtung: 1,
          klasse: QualityClass.c,
          v: null,
          sigmaV: null,
          vLaufzeit: null,
          vDoppler: null,
          kappa: null,
          dEst: null,
          nToene: 0,
          restLaufzeitUs: null,
          pegel: 20,
          dauer: 1,
          reason: null,
          laneIndex: null,
          distanceUsedM: null,
        );
      },
    );
    PassEvent event(double t) => PassEvent(
      peakTimeS: t,
      peakLevelDb: -20,
      floorDb: -40,
      durationS: 1,
      windowStartS: t - 4,
      windowEndS: t + 4,
      overlap: false,
      truncated: false,
    );
    live.add(StereoBlock(Float64List(48000 * 12), Float64List(48000 * 12)));
    for (final t in [5.0, 6.0, 7.0, 8.0]) {
      live.submit(event(t));
    }
    expect(started, 1);
    expect(live.pending, 2);
    expect(live.dropped, 2);
    release.complete();
    await live.finish();
    expect(live.pending, 0);
  });
}

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/core/sim/traffic.dart';
import 'package:nyooom/data/live_pipeline.dart';
import 'package:test/test.dart';

const config = NyooomConfig();
const nearLane = 4.1, farLane = 7.3;

// Speed tolerance for vehicles that share a window. technik.pdf 1 aims at
// ±3 to 5 km/h (1 σ) for TDOA-only results including the unknown lateral
// position; here the lane distance is exact, so 2.5 km/h must hold.
const toleranceKmh = 2.5;

VehiclePass spanned(VehiclePass p, int seed) => VehiclePass(
  kind: p.kind,
  speed: p.speed,
  distance: p.distance,
  t0: p.t0,
  acceleration: p.acceleration,
  noiseRms: p.noiseRms,
  tones: p.tones,
  toneLeadS: p.toneLeadS,
  noiseSeed: seed,
  audibleSpanS: 9,
);

AnalysisSetup setupFor(SimulationSetup sim) => AnalysisSetup(
  micSpacing: sim.micSpacing,
  channelOffset: 0,
  swapChannels: false,
  speedOfSound: sim.speedOfSound,
  speedLimitKmh: 50,
  startedAtUtcMs: 0,
  lanes: const [
    LaneGeometry(index: 0, direction: 1, slantDistance: nearLane),
    LaneGeometry(index: 1, direction: -1, slantDistance: farLane),
  ],
);

({SimulatedRecording rec, List<PassRecord> records}) evaluate(
  List<VehiclePass> passes, {
  double durationS = 20,
}) {
  final sim = Scenarios.setup(backgroundRms: 0.002);
  final rec = PassBySimulator(sim).render(durationS, [
    for (var i = 0; i < passes.length; i++) spanned(passes[i], i + 1),
  ]);
  final records = evaluateSignalFull(
    rec.signal,
    config: config,
    setup: setupFor(sim),
  )..sort((a, b) => a.offsetS.compareTo(b.offsetS));
  return (rec: rec, records: records);
}

/// Every vehicle has exactly one valid record with the right direction and
/// speed; nothing else is reported.
void expectAllMeasured(
  List<GroundTruth> truths,
  List<PassRecord> records, {
  String? why,
}) {
  expect(records, hasLength(truths.length), reason: why);
  final open = List.of(records);
  for (final truth in truths) {
    final match = open
        .where(
          (r) =>
              r.richtung == truth.direction &&
              (r.offsetS - truth.t0).abs() < 0.3,
        )
        .toList();
    expect(match, hasLength(1), reason: '$why, vehicle at ${truth.t0}');
    final r = match.single;
    open.remove(r);
    expect(r.klasse, isNot(QualityClass.c), reason: '$why: ${r.grund}');
    expect(
      r.v,
      closeTo(truth.speed.abs() * 3.6, toleranceKmh),
      reason: '$why, vehicle at ${truth.t0}',
    );
    expect(r.laneIndex, truth.direction > 0 ? 0 : 1);
  }
}

void main() {
  test('two vehicles following each other are both measured', () {
    for (final gap in [2.0, 3.0, 5.0]) {
      for (final kmh in [30.0, 50.0]) {
        final result = evaluate([
          Scenarios.combustion(speedKmh: kmh, distance: nearLane, t0: 8),
          Scenarios.electric(
            speedKmh: kmh + 3,
            distance: nearLane,
            t0: 8 + gap,
          ),
        ]);
        expectAllMeasured(
          result.rec.truths,
          result.records,
          why: 'gap $gap s at $kmh km/h',
        );
      }
    }
  });

  test('oncoming traffic is measured for both directions', () {
    for (final gap in [0.0, 0.5, 1.0, 2.0, 3.0]) {
      final result = evaluate([
        Scenarios.electric(speedKmh: 40, distance: nearLane, t0: 8),
        Scenarios.electric(
          speedKmh: 45,
          distance: farLane,
          t0: 8 + gap,
          direction: -1,
          noiseRms: 0.15,
        ),
      ]);
      expectAllMeasured(
        result.rec.truths,
        result.records,
        why: 'oncoming, $gap s apart',
      );
    }
  });

  test('a platoon of three with one oncoming car gives four records', () {
    final result = evaluate([
      Scenarios.electric(speedKmh: 42, distance: nearLane, t0: 8),
      Scenarios.combustion(speedKmh: 40, distance: nearLane, t0: 10.5),
      Scenarios.electric(
        speedKmh: 36,
        distance: farLane,
        t0: 11.5,
        direction: -1,
        noiseRms: 0.15,
      ),
      Scenarios.electric(speedKmh: 38, distance: nearLane, t0: 13.2),
    ], durationS: 24);
    expectAllMeasured(result.rec.truths, result.records, why: 'platoon');
  });

  test('tones are not assigned when two vehicles pass at the same time', () {
    final result = evaluate([
      Scenarios.combustion(speedKmh: 40, distance: nearLane, t0: 8),
      Scenarios.combustion(
        speedKmh: 44,
        distance: farLane,
        t0: 8.2,
        direction: -1,
        noiseRms: 0.3,
        fundamentalHz: 130,
      ),
    ]);
    expectAllMeasured(result.rec.truths, result.records, why: 'both with tone');
    for (final r in result.records) {
      expect(r.klasse, QualityClass.b);
      expect(r.reason, DowngradeReason.toneAmbiguous);
      expect(r.vDoppler, isNull);
      expect(r.v, r.vLaufzeit);
    }
  });

  test('a mirror image from a side wall is not counted as a vehicle', () {
    // Reflection at a wall across the road axis (window reveal): the image
    // source moves the other way with the same |κ| and the same t0.
    final result = evaluate([
      Scenarios.electric(speedKmh: 40, distance: nearLane, t0: 8),
      Scenarios.electric(
        speedKmh: 40,
        distance: nearLane,
        t0: 8,
        direction: -1,
        noiseRms: 0.04,
      ),
    ]);
    expect(result.records, hasLength(1));
    expect(result.records.single.richtung, 1);
    expect(result.records.single.v, closeTo(40, toleranceKmh));
  });

  test('random traffic with short gaps: every vehicle once, none invented', () {
    // Mean gap 8 s on two lanes (lateral spread 0.4 m, 10 % accelerating):
    // about every second vehicle shares its window with another one.
    const durationS = 50.0;
    final traffic = TrafficGenerator(
      lanes: const [
        TrafficLane(slantDistance: nearLane, direction: 1),
        TrafficLane(slantDistance: farLane, direction: -1),
      ],
      seed: 3,
      minGapS: 3,
      meanExtraGapS: 5,
    );
    final sim = Scenarios.setup(backgroundRms: 0.002, seed: 3);
    final rec = PassBySimulator(sim)
        .render(durationS, traffic.passesAffecting(0, durationS));
    final records = evaluateSignalFull(
      rec.signal,
      config: config,
      setup: setupFor(sim),
    );
    final truths = rec.truths
        .where((t) => t.t0 >= 4.5 && t.t0 <= durationS - 4.5)
        .toList();
    expect(truths.length, greaterThanOrEqualTo(5));
    final open = records
        .where((r) => r.offsetS >= 4.5 && r.offsetS <= durationS - 4.5)
        .toList();
    for (final truth in truths) {
      final match = open
          .where(
            (r) =>
                r.richtung == truth.direction &&
                (r.offsetS - truth.t0).abs() < 0.3,
          )
          .toList();
      expect(match, hasLength(1), reason: 'vehicle at ${truth.t0}');
      final r = match.single;
      open.remove(r);
      expect(r.klasse, isNot(QualityClass.c), reason: r.grund);
      // κ itself, without the error of the lateral position in the lane.
      expect(r.kappa, closeTo(truth.kappa, 0.04 * truth.kappa.abs()));
    }
    expect(open, isEmpty, reason: 'records without a vehicle');
  });

  test(
    'live results equal the offline evaluation with several vehicles',
    () async {
      final sim = Scenarios.setup(backgroundRms: 0.002);
      final rec = PassBySimulator(sim).render(24, [
        spanned(Scenarios.electric(speedKmh: 42, distance: nearLane, t0: 7), 1),
        spanned(
          Scenarios.combustion(speedKmh: 40, distance: nearLane, t0: 9.5),
          2,
        ),
        spanned(
          Scenarios.electric(
            speedKmh: 45,
            distance: farLane,
            t0: 15,
            direction: -1,
            noiseRms: 0.15,
          ),
          3,
        ),
        spanned(
          Scenarios.electric(speedKmh: 35, distance: nearLane, t0: 15.4),
          4,
        ),
      ]);
      final setup = setupFor(sim);
      final offline = evaluateSignalFull(
        rec.signal,
        config: config,
        setup: setup,
      );
      final live = LivePipeline(config: config, setup: setup, maxPending: 8);
      final online = <PassRecord>[];
      final sub = live.records.listen(online.add);
      final random = math.Random(3);
      var i = 0;
      while (i < rec.signal.length) {
        final n = math.min(rec.signal.length - i, 500 + random.nextInt(4000));
        live.add(
          StereoBlock(
            Float64List.sublistView(rec.signal.left, i, i + n),
            Float64List.sublistView(rec.signal.right, i, i + n),
          ),
        );
        i += n;
        await Future<void>.delayed(Duration.zero);
      }
      await live.finish();
      await sub.cancel();
      expect(offline, hasLength(4));
      expect(online.map((r) => r.toJson()), offline.map((r) => r.toJson()));
      expect(live.dropped, 0);
    },
  );
}

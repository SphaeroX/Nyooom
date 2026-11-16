import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/events/event_detector.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/doppler.dart';
import 'package:nyooom/core/pipeline/event_evaluator.dart';
import 'package:nyooom/core/pipeline/fusion.dart';
import 'package:nyooom/core/pipeline/joint_fit.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

class Stages {
  Stages(this.truth, this.analysis, this.doppler, this.setup, this.simple);
  final GroundTruth truth;
  final EventAnalysis analysis;
  final DopplerResult doppler;
  final AnalysisSetup setup;

  /// Speed of the simple fusion in m/s (or v_T without tone).
  final double simple;
}

Stages stages(
  VehiclePass pass, {
  double lane = 5,
  double snrDb = 30,
  int seed = 1,
}) {
  final rec = Scenarios.render(pass, durationS: 12, snrDb: snrDb, seed: seed);
  final truth = rec.truths.single;
  final setup = AnalysisSetup(
    micSpacing: truth.micSpacing,
    channelOffset: 0,
    swapChannels: false,
    speedOfSound: truth.speedOfSound,
    speedLimitKmh: 50,
    startedAtUtcMs: 0,
    lanes: [
      LaneGeometry(index: 0, direction: 1, slantDistance: lane),
      LaneGeometry(index: 1, direction: -1, slantDistance: lane),
    ],
  );
  final event = detectEvents(rec.signal, config: config).single;
  final from = (event.windowStartS * 48000).round() / 48000;
  final analysis = EventEvaluator(
    config: config,
    setup: setup,
  ).analyse(windowOf(rec.signal, event, 48000), event, windowStartS: from);
  final fit = analysis.fit!;
  final doppler =
      DopplerEstimator(
        config: config,
        speedOfSound: setup.speedOfSound,
      ).estimate(
        analysis.signal,
        windowStartS: from,
        receptionT0: fit.t0 + lane / setup.speedOfSound,
        directionCosine: (t) =>
            (analysis.fitter!.tdoaAt(t, kappa: fit.kappa, t0: fit.t0)) /
            setup.maxTdoa,
      );
  var simple = fromKmh(analysis.record.vLaufzeit!);
  if (doppler.hasTone) {
    simple = fuse(
      config: config,
      vT: simple,
      sigmaT: fromKmh(analysis.record.sigmaLaufzeit!),
      kappa: fit.kappa,
      laneDistance: lane,
      vD: doppler.speed,
      sigmaD: doppler.sigma,
    ).v;
  }
  return Stages(truth, analysis, doppler, setup, simple);
}

JointResult? joint(Stages s, {double? startSpeed, double? startT0}) => jointFit(
  analysis: s.analysis,
  doppler: s.doppler,
  setup: s.setup,
  config: config,
  startSpeed: startSpeed ?? s.simple,
  startT0: startT0,
);

void main() {
  test('finds v, d and t0 and is not worse than the simple fusion', () {
    var simpleErr = 0.0, jointErr = 0.0, n = 0;
    for (final (kmh, d, lane) in [
      (30.0, 5.4, 5.0),
      (50.0, 4.0, 4.0),
      (40.0, 4.6, 5.0),
      (35.0, 6.4, 6.0),
    ]) {
      for (final direction in [1, -1]) {
        final s = stages(
          Scenarios.combustion(
            speedKmh: kmh,
            distance: d,
            direction: direction,
            t0: 6,
          ),
          lane: lane,
        );
        final j = joint(s)!;
        final why = '$kmh km/h, d $d, lane $lane, dir $direction';
        expect(j.speed.sign, direction, reason: why);
        expect(toKmh(j.speed.abs()), closeTo(kmh, 1.5), reason: why);
        expect(j.distance, closeTo(d, 0.3), reason: why);
        expect(j.t0, closeTo(s.truth.t0, 0.02), reason: why);
        simpleErr += (toKmh(s.simple) - kmh).abs();
        jointErr += (toKmh(j.speed.abs()) - kmh).abs();
        n++;
      }
    }
    // ignore: avoid_print
    print(
      'mean |error| simple fusion ${(simpleErr / n).toStringAsFixed(2)} km/h, '
      'joint fit ${(jointErr / n).toStringAsFixed(2)} km/h ($n passes)',
    );
    expect(jointErr / n, lessThanOrEqualTo(simpleErr / n + 0.3));
  });

  test('without tone there is no joint result (TDOA result stays)', () {
    final s = stages(Scenarios.electric(speedKmh: 40, distance: 5, t0: 6));
    expect(s.doppler.hasTone, isFalse);
    expect(joint(s), isNull);
  });

  test('converges from 20 % wrong v and 0.2 s wrong t0', () {
    final s = stages(Scenarios.combustion(speedKmh: 40, distance: 5, t0: 6));
    for (final (f, dt) in [(1.2, 0.2), (0.8, -0.2)]) {
      final j = joint(
        s,
        startSpeed: fromKmh(40) * f,
        startT0: s.truth.t0 + dt,
      )!;
      expect(
        toKmh(j.speed.abs()),
        closeTo(40, 1.5),
        reason: 'start ×$f, $dt s',
      );
      expect(j.t0, closeTo(s.truth.t0, 0.02));
    }
  });

  test('sigma of v is smaller with better SNR', () {
    final pass = Scenarios.combustion(speedKmh: 40, distance: 5, t0: 6);
    final good = joint(stages(pass, snrDb: 30))!;
    // Still above the 10-dB event threshold, but much noisier.
    final bad = joint(stages(pass, snrDb: 13, seed: 2))!;
    expect(bad.sigmaSpeed, greaterThan(good.sigmaSpeed));
  });
}

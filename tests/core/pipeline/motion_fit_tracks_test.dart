import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/dsp/gcc_phat.dart';
import 'package:nyooom/core/pipeline/motion_fit.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

const config = NyooomConfig();
const nearLane = 4.1, farLane = 7.3;

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

class Scene {
  Scene(List<VehiclePass> passes, {double durationS = 16})
    : sim = Scenarios.setup(backgroundRms: 0.002) {
    rec = PassBySimulator(sim).render(durationS, [
      for (var i = 0; i < passes.length; i++) spanned(passes[i], i + 1),
    ]);
  }

  final SimulationSetup sim;
  late final SimulatedRecording rec;

  /// Correlogram of the window ±4 s around [centreS].
  ({Correlogram correlogram, double startS}) window(double centreS) {
    final from = ((centreS - 4) * 48000).round();
    final to = ((centreS + 4) * 48000).round();
    final c = GccPhat(
      config: config,
      micSpacing: sim.micSpacing,
      speedOfSound: sim.speedOfSound,
    ).correlogram(rec.signal, from: from, to: to);
    return (correlogram: c, startS: from / 48000);
  }

  MotionFitter get fitter => MotionFitter(
    config: config,
    maxTdoa: sim.micSpacing / sim.speedOfSound,
    channelOffset: 0,
    speedOfSound: sim.speedOfSound,
    laneDistance: (direction) => direction > 0 ? nearLane : farLane,
  );
}

void main() {
  test('a louder vehicle 5 s earlier does not spoil the quieter one', () {
    // Before the track separation the block maxima of the louder vehicle
    // counted as "strong blocks off the curve": class C, "nicht monoton".
    final scene = Scene([
      Scenarios.combustion(speedKmh: 30, distance: nearLane, t0: 5),
      Scenarios.electric(speedKmh: 32, distance: nearLane, t0: 10),
    ]);
    final truth = scene.rec.truths[1];
    final w = scene.window(truth.receptionT0);
    final fit = scene.fitter.fit(
      w.correlogram,
      timeOffsetS: w.startS,
      peakTimeS: truth.receptionT0,
    );
    expect(fit.reason, isNull);
    expect(fit.kappa, closeTo(truth.kappa, 0.03 * truth.kappa));
    expect(fit.t0, closeTo(truth.t0, 0.03));
    expect(fit.strength, greaterThan(0.5));
  });

  test('two vehicles 2 s apart are both fitted with bounded t0', () {
    final scene = Scene([
      Scenarios.electric(speedKmh: 50, distance: nearLane, t0: 7),
      Scenarios.combustion(speedKmh: 46, distance: nearLane, t0: 9),
    ]);
    final first = scene.rec.truths[0], second = scene.rec.truths[1];
    final middle = 0.5 * (first.receptionT0 + second.receptionT0);
    final w1 = scene.window(first.receptionT0);
    final fit1 = scene.fitter.fit(
      w1.correlogram,
      timeOffsetS: w1.startS,
      peakTimeS: first.receptionT0,
      t0MaxS: middle,
    );
    final w2 = scene.window(second.receptionT0);
    final fit2 = scene.fitter.fit(
      w2.correlogram,
      timeOffsetS: w2.startS,
      peakTimeS: second.receptionT0,
      t0MinS: middle,
    );
    expect(fit1.reason, isNull);
    expect(fit2.reason, isNull);
    expect(fit1.kappa, closeTo(first.kappa, 0.04 * first.kappa));
    expect(fit2.kappa, closeTo(second.kappa, 0.04 * second.kappa));
    expect(fit1.t0, closeTo(first.t0, 0.05));
    expect(fit2.t0, closeTo(second.t0, 0.05));
  });

  test('oncoming traffic at the same time: the second track is found when '
      'the first one is left out', () {
    final scene = Scene([
      Scenarios.combustion(speedKmh: 40, distance: nearLane, t0: 8),
      Scenarios.electric(
        speedKmh: 45,
        distance: farLane,
        t0: 8.3,
        direction: -1,
        noiseRms: 0.15,
      ),
    ]);
    final near = scene.rec.truths[0], far = scene.rec.truths[1];
    final w = scene.window(near.receptionT0);
    final fitter = scene.fitter;
    final first = fitter.fit(
      w.correlogram,
      timeOffsetS: w.startS,
      peakTimeS: near.receptionT0,
    );
    expect(first.reason, isNull);
    expect(first.direction, 1);
    expect(first.kappa, closeTo(near.kappa, 0.04 * near.kappa));

    final second = fitter.fit(
      w.correlogram,
      timeOffsetS: w.startS,
      peakTimeS: near.receptionT0,
      direction: -first.direction,
      exclude: [first.curve],
    );
    expect(second.reason, isNull);
    expect(second.direction, -1);
    expect(second.kappa, closeTo(far.kappa, 0.05 * far.kappa.abs()));
    expect(second.t0, closeTo(far.t0, 0.05));
  });

  test('a single vehicle has no second track in the opposite direction', () {
    for (final pass in [
      Scenarios.combustion(speedKmh: 30, distance: nearLane, t0: 8),
      Scenarios.electric(speedKmh: 55, distance: nearLane, t0: 8),
      Scenarios.combustion(
        speedKmh: 45,
        distance: farLane,
        t0: 8,
        direction: -1,
      ),
    ]) {
      final scene = Scene([pass]);
      final truth = scene.rec.truths.single;
      final w = scene.window(truth.receptionT0);
      final first = scene.fitter.fit(
        w.correlogram,
        timeOffsetS: w.startS,
        peakTimeS: truth.receptionT0,
      );
      expect(first.reason, isNull);
      final second = scene.fitter.fit(
        w.correlogram,
        timeOffsetS: w.startS,
        peakTimeS: truth.receptionT0,
        direction: -first.direction,
        exclude: [first.curve],
      );
      expect(second.reason, isNotNull, reason: 'strength ${second.strength}');
      expect(second.strength, lessThan(config.trackMinStrength));
    }
  });

  test('a source at a fixed direction is not a vehicle track', () {
    // Same noise in both channels, the left one delayed by 150 µs: a
    // horizontal line in the correlogram (e.g. a machine next to the road).
    final random = math.Random(11);
    final n = 8 * 48000;
    const shift = 7; // samples ≈ 146 µs
    final source = Float64List.fromList(
      List.generate(n + shift, (_) => 0.2 * (random.nextDouble() - 0.5)),
    );
    final signal = StereoBlock(
      Float64List.sublistView(source, 0, n),
      Float64List.sublistView(source, shift, n + shift),
    );
    final corr = GccPhat(
      config: config,
      micSpacing: 0.15,
      speedOfSound: 343,
    ).correlogram(signal);
    final fit = MotionFitter(
      config: config,
      maxTdoa: 0.15 / 343,
      channelOffset: 0,
      speedOfSound: 343,
      laneDistance: (_) => 5,
    ).fit(corr, timeOffsetS: 0, peakTimeS: 4);
    expect(fit.reason, isNotNull);
    expect(fit.reason!.isClassC, isTrue);
    expect(fit.reason, isNot(DowngradeReason.residual));
  });
}

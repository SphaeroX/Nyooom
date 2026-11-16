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

class Case {
  Case(this.pass, {double snrDb = 30, int seed = 1})
    : rec = Scenarios.render(pass, durationS: 8, snrDb: snrDb, seed: seed);
  final VehiclePass pass;
  final SimulatedRecording rec;
  GroundTruth get truth => rec.truths.single;

  Correlogram correlogram() => GccPhat(
    config: config,
    micSpacing: truth.micSpacing,
    speedOfSound: truth.speedOfSound,
  ).correlogram(rec.signal);

  MotionFitter fitter({bool propagation = true, double? laneDistance}) =>
      MotionFitter(
        config: config,
        maxTdoa: truth.micSpacing / truth.speedOfSound,
        channelOffset: 0,
        speedOfSound: truth.speedOfSound,
        laneDistance: (_) => laneDistance ?? truth.distance,
        includePropagation: propagation,
      );

  MotionFit fit({bool propagation = true}) =>
      fitter(propagation: propagation)
          .fit(correlogram(), timeOffsetS: 0, peakTimeS: truth.receptionT0);
}

void main() {
  test('kappa within 3 %, t0 within 20 ms, direction right', () {
    for (final (kmh, d) in [(30.0, 5.0), (50.0, 4.0)]) {
      for (final direction in [1, -1]) {
        for (final electric in [true, false]) {
          final pass = electric
              ? Scenarios.electric(
                  speedKmh: kmh,
                  distance: d,
                  direction: direction,
                )
              : Scenarios.combustion(
                  speedKmh: kmh,
                  distance: d,
                  direction: direction,
                );
          final c = Case(pass);
          final fit = c.fit();
          final why = '$kmh km/h, $d m, dir $direction, ev $electric';
          expect(fit.reason, isNull, reason: why);
          expect(
            fit.kappa,
            closeTo(c.truth.kappa, 0.03 * c.truth.kappa.abs()),
            reason: why,
          );
          expect(fit.t0, closeTo(c.truth.t0, 0.02), reason: why);
          expect(fit.direction, direction, reason: why);
          expect(fit.sigmaKappa, greaterThan(0), reason: why);
          expect(fit.residualS, lessThan(config.residualLimitS), reason: why);
        }
      }
    }
  });

  test('robust against strong outliers in the block maxima', () {
    final c = Case(Scenarios.electric(speedKmh: 40, distance: 4.5));
    final corr = c.correlogram();
    final random = math.Random(7);
    final delays = Float64List.fromList(corr.peakDelays);
    for (var i = 0; i < delays.length; i++) {
      if (random.nextDouble() < 0.2) {
        delays[i] = (random.nextDouble() * 2 - 1) * corr.maxLag;
      }
    }
    final corrupted = Correlogram(
      times: corr.times,
      lagStep: corr.lagStep,
      maxLagIndex: corr.maxLagIndex,
      values: corr.values,
      peakDelays: delays,
      peakWeights: corr.peakWeights,
    );
    final fit = c.fitter().fit(
      corrupted,
      timeOffsetS: 0,
      peakTimeS: c.truth.receptionT0,
    );
    expect(fit.kappa, closeTo(c.truth.kappa, 0.03 * c.truth.kappa));
    expect(fit.t0, closeTo(c.truth.t0, 0.02));
  });

  test('pure noise without a source gives a class C reason', () {
    final random = math.Random(3);
    final n = 8 * 48000;
    final noise = StereoBlock(
      Float64List.fromList(List.generate(n, (_) => random.nextDouble() - .5)),
      Float64List.fromList(List.generate(n, (_) => random.nextDouble() - .5)),
    );
    final corr = GccPhat(
      config: config,
      micSpacing: 0.15,
      speedOfSound: 343,
    ).correlogram(noise);
    final fit = MotionFitter(
      config: config,
      maxTdoa: 0.15 / 343,
      channelOffset: 0,
      speedOfSound: 343,
      laneDistance: (_) => 5,
    ).fit(corr, timeOffsetS: 0, peakTimeS: 4);
    expect(fit.reason, isNotNull);
    expect(fit.reason!.isClassC, isTrue);
  });

  test('sigma kappa is larger at low SNR than at high SNR', () {
    final pass = Scenarios.electric(speedKmh: 40, distance: 5);
    final good = Case(pass, snrDb: 30).fit();
    final bad = Case(pass, snrDb: -3, seed: 2).fit();
    expect(bad.sigmaKappa, greaterThan(good.sigmaKappa));
  });

  test('without propagation delay t0 is biased by about d/c', () {
    final c = Case(Scenarios.electric(speedKmh: 50, distance: 6));
    final withDelay = c.fit();
    final withoutDelay = c.fit(propagation: false);
    expect(withDelay.t0, closeTo(c.truth.t0, 0.004));
    final bias = withoutDelay.t0 - c.truth.t0;
    expect(bias, closeTo(6 / c.truth.speedOfSound, 0.006));
    expect(bias.abs(), greaterThan(0.01));
  });

  test('curve evaluation matches PassByModel', () {
    final c = Case(Scenarios.electric(speedKmh: 30, distance: 5));
    final f = c.fitter();
    final model = c.truth.model;
    for (final t in [1.0, 3.9, 4.0, 4.1, 7.0]) {
      expect(
        f.tdoaAt(t, kappa: c.truth.kappa, t0: c.truth.t0),
        closeTo(model.tdoa(t), 1e-10),
      );
    }
  });

  test('the fit of one 8 s event stays within the recorded bound', () {
    final c = Case(Scenarios.combustion(speedKmh: 40, distance: 5));
    final corr = c.correlogram();
    final fitter = c.fitter();
    fitter.fit(corr, timeOffsetS: 0, peakTimeS: c.truth.receptionT0);
    final watch = Stopwatch()..start();
    fitter.fit(corr, timeOffsetS: 0, peakTimeS: c.truth.receptionT0);
    watch.stop();
    // ignore: avoid_print
    print('Motion fit per event: ${watch.elapsedMilliseconds} ms');
    expect(watch.elapsed, lessThan(const Duration(seconds: 3)));
  });
}

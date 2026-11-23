import 'package:nyooom/core/calibration/plateau_calibration.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/dsp/gcc_phat.dart';
import 'package:nyooom/core/pipeline/motion_fit.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

/// A pass recorded with [trueSpacing] and [trueOffset], evaluated with the
/// nominal values [assumedSpacing] and offset 0 (an uncalibrated device).
PlateauEstimate? estimateFor(
  VehiclePass pass, {
  required double trueSpacing,
  required double trueOffset,
  required double assumedSpacing,
  double assumedOffset = 0,
}) {
  final rec = Scenarios.render(
    pass,
    micSpacing: trueSpacing,
    channelOffset: trueOffset,
  );
  final c = rec.truths.single.speedOfSound;
  final correlogram = GccPhat(
    config: config,
    micSpacing: assumedSpacing,
    speedOfSound: c,
  ).correlogram(rec.signal);
  final fitter = MotionFitter(
    config: config,
    maxTdoa: assumedSpacing / c,
    channelOffset: assumedOffset,
    speedOfSound: c,
    laneDistance: (_) => pass.distance,
  );
  final fit = fitter.fit(
    correlogram,
    timeOffsetS: 0,
    peakTimeS: rec.truths.single.receptionT0,
  );
  return estimatePlateaus(
    correlogram,
    timeOffsetS: 0,
    directionCosine: (t) =>
        (fitter.tdoaAt(t, kappa: fit.kappa, t0: fit.t0) - assumedOffset) /
        (assumedSpacing / c),
    speedOfSound: c,
    config: config,
  );
}

void main() {
  test(
    'finds spacing and offset of a device evaluated with nominal values',
    () {
      // 4 % less spacing than assumed, as on the window sill recording of
      // 2026-11-23 (0.144 m instead of 0.15 m).
      for (final direction in [1, -1]) {
        final estimate = estimateFor(
          Scenarios.electric(speedKmh: 40, distance: 4, direction: direction),
          trueSpacing: 0.144,
          trueOffset: -8e-6,
          assumedSpacing: 0.15,
        );
        expect(estimate, isNotNull, reason: 'direction $direction');
        // 2 % of b: the plateau level is read where |u| is at least 0.95, and
        // the first fit with the wrong b misjudges u there by about 1 %.
        expect(estimate!.micSpacing, closeTo(0.144, 0.003));
        expect(estimate.channelOffset, closeTo(-8e-6, 4e-6));
      }
    },
  );

  test('a second round with the estimate is within 1 %', () {
    final pass = Scenarios.electric(speedKmh: 40, distance: 4);
    final first = estimateFor(
      pass,
      trueSpacing: 0.144,
      trueOffset: -8e-6,
      assumedSpacing: 0.15,
    )!;
    final second = estimateFor(
      pass,
      trueSpacing: 0.144,
      trueOffset: -8e-6,
      assumedSpacing: first.micSpacing,
      assumedOffset: first.channelOffset,
    )!;
    expect(second.micSpacing, closeTo(0.144, 0.0015));
    expect(second.channelOffset, closeTo(-8e-6, 3e-6));
  });

  test('a correct calibration is confirmed', () {
    final estimate = estimateFor(
      Scenarios.combustion(speedKmh: 30, distance: 5),
      trueSpacing: 0.15,
      trueOffset: 0,
      assumedSpacing: 0.15,
    )!;
    expect(estimate.micSpacing, closeTo(0.15, 0.0015));
    expect(estimate.channelOffset, closeTo(0, 3e-6));
  });

  test('no estimate when the window does not reach the plateaus', () {
    // κ = 0.42 1/s: |u| stays below 0.95 within ±4 s.
    final estimate = estimateFor(
      Scenarios.electric(speedKmh: 15, distance: 10),
      trueSpacing: 0.15,
      trueOffset: 0,
      assumedSpacing: 0.15,
    );
    expect(estimate, isNull);
  });

  test('median of several passes', () {
    PlateauEstimate e(double b, double offset) => PlateauEstimate(
      micSpacing: b,
      channelOffset: offset,
      blocksBefore: 20,
      blocksAfter: 20,
    );
    final median = medianPlateauEstimate([
      e(0.142, -6e-6),
      e(0.144, -4e-6),
      e(0.160, 30e-6),
    ]);
    expect(median!.micSpacing, 0.144);
    expect(median.channelOffset, -4e-6);
    expect(medianPlateauEstimate(const []), isNull);
  });
}

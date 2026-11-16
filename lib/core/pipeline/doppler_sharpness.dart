import 'dart:math' as math;
import 'dart:typed_data';

import '../config/nyooom_config.dart';
import '../dsp/fft.dart';
import 'doppler.dart';

/// Result of Doppler variant 2.
class SharpnessResult {
  const SharpnessResult({
    required this.speed,
    required this.sigma,
    required this.peak,
    required this.median,
  });

  /// |v_D| in m/s, null without usable tone.
  final double? speed;
  final double? sigma;

  /// Largest sharpness and median over all candidates.
  final double peak;
  final double median;

  bool get hasTone => speed != null;
}

/// Doppler variant 2, dewarping with sharpness maximum (technik.pdf 5.4):
/// for each candidate v the sum signal is resampled from reception time t
/// to a uniform emission-time grid (t = te + r(te)/c with d = v/|κ|); with
/// the right v the Doppler shift vanishes and tones become sharp lines in
/// the averaged spectrum. The sharpness S(v) is the sum of squared
/// excesses (dB) above the running median.
///
/// Search: coarse grid ([NyooomConfig.sharpnessCoarseStep]) over
/// [dopplerSpeedMin, dopplerSpeedMax], then [NyooomConfig.dopplerSpeedStep]
/// around the maximum. Uncertainty from the half-height width of S.
class SharpnessEstimator {
  SharpnessEstimator({required this.config, required this.speedOfSound});

  final NyooomConfig config;
  final double speedOfSound;

  /// Sharpness for one candidate [speed] (m/s, positive).
  double sharpness(
    Float64List sum, {
    required double windowStartS,
    required double speed,
    required double kappa,
    required double t0,
  }) {
    final dewarped = _dewarp(sum, windowStartS, speed, kappa, t0);
    if (dewarped.length < config.sharpnessFftSize) return 0;
    final n = config.sharpnessFftSize;
    final fft = Fft.of(n);
    final w = hannWindow(n);
    final fs = config.sampleRate;
    final lo = (config.toneBandLowHz / fs * n).floor();
    final hi = math.min(n ~/ 2, (config.toneBandHighHz / fs * n).ceil());
    final power = Float64List(hi - lo + 1);
    final re = Float64List(n), im = Float64List(n);
    for (var s = 0; s + n <= dewarped.length; s += n ~/ 2) {
      for (var i = 0; i < n; i++) {
        re[i] = dewarped[s + i] * w[i];
        im[i] = 0;
      }
      fft.transform(re, im);
      for (var k = lo; k <= hi; k++) {
        power[k - lo] += re[k] * re[k] + im[k] * im[k];
      }
    }
    final db = Float64List(power.length);
    for (var k = 0; k < db.length; k++) {
      db[k] = 10 * math.log(power[k] + 1e-30) / math.ln10;
    }
    final binHz = fs / n;
    final halfWidth = math.max(
      2,
      (config.toneMedianWidthHz / binHz / 2).round(),
    );
    final median = DopplerEstimator.runningMedian(
      db,
      halfWidth,
      math.max(1, halfWidth ~/ 4),
    );
    // Excess over the running median; only what clearly exceeds the noise
    // fluctuation of the averaged spectrum counts (robust sigma from the
    // median absolute deviation), so weak lines are not drowned by the
    // thousands of noise bins.
    final excess = Float64List(db.length);
    for (var k = 0; k < db.length; k++) {
      excess[k] = db[k] - median[k];
    }
    final abs = Float64List.fromList([for (final e in excess) e.abs()])..sort();
    final sigma = 1.4826 * abs[abs.length ~/ 2];
    final floor = config.sharpnessFloorSigma * sigma;
    var s = 0.0;
    for (final e in excess) {
      if (e > floor) s += (e - floor) * (e - floor);
    }
    return s;
  }

  SharpnessResult estimate(
    Float64List sum, {
    required double windowStartS,
    required double kappa,
    required double t0,
  }) {
    double s(double v) => sharpness(
      sum,
      windowStartS: windowStartS,
      speed: v,
      kappa: kappa,
      t0: t0,
    );
    final coarse = <double>[];
    final values = <double>[];
    for (
      var v = config.dopplerSpeedMin;
      v <= config.dopplerSpeedMax + 1e-9;
      v += config.sharpnessCoarseStep
    ) {
      coarse.add(v);
      values.add(s(v));
    }
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > values[best]) best = i;
    }
    final peak = values[best];
    // Median as reference level. Deviation from the plain median over all
    // candidates (Task_17): candidates inside the half-height region of the
    // maximum are left out, otherwise a tone that stays partly sharp over a
    // range of v inflates the median and hides itself.
    final allSorted = List.of(values)..sort();
    final overall = allSorted[allSorted.length ~/ 2];
    final halfLevel = overall + (peak - overall) / 2;
    var lo = best, hi = best;
    while (lo > 0 && values[lo - 1] > halfLevel) {
      lo--;
    }
    while (hi < values.length - 1 && values[hi + 1] > halfLevel) {
      hi++;
    }
    final outside = [
      for (var i = 0; i < values.length; i++)
        if (i < lo - 1 || i > hi + 1) values[i],
    ]..sort();
    final median = outside.isEmpty ? overall : outside[outside.length ~/ 2];
    if (!(peak > config.sharpnessPeakFactor * median) ||
        peak < config.sharpnessMinPeak) {
      return SharpnessResult(
        speed: null,
        sigma: null,
        peak: peak,
        median: median,
      );
    }
    // Refine around the coarse maximum.
    var bestV = coarse[best], bestS = peak;
    final step = config.dopplerSpeedStep;
    final steps = (config.sharpnessCoarseStep / step).round();
    for (var j = -steps; j <= steps; j++) {
      final v = coarse[best] + j * step;
      if (j == 0 || v < config.dopplerSpeedMin || v > config.dopplerSpeedMax) {
        continue;
      }
      final value = s(v);
      if (value > bestS) {
        bestS = value;
        bestV = v;
      }
    }
    // Half-height width on the coarse curve (Gaussian FWHM → sigma).
    final half = median + (peak - median) / 2;
    double crossing(int from, int dir) {
      var i = from;
      while (i + dir >= 0 &&
          i + dir < values.length &&
          values[i + dir] > half) {
        i += dir;
      }
      final j = i + dir;
      if (j < 0 || j >= values.length) return coarse[i];
      final w = (values[i] - half) / (values[i] - values[j]);
      return coarse[i] + dir * w * config.sharpnessCoarseStep;
    }

    final width = crossing(best, 1) - crossing(best, -1);
    return SharpnessResult(
      speed: bestV,
      sigma: math.max(step, width / 2.355),
      peak: peak,
      median: median,
    );
  }

  /// Resamples [sum] (window starting at [windowStartS]) onto a uniform
  /// emission-time grid within |u| ≤ [NyooomConfig.sharpnessMaxDirectionCosine].
  Float64List _dewarp(
    Float64List sum,
    double windowStartS,
    double speed,
    double kappa,
    double t0,
  ) {
    final fs = config.sampleRate.toDouble();
    final c = speedOfSound;
    final d = speed / kappa.abs();
    final uMax = config.sharpnessMaxDirectionCosine;
    final tauMax = uMax / (kappa.abs() * math.sqrt(1 - uMax * uMax));
    final windowEnd = windowStartS + sum.length / fs;
    // Keep emission times whose reception lies inside the window.
    var teFrom = t0 - tauMax, teTo = t0 + tauMax;
    double reception(double te) {
      final x = speed * (te - t0);
      return te + math.sqrt(d * d + x * x) / c;
    }

    while (reception(teFrom) < windowStartS + 2 / fs && teFrom < t0) {
      teFrom += 0.01;
    }
    while (reception(teTo) > windowEnd - 3 / fs && teTo > t0) {
      teTo -= 0.01;
    }
    final n = math.max(0, ((teTo - teFrom) * fs).floor());
    final out = Float64List(n);
    for (var i = 0; i < n; i++) {
      final pos = (reception(teFrom + i / fs) - windowStartS) * fs;
      out[i] = _cubic(sum, pos);
    }
    return out;
  }

  /// Catmull-Rom interpolation.
  static double _cubic(Float64List x, double pos) {
    final i = pos.floor();
    final f = pos - i;
    double at(int k) => x[k.clamp(0, x.length - 1)];
    final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
    return p1 +
        0.5 *
            f *
            (p2 -
                p0 +
                f *
                    (2 * p0 -
                        5 * p1 +
                        4 * p2 -
                        p3 +
                        f * (3 * (p1 - p2) + p3 - p0)));
  }
}

/// The Doppler estimate used for the fusion.
class DopplerChoice {
  const DopplerChoice({
    required this.speed,
    required this.sigma,
    required this.toneCount,
    required this.variant,
    this.speedWithAcceleration,
    this.frequencyRises = false,
  });

  /// Variant 1 only: the tones rise against the model (see
  /// [DopplerResult.frequencyRises]).
  final bool frequencyRises;

  final double speed;
  final double sigma;
  final int toneCount;

  /// 1 = line tracking, 2 = dewarping.
  final int variant;

  /// Only variant 1 has the acceleration regression.
  final double? speedWithAcceleration;
}

/// Combination rule (Task_17): variant 1 has priority because it also
/// checks for acceleration; variant 2 is only used when variant 1 finds no
/// tone and variant 2 is enabled.
DopplerChoice? chooseDoppler({
  required DopplerChoice? v1,
  required DopplerChoice? v2,
  required bool variant2Enabled,
}) {
  if (v1 != null) return v1;
  if (variant2Enabled) return v2;
  return null;
}

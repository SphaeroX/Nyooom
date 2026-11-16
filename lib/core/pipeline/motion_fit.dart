import 'dart:math' as math;
import 'dart:typed_data';

import '../config/nyooom_config.dart';
import '../dsp/gcc_phat.dart';
import 'reasons.dart';

/// Result of fitting the motion model to one event (technik.pdf 5.3).
class MotionFit {
  const MotionFit({
    required this.kappa,
    required this.sigmaKappa,
    required this.t0,
    required this.sigmaT0,
    required this.residualS,
    required this.inliers,
    required this.onCurveFraction,
    required this.startKappa,
    required this.startT0,
    this.reason,
  });

  /// κ = v/d in 1/s; the sign is the direction of travel.
  final double kappa;
  final double sigmaKappa;

  /// Emission time of closest approach (absolute, s).
  final double t0;
  final double sigmaT0;

  /// Weighted RMS of the fine-fit residuals in s (`rest_laufzeit`).
  final double residualS;
  final int inliers;

  /// Fraction of strong blocks that lie on the fitted S curve.
  final double onCurveFraction;
  final double startKappa;
  final double startT0;

  /// Class-C reason if the track is not valid, otherwise null.
  final DowngradeReason? reason;

  int get direction => kappa >= 0 ? 1 : -1;
}

/// Fits Δ(t; κ, t0) = b/c·u + Δ0 to a correlogram: coarse grid search of the
/// summed correlation along the model curve, then a robust (Huber) weighted
/// Levenberg–Marquardt fit to the block maxima (technik.pdf 5.3).
///
/// The sound travel time uses the lane distance of the direction
/// (technik.pdf 5.3 last paragraph); with [includePropagation] false the
/// model ignores it (only for comparison).
class MotionFitter {
  MotionFitter({
    required this.config,
    required this.maxTdoa,
    required this.channelOffset,
    required this.speedOfSound,
    required this.laneDistance,
    this.includePropagation = true,
  });

  final NyooomConfig config;

  /// b/c in s.
  final double maxTdoa;

  /// Δ0 in s.
  final double channelOffset;
  final double speedOfSound;

  /// Lane distance d_Spur for a direction (+1/−1).
  final double Function(int direction) laneDistance;
  final bool includePropagation;

  /// Model TDOA at reception time [t] (closed-form solution of
  /// t = te + r(te)/c, technik.pdf 3.1/3.2).
  double tdoaAt(double t, {required double kappa, required double t0}) {
    final d = laneDistance(kappa >= 0 ? 1 : -1);
    return maxTdoa * _directionCosine(t - t0, kappa, d) + channelOffset;
  }

  double _directionCosine(double s, double kappa, double d) {
    double tau;
    if (includePropagation) {
      final c = speedOfSound, v = kappa * d;
      final c2 = c * c, v2 = v * v;
      final disc = c2 * (d * d + v2 * s * s) - v2 * d * d;
      tau = (c2 * s - math.sqrt(disc)) / (c2 - v2);
    } else {
      tau = s;
    }
    final k = kappa * tau;
    return k / math.sqrt(1 + k * k);
  }

  MotionFit fit(
    Correlogram correlogram, {
    required double timeOffsetS,
    required double peakTimeS,
  }) {
    final n = correlogram.rowCount;
    final times = Float64List(n);
    for (var i = 0; i < n; i++) {
      times[i] = timeOffsetS + correlogram.times[i];
    }

    // 1. Coarse search (5.3 step 1).
    final kappas = <double>[];
    for (
      var k = config.kappaMin;
      k <= config.kappaMax + 1e-9;
      k += config.kappaGridStep
    ) {
      kappas
        ..add(k)
        ..add(-k);
    }
    final t0Steps = (config.t0SearchRangeS / config.t0SearchStepS).round();
    var bestScore = -double.infinity, bestKappa = kappas.first;
    var bestT0 = peakTimeS;
    final lagScale = 1 / correlogram.lagStep;
    final lagCount = correlogram.lagCount;
    final values = correlogram.values;
    for (final kappa in kappas) {
      final d = laneDistance(kappa >= 0 ? 1 : -1);
      for (var j = -t0Steps; j <= t0Steps; j++) {
        final t0 = peakTimeS + j * config.t0SearchStepS;
        var score = 0.0;
        for (var i = 0; i < n; i++) {
          final lag =
              maxTdoa * _directionCosine(times[i] - t0, kappa, d) +
              channelOffset;
          final pos = lag * lagScale + correlogram.maxLagIndex;
          if (pos < 0 || pos >= lagCount - 1) continue;
          final p = pos.floor();
          final w = pos - p;
          final base = i * lagCount + p;
          score += values[base] * (1 - w) + values[base + 1] * w;
        }
        if (score > bestScore) {
          bestScore = score;
          bestKappa = kappa;
          bestT0 = t0;
        }
      }
    }

    // 2. Inliers relative to the start curve.
    final delays = correlogram.peakDelays;
    final weights = correlogram.peakWeights;
    final idx = <int>[];
    for (var i = 0; i < n; i++) {
      final r = delays[i] - tdoaAt(times[i], kappa: bestKappa, t0: bestT0);
      if (r.abs() <= config.fitOutlierLimitS && weights[i] > 0) idx.add(i);
    }
    if (idx.length < config.fitMinPoints) {
      return MotionFit(
        kappa: bestKappa,
        sigmaKappa: double.infinity,
        t0: bestT0,
        sigmaT0: double.infinity,
        residualS: double.infinity,
        inliers: idx.length,
        onCurveFraction: 0,
        startKappa: bestKappa,
        startT0: bestT0,
        reason: DowngradeReason.noTrack,
      );
    }
    var meanW = 0.0;
    for (final i in idx) {
      meanW += weights[i];
    }
    meanW /= idx.length;

    // 3. Robust weighted Levenberg–Marquardt (5.3 step 2).
    var kappa = bestKappa, t0 = bestT0, lambda = 1e-3;
    double cost(double k, double t) {
      var c = 0.0;
      for (final i in idx) {
        final r = delays[i] - tdoaAt(times[i], kappa: k, t0: t);
        c += weights[i] / meanW * _huberLoss(r);
      }
      return c;
    }

    var current = cost(kappa, t0);
    late double a00, a01, a11;
    for (var iter = 0; iter < 50; iter++) {
      a00 = 0;
      a01 = 0;
      a11 = 0;
      var g0 = 0.0, g1 = 0.0;
      const hk = 1e-5, ht = 1e-6;
      for (final i in idx) {
        final t = times[i];
        final f = tdoaAt(t, kappa: kappa, t0: t0);
        final r = delays[i] - f;
        final jk =
            (tdoaAt(t, kappa: kappa + hk, t0: t0) -
                tdoaAt(t, kappa: kappa - hk, t0: t0)) /
            (2 * hk);
        final jt =
            (tdoaAt(t, kappa: kappa, t0: t0 + ht) -
                tdoaAt(t, kappa: kappa, t0: t0 - ht)) /
            (2 * ht);
        final w = weights[i] / meanW * _huberWeight(r);
        a00 += w * jk * jk;
        a01 += w * jk * jt;
        a11 += w * jt * jt;
        g0 += w * jk * r;
        g1 += w * jt * r;
      }
      final m00 = a00 * (1 + lambda), m11 = a11 * (1 + lambda);
      final det = m00 * m11 - a01 * a01;
      if (det == 0) break;
      final dk = (m11 * g0 - a01 * g1) / det;
      final dt = (m00 * g1 - a01 * g0) / det;
      final next = cost(kappa + dk, t0 + dt);
      if (next < current) {
        kappa += dk;
        t0 += dt;
        lambda = math.max(lambda / 10, 1e-9);
        final converged = (current - next) < 1e-12 * current;
        current = next;
        if (converged || (dk.abs() < 1e-7 && dt.abs() < 1e-8)) break;
      } else {
        lambda *= 10;
        if (lambda > 1e8) break;
      }
    }

    // 4. Residual, covariance, validity (5.3 step 3, 5.6).
    var sumW = 0.0, sumWr2 = 0.0;
    for (final i in idx) {
      final r = delays[i] - tdoaAt(times[i], kappa: kappa, t0: t0);
      final w = weights[i] / meanW;
      sumW += w;
      sumWr2 += w * r * r;
    }
    final residual = math.sqrt(sumWr2 / sumW);
    // Recompute the normal matrix at the solution without Huber weights.
    a00 = 0;
    a01 = 0;
    a11 = 0;
    for (final i in idx) {
      final t = times[i];
      const hk = 1e-5, ht = 1e-6;
      final jk =
          (tdoaAt(t, kappa: kappa + hk, t0: t0) -
              tdoaAt(t, kappa: kappa - hk, t0: t0)) /
          (2 * hk);
      final jt =
          (tdoaAt(t, kappa: kappa, t0: t0 + ht) -
              tdoaAt(t, kappa: kappa, t0: t0 - ht)) /
          (2 * ht);
      final w = weights[i] / meanW;
      a00 += w * jk * jk;
      a01 += w * jk * jt;
      a11 += w * jt * jt;
    }
    final det = a00 * a11 - a01 * a01;
    // Overlapping blocks are correlated: inflate by blockLength/hop.
    final s2 =
        sumWr2 /
        math.max(1, idx.length - 2) *
        (config.gccBlockLength / config.gccHop);
    final sigmaKappa = det > 0 ? math.sqrt(s2 * a11 / det) : double.infinity;
    final sigmaT0 = det > 0 ? math.sqrt(s2 * a00 / det) : double.infinity;

    var maxWeight = 0.0;
    for (var i = 0; i < n; i++) {
      maxWeight = math.max(maxWeight, weights[i]);
    }
    var strong = 0, onCurve = 0;
    for (var i = 0; i < n; i++) {
      if (weights[i] < 0.5 * maxWeight) continue;
      strong++;
      final r = delays[i] - tdoaAt(times[i], kappa: kappa, t0: t0);
      if (r.abs() <= config.fitOutlierLimitS) onCurve++;
    }
    final fraction = strong == 0 ? 0.0 : onCurve / strong;

    DowngradeReason? reason;
    final atGridEdge =
        (bestKappa.abs() - config.kappaMax).abs() < config.kappaGridStep / 2;
    if (atGridEdge ||
        kappa.abs() < config.kappaMin ||
        kappa.abs() > config.kappaMax) {
      reason = DowngradeReason.outOfRange;
    } else if (residual > config.residualLimitS) {
      reason = DowngradeReason.residual;
    } else if (fraction < config.monotonicMinFraction) {
      reason = DowngradeReason.notMonotonic;
    }

    return MotionFit(
      kappa: kappa,
      sigmaKappa: sigmaKappa,
      t0: t0,
      sigmaT0: sigmaT0,
      residualS: residual,
      inliers: idx.length,
      onCurveFraction: fraction,
      startKappa: bestKappa,
      startT0: bestT0,
      reason: reason,
    );
  }

  double _huberWeight(double r) {
    final a = r.abs(), delta = config.fitHuberDeltaS;
    return a <= delta ? 1 : delta / a;
  }

  double _huberLoss(double r) {
    final a = r.abs(), delta = config.fitHuberDeltaS;
    return a <= delta ? 0.5 * r * r : delta * (a - 0.5 * delta);
  }
}

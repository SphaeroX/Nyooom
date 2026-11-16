import 'dart:math' as math;
import 'dart:typed_data';

import '../config/nyooom_config.dart';
import '../dsp/gcc_phat.dart';
import 'reasons.dart';

/// u at reception time offset s = t − t0 for κ and distance d, with the
/// sound travel time solved in closed form: t − t0 = τ + √(d² + v²τ²)/c
/// (technik.pdf 3.1). An infinite [speedOfSound] ignores the travel time.
double directionCosineAt(
  double s, {
  required double kappa,
  required double distance,
  required double speedOfSound,
}) {
  double tau;
  if (speedOfSound.isFinite) {
    final c = speedOfSound, v = kappa * distance, d = distance;
    final c2 = c * c, v2 = v * v;
    final disc = c2 * (d * d + v2 * s * s) - v2 * d * d;
    tau = (c2 * s - math.sqrt(disc)) / (c2 - v2);
  } else {
    tau = s;
  }
  final k = kappa * tau;
  return k / math.sqrt(1 + k * k);
}

/// A track that was already found in the same window. Further searches
/// leave its band of the correlogram out (track separation).
class TrackCurve {
  const TrackCurve({required this.kappa, required this.t0});
  final double kappa;

  /// Emission time of closest approach (absolute, s).
  final double t0;
}

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
    this.strength = 0,
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

  /// Fraction of the blocks around the closest approach that show a
  /// correlation maximum on the fitted S curve.
  final double onCurveFraction;
  final double startKappa;
  final double startT0;

  /// Mean correlation along the fitted curve around the closest approach
  /// (0 = nothing there, 1 = one perfectly coherent source).
  final double strength;

  /// Class-C reason if the track is not valid, otherwise null.
  final DowngradeReason? reason;

  int get direction => kappa >= 0 ? 1 : -1;

  TrackCurve get curve => TrackCurve(kappa: kappa, t0: t0);
}

/// Fits Δ(t; κ, t0) = b/c·u + Δ0 to a correlogram: coarse grid search of the
/// summed correlation along the model curve, then a robust (Huber) weighted
/// Levenberg–Marquardt fit to the block maxima (technik.pdf 5.3).
///
/// The sound travel time uses the lane distance of the direction
/// (technik.pdf 5.3 last paragraph); with [includePropagation] false the
/// model ignores it (only for comparison).
///
/// Several vehicles in one window: the PHAT weighting makes every coherent
/// source a maximum of similar height, however quiet it is, so the largest
/// maximum of a block often belongs to another vehicle. The fine fit
/// therefore takes, per block, the local maximum next to the start curve
/// (within the outlier limit) instead of the largest one, and a track is
/// judged only around its own closest approach
/// (|u| ≤ [NyooomConfig.trackCoreDirectionCosine]).
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

  double _directionCosine(double s, double kappa, double d) =>
      directionCosineAt(
        s,
        kappa: kappa,
        distance: d,
        speedOfSound: includePropagation ? speedOfSound : double.infinity,
      );

  /// Fits one track. [t0MinS]/[t0MaxS] bound the coarse search for t0
  /// (besides ±[NyooomConfig.t0SearchRangeS] around [peakTimeS]),
  /// [direction] restricts it to one direction of travel, and the bands of
  /// the [exclude]d tracks do not count (search for a further vehicle).
  ///
  /// Without [othersPresent] every block around the closest approach must
  /// show a maximum on the curve (technik.pdf 5.6, "Spur nicht monoton": a
  /// vehicle that stops or turns leaves the curve). With it, blocks in
  /// which another coherent source is the largest maximum are not judged:
  /// a second vehicle is known to be in the window.
  MotionFit fit(
    Correlogram correlogram, {
    required double timeOffsetS,
    required double peakTimeS,
    double? t0MinS,
    double? t0MaxS,
    int? direction,
    List<TrackCurve> exclude = const [],
    bool othersPresent = false,
  }) {
    final n = correlogram.rowCount;
    final times = Float64List(n);
    for (var i = 0; i < n; i++) {
      times[i] = timeOffsetS + correlogram.times[i];
    }
    final masks = [
      for (final e in exclude)
        Float64List.fromList([
          for (var i = 0; i < n; i++)
            tdoaAt(times[i], kappa: e.kappa, t0: e.t0),
        ]),
    ];
    final maskWidth = config.trackMaskWidthS;

    // 1. Coarse search (5.3 step 1).
    final kappas = <double>[];
    for (
      var k = config.kappaMin;
      k <= config.kappaMax + 1e-9;
      k += config.kappaGridStep
    ) {
      if (direction == null || direction > 0) kappas.add(k);
      if (direction == null || direction < 0) kappas.add(-k);
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
        if (t0MinS != null && t0 < t0MinS) continue;
        if (t0MaxS != null && t0 > t0MaxS) continue;
        var score = 0.0;
        rows:
        for (var i = 0; i < n; i++) {
          final lag =
              maxTdoa * _directionCosine(times[i] - t0, kappa, d) +
              channelOffset;
          for (final mask in masks) {
            if ((lag - mask[i]).abs() < maskWidth) continue rows;
          }
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

    // 2. and 3. Block maxima next to the curve, then the robust weighted
    // Levenberg–Marquardt fit (5.3 step 2). The maxima are picked a second
    // time along the refined curve.
    final delays = Float64List(n), weights = Float64List(n);
    var kappa = bestKappa, t0 = bestT0;
    var idx = <int>[];
    var meanW = 1.0;
    for (var pass = 0; pass < 2; pass++) {
      idx = _pickMaxima(
        correlogram,
        times,
        masks,
        kappa: kappa,
        t0: t0,
        delays: delays,
        weights: weights,
      );
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
      meanW = 0;
      for (final i in idx) {
        meanW += weights[i];
      }
      meanW /= idx.length;
      final refined = _refine(times, delays, weights, idx, meanW, kappa, t0);
      kappa = refined.kappa;
      t0 = refined.t0;
    }

    // 4. Residual, covariance, validity (5.3 step 3, 5.6).
    var sumW = 0.0, sumWr2 = 0.0;
    var a00 = 0.0, a01 = 0.0, a11 = 0.0;
    for (final i in idx) {
      final t = times[i];
      final r = delays[i] - tdoaAt(t, kappa: kappa, t0: t0);
      final w = weights[i] / meanW;
      sumW += w;
      sumWr2 += w * r * r;
      // Normal matrix at the solution without Huber weights.
      final (jk, jt) = _jacobian(t, kappa, t0);
      a00 += w * jk * jk;
      a01 += w * jk * jt;
      a11 += w * jt * jt;
    }
    final residual = math.sqrt(sumWr2 / sumW);
    final det = a00 * a11 - a01 * a01;
    // Overlapping blocks are correlated: inflate by blockLength/hop.
    final s2 =
        sumWr2 /
        math.max(1, idx.length - 2) *
        (config.gccBlockLength / config.gccHop);
    final sigmaKappa = det > 0 ? math.sqrt(s2 * a11 / det) : double.infinity;
    final sigmaT0 = det > 0 ? math.sqrt(s2 * a00 / det) : double.infinity;

    // Evidence around the closest approach: mean correlation along the
    // curve and share of blocks with a maximum on it.
    _pickMaxima(
      correlogram,
      times,
      masks,
      kappa: kappa,
      t0: t0,
      delays: delays,
      weights: weights,
    );
    var core = 0, onCurve = 0, occluded = 0;
    var strength = 0.0;
    rows:
    for (var i = 0; i < n; i++) {
      final lag = tdoaAt(times[i], kappa: kappa, t0: t0);
      final u = (lag - channelOffset) / maxTdoa;
      if (u.abs() > config.trackCoreDirectionCosine) continue;
      for (final mask in masks) {
        if ((lag - mask[i]).abs() < maskWidth) continue rows;
      }
      core++;
      strength += correlogram.valueAt(i, lag);
      if (weights[i] >= config.trackMinStrength) {
        onCurve++;
      } else if (othersPresent &&
          correlogram.peakWeights[i] >= 2 * config.trackMinStrength) {
        // Another coherent source dominates this block: it says nothing
        // about this track.
        occluded++;
      }
    }
    strength = core == 0 ? 0.0 : strength / core;
    final judged = core - occluded;
    final fraction = judged < config.fitMinPoints ? 0.0 : onCurve / judged;

    DowngradeReason? reason;
    final atGridEdge =
        (bestKappa.abs() - config.kappaMax).abs() < config.kappaGridStep / 2;
    if (atGridEdge ||
        kappa.abs() < config.kappaMin ||
        kappa.abs() > config.kappaMax) {
      reason = DowngradeReason.outOfRange;
    } else if (core < config.fitMinPoints ||
        strength < config.trackMinStrength) {
      reason = DowngradeReason.noTrack;
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
      strength: strength,
      reason: reason,
    );
  }

  /// Per block the local maximum of R within the outlier limit of the curve
  /// (κ, t0), written to [delays]/[weights] (weight 0 without one). Returns
  /// the blocks that have one. Blocks in which the curve runs through the
  /// band of a masked track are left out.
  List<int> _pickMaxima(
    Correlogram correlogram,
    Float64List times,
    List<Float64List> masks, {
    required double kappa,
    required double t0,
    required Float64List delays,
    required Float64List weights,
  }) {
    final lagCount = correlogram.lagCount;
    final lagStep = correlogram.lagStep;
    final values = correlogram.values;
    final half = config.fitOutlierLimitS / lagStep;
    final guard = config.trackMaskWidthS + config.fitOutlierLimitS;
    final idx = <int>[];
    rows:
    for (var i = 0; i < times.length; i++) {
      weights[i] = 0;
      final lag = tdoaAt(times[i], kappa: kappa, t0: t0);
      for (final mask in masks) {
        if ((lag - mask[i]).abs() < guard) continue rows;
      }
      final centre = lag / lagStep + correlogram.maxLagIndex;
      final lo = math.max(1, (centre - half).ceil());
      final hi = math.min(lagCount - 2, (centre + half).floor());
      if (lo > hi) continue;
      final base = i * lagCount;
      var best = lo;
      for (var j = lo + 1; j <= hi; j++) {
        if (values[base + j] > values[base + best]) best = j;
      }
      final a = values[base + best - 1];
      final b = values[base + best];
      final c = values[base + best + 1];
      // A maximum at the border of the range that still rises outwards
      // belongs to something else.
      if (b <= 0 || a > b || c > b) continue;
      var offset = 0.0, height = b;
      final denom = a - 2 * b + c;
      if (denom < 0) {
        offset = 0.5 * (a - c) / denom;
        height = b - 0.25 * (a - c) * offset;
      }
      delays[i] = (best - correlogram.maxLagIndex + offset) * lagStep;
      weights[i] = height;
      idx.add(i);
    }
    return idx;
  }

  (double, double) _jacobian(double t, double kappa, double t0) {
    const hk = 1e-5, ht = 1e-6;
    final jk =
        (tdoaAt(t, kappa: kappa + hk, t0: t0) -
            tdoaAt(t, kappa: kappa - hk, t0: t0)) /
        (2 * hk);
    final jt =
        (tdoaAt(t, kappa: kappa, t0: t0 + ht) -
            tdoaAt(t, kappa: kappa, t0: t0 - ht)) /
        (2 * ht);
    return (jk, jt);
  }

  /// Robust weighted Levenberg–Marquardt over the blocks [idx].
  ({double kappa, double t0}) _refine(
    Float64List times,
    Float64List delays,
    Float64List weights,
    List<int> idx,
    double meanW,
    double startKappa,
    double startT0,
  ) {
    var kappa = startKappa, t0 = startT0, lambda = 1e-3;
    double cost(double k, double t) {
      var c = 0.0;
      for (final i in idx) {
        final r = delays[i] - tdoaAt(times[i], kappa: k, t0: t);
        c += weights[i] / meanW * _huberLoss(r);
      }
      return c;
    }

    var current = cost(kappa, t0);
    for (var iter = 0; iter < 50; iter++) {
      var a00 = 0.0, a01 = 0.0, a11 = 0.0;
      var g0 = 0.0, g1 = 0.0;
      for (final i in idx) {
        final t = times[i];
        final r = delays[i] - tdoaAt(t, kappa: kappa, t0: t0);
        final (jk, jt) = _jacobian(t, kappa, t0);
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
    return (kappa: kappa, t0: t0);
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

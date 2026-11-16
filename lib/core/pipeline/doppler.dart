import 'dart:math' as math;
import 'dart:typed_data';

import '../config/nyooom_config.dart';
import '../dsp/spectrogram.dart';
import '../signal/pcm.dart';

/// A tone track: frequency over (reception) time.
class ToneTrack {
  ToneTrack(this.points);
  final List<({double t, double f})> points;

  double get start => points.first.t;
  double get end => points.last.t;
  double get duration => end - start;
}

/// Result of the Doppler evaluation (technik.pdf 5.4 variant 1).
class DopplerResult {
  const DopplerResult({
    required this.speed,
    required this.sigma,
    required this.toneCount,
    required this.offsetS,
    required this.residual,
    required this.tracks,
    required this.speedWithAcceleration,
    this.frequencyRises = false,
  });

  const DopplerResult.noTone()
    : speed = null,
      sigma = null,
      toneCount = 0,
      offsetS = 0,
      residual = null,
      tracks = const [],
      speedWithAcceleration = null,
      frequencyRises = false;

  /// The regression gives v with the sign opposite to the direction of
  /// travel: the tones rise where a Doppler curve must fall (technik.pdf
  /// 6.1). The source frequency itself changed (throttle, gear) or the tone
  /// belongs to something else; [speed] is then not a speed.
  final bool frequencyRises;

  /// |v_D| in m/s, null without tone.
  final double? speed;
  final double? sigma;
  final int toneCount;

  /// Chosen time offset between u(t) and the tone tracks in s.
  final double offsetS;

  /// RMS residual of ln f.
  final double? residual;
  final List<ToneTrack> tracks;

  /// |v| from the second regression with the term g·(t − t0) (5.4,
  /// acceleration check), null without tone.
  final double? speedWithAcceleration;

  bool get hasTone => speed != null;
}

/// Keeps tracks of at least the minimum length that cover the closest
/// approach (technik.pdf 5.4 step 4).
List<ToneTrack> selectTracks(
  List<ToneTrack> tracks, {
  required double receptionT0,
  required NyooomConfig config,
}) {
  const coverS = 0.2;
  return [
    for (final t in tracks)
      if (t.duration >= config.toneMinLengthS &&
          t.start <= receptionT0 - coverS &&
          t.end >= receptionT0 + coverS)
        t,
  ];
}

/// Distance check of technik.pdf 5.5 applied to single tone tracks: a tone
/// belongs to the vehicle only if the speed it gives alone, divided by |κ|,
/// is compatible with the lane distance. Tones of other vehicles that are
/// audible at the same time fail it, because against the u(t) of this
/// vehicle they hardly move.
class ToneGate {
  const ToneGate({required this.kappa, required this.laneDistance});

  /// κ of the vehicle from the TDOA fit in 1/s.
  final double kappa;

  /// Lane distance d_Spur in m.
  final double laneDistance;
}

/// Doppler speed with known direction cosine u(t) (technik.pdf 5.4,
/// variant 1): track tones in the spectrogram of the sum signal and fit
/// ln f_k(t_j) = ln f0_k − ln(1 + v/c·u(t_j + δ)) with one v for all
/// tracks, for offsets δ in ±[NyooomConfig.toneOffsetRangeS].
class DopplerEstimator {
  DopplerEstimator({required this.config, required this.speedOfSound});

  final NyooomConfig config;
  final double speedOfSound;

  /// [directionCosine] takes absolute reception times; the spectrogram
  /// times are shifted by [windowStartS].
  DopplerResult estimate(
    StereoBlock window, {
    required double windowStartS,
    required double receptionT0,
    required double Function(double t) directionCosine,
    ToneGate? gate,
  }) {
    final sum = Float64List(window.length);
    for (var i = 0; i < sum.length; i++) {
      sum[i] = 0.5 * (window.left[i] + window.right[i]);
    }
    if (sum.length < config.spectrogramWindow) {
      return const DopplerResult.noTone();
    }
    final spectrogram = Spectrogram.compute(sum, config: config);
    var tracks = selectTracks(
      trackTones(spectrogram, timeOffsetS: windowStartS),
      receptionT0: receptionT0,
      config: config,
    );
    if (tracks.isEmpty) return const DopplerResult.noTone();

    // u rises through 0 for travel in +x direction, so v·u is the radial
    // speed only for v of the same sign (technik.pdf 3.3).
    final direction =
        directionCosine(receptionT0 + config.toneMinLengthS) >=
            directionCosine(receptionT0 - config.toneMinLengthS)
        ? 1
        : -1;
    final steps = (config.toneOffsetRangeS / config.toneOffsetStepS).round();
    (_Fit, double)? bestOf(List<ToneTrack> tracks, {bool core = false}) {
      _Fit? best;
      var bestOffset = 0.0;
      for (var s = -steps; s <= steps; s++) {
        final offset = s * config.toneOffsetStepS;
        final fit = _fit(
          tracks,
          (t) => directionCosine(t + offset),
          maxDirectionCosine: core ? config.sharpnessMaxDirectionCosine : null,
        );
        if (fit != null && (best == null || fit.residual < best.residual)) {
          best = fit;
          bestOffset = offset;
        }
      }
      return best == null ? null : (best, bestOffset);
    }

    if (gate != null) {
      // Far before and after the pass a tone only shows its two limit
      // frequencies, and those are the same for any vehicle of similar
      // speed. Whose tone it is shows in the moment of the fall, so the
      // single tracks are judged where u changes (as in variant 2).
      final tolerance = config.distanceCheckTolerance * gate.laneDistance;
      final own = [
        for (final track in tracks)
          if (bestOf([track], core: true) case (final fit, _)
              when fit.v * direction > 0 &&
                  (fit.v.abs() / gate.kappa.abs() - gate.laneDistance).abs() <=
                      tolerance + 2 * fit.sigma / gate.kappa.abs())
            track,
      ];
      // Without any compatible track all stay, so that the distance check
      // of the fusion still sees the estimate.
      if (own.isNotEmpty) tracks = own;
    }

    final joint = bestOf(tracks);
    if (joint == null) return const DopplerResult.noTone();
    final (best, bestOffset) = joint;
    final accel = _fit(
      tracks,
      (t) => directionCosine(t + bestOffset),
      accelerationAt: receptionT0,
    );
    return DopplerResult(
      speed: best.v.abs(),
      sigma: best.sigma,
      toneCount: tracks.length,
      offsetS: bestOffset,
      residual: best.residual,
      tracks: tracks,
      speedWithAcceleration: accel?.v.abs(),
      frequencyRises: best.v * direction <= 0,
    );
  }

  /// Steps 2 to 4 of variant 1: median normalisation, prominent maxima,
  /// tracks.
  List<ToneTrack> trackTones(Spectrogram s, {required double timeOffsetS}) {
    final halfWidth = math.max(
      2,
      (config.toneMedianWidthHz / s.binHz / 2).round(),
    );
    final decimation = math.max(1, halfWidth ~/ 4);
    final maxGapFrames = math.max(
      1,
      (config.toneMaxGapS * config.sampleRate / config.spectrogramHop).round(),
    );
    final active = <_ActiveTrack>[];
    final done = <ToneTrack>[];
    for (var r = 0; r < s.rowCount; r++) {
      final row = s.row(r);
      final median = runningMedian(row, halfWidth, decimation);
      final t = timeOffsetS + s.times[r];
      final peaks = <double>[];
      for (var k = 1; k < row.length - 1; k++) {
        final p = row[k] - median[k];
        if (p < config.toneMinProminenceDb) continue;
        if (row[k] < row[k - 1] || row[k] < row[k + 1]) continue;
        peaks.add(s.frequencyOf(k) + parabolicOffset(row, k) * s.binHz);
      }
      final used = List.filled(peaks.length, false);
      for (final track in active) {
        var bestJ = -1;
        var bestDiff = config.toneMaxJumpHz;
        for (var j = 0; j < peaks.length; j++) {
          if (used[j]) continue;
          final diff = (peaks[j] - track.lastF).abs();
          if (diff <= bestDiff) {
            bestDiff = diff;
            bestJ = j;
          }
        }
        if (bestJ >= 0) {
          used[bestJ] = true;
          track.points.add((t: t, f: peaks[bestJ]));
          track.lastRow = r;
        }
      }
      active.removeWhere((track) {
        if (r - track.lastRow > maxGapFrames) {
          done.add(ToneTrack(track.points));
          return true;
        }
        return false;
      });
      for (var j = 0; j < peaks.length; j++) {
        if (!used[j]) active.add(_ActiveTrack(t, peaks[j], r));
      }
    }
    for (final track in active) {
      done.add(ToneTrack(track.points));
    }
    return done;
  }

  /// Gauss–Newton fit of v (signed) with one intercept per track; with
  /// [accelerationAt] an extra term g·(t − t0) is fitted as well. With
  /// [maxDirectionCosine] only points with |u| up to that value count.
  _Fit? _fit(
    List<ToneTrack> tracks,
    double Function(double t) u, {
    double? accelerationAt,
    double? maxDirectionCosine,
  }) {
    final c = speedOfSound;
    final ts = <double>[], us = <double>[], lf = <double>[], k = <int>[];
    for (var i = 0; i < tracks.length; i++) {
      for (final p in tracks[i].points) {
        final value = u(p.t);
        if (maxDirectionCosine != null && value.abs() > maxDirectionCosine) {
          continue;
        }
        ts.add(p.t);
        us.add(value);
        lf.add(math.log(p.f));
        k.add(i);
      }
    }
    final n = ts.length;
    final nTracks = tracks.length;
    final withG = accelerationAt != null;
    if (n < nTracks + 2) return null;
    var v = 0.0, g = 0.0;
    final a = Float64List(nTracks);
    for (var iter = 0; iter < 8; iter++) {
      // Intercepts for fixed v, g.
      final sums = Float64List(nTracks), counts = Float64List(nTracks);
      for (var j = 0; j < n; j++) {
        final model =
            -math.log(1 + v / c * us[j]) +
            (withG ? g * (ts[j] - accelerationAt) : 0);
        sums[k[j]] += lf[j] - model;
        counts[k[j]]++;
      }
      for (var i = 0; i < nTracks; i++) {
        a[i] = sums[i] / counts[i];
      }
      // Normal equations for (v, g) with track-centred derivatives.
      final dvMean = Float64List(nTracks), dgMean = Float64List(nTracks);
      final dv = Float64List(n), dg = Float64List(n), res = Float64List(n);
      for (var j = 0; j < n; j++) {
        dv[j] = -(us[j] / c) / (1 + v / c * us[j]);
        dg[j] = withG ? ts[j] - accelerationAt : 0;
        dvMean[k[j]] += dv[j] / counts[k[j]];
        dgMean[k[j]] += dg[j] / counts[k[j]];
      }
      var svv = 0.0, svg = 0.0, sgg = 0.0, bv = 0.0, bg = 0.0;
      for (var j = 0; j < n; j++) {
        final model =
            a[k[j]] - math.log(1 + v / c * us[j]) + (withG ? g * dg[j] : 0);
        res[j] = lf[j] - model;
        final x = dv[j] - dvMean[k[j]], y = dg[j] - dgMean[k[j]];
        svv += x * x;
        svg += x * y;
        sgg += y * y;
        bv += x * res[j];
        bg += y * res[j];
      }
      if (withG) {
        final det = svv * sgg - svg * svg;
        if (det <= 0) return null;
        v += (sgg * bv - svg * bg) / det;
        g += (svv * bg - svg * bv) / det;
      } else {
        if (svv <= 0) return null;
        v += bv / svv;
      }
    }
    // Residual and uncertainty at the solution.
    var rss = 0.0, svv = 0.0;
    final counts = Float64List(nTracks), dvMean = Float64List(nTracks);
    for (var j = 0; j < n; j++) {
      counts[k[j]]++;
    }
    final dv = Float64List(n);
    for (var j = 0; j < n; j++) {
      dv[j] = -(us[j] / c) / (1 + v / c * us[j]);
      dvMean[k[j]] += dv[j] / counts[k[j]];
    }
    for (var j = 0; j < n; j++) {
      final model =
          a[k[j]] -
          math.log(1 + v / c * us[j]) +
          (withG ? g * (ts[j] - accelerationAt) : 0);
      final r = lf[j] - model;
      rss += r * r;
      final x = dv[j] - dvMean[k[j]];
      svv += x * x;
    }
    final dof = math.max(1, n - nTracks - (withG ? 2 : 1));
    final s2 = rss / dof;
    // Overlapping frames are correlated: inflate by window/hop.
    final inflation = config.spectrogramWindow / config.spectrogramHop;
    final sigma = math.sqrt(s2 / svv * inflation);
    return _Fit(v, sigma, math.sqrt(rss / n));
  }

  static Float64List runningMedian(
    Float64List row,
    int halfWidth,
    int decimation,
  ) {
    final n = row.length;
    final anchors = <int>[for (var i = 0; i < n; i += decimation) i];
    if (anchors.last != n - 1) anchors.add(n - 1);
    final values = Float64List(anchors.length);
    final buffer = Float64List(2 * halfWidth + 1);
    for (var a = 0; a < anchors.length; a++) {
      final c = anchors[a];
      final from = math.max(0, c - halfWidth);
      final to = math.min(n - 1, c + halfWidth);
      final len = to - from + 1;
      for (var i = 0; i < len; i++) {
        buffer[i] = row[from + i];
      }
      final view = Float64List.sublistView(buffer, 0, len)..sort();
      values[a] = view[len ~/ 2];
    }
    final out = Float64List(n);
    for (var a = 0; a < anchors.length - 1; a++) {
      final x0 = anchors[a], x1 = anchors[a + 1];
      for (var i = x0; i <= x1; i++) {
        final w = (i - x0) / (x1 - x0);
        out[i] = values[a] * (1 - w) + values[a + 1] * w;
      }
    }
    return out;
  }
}

class _ActiveTrack {
  _ActiveTrack(double t, double f, this.lastRow) : points = [(t: t, f: f)];
  final List<({double t, double f})> points;
  int lastRow;
  double get lastF => points.last.f;
}

class _Fit {
  const _Fit(this.v, this.sigma, this.residual);
  final double v;
  final double sigma;
  final double residual;
}

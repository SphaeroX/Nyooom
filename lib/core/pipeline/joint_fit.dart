import 'dart:math' as math;
import 'dart:typed_data';

import '../config/nyooom_config.dart';
import 'analysis_setup.dart';
import 'doppler.dart';
import 'event_evaluator.dart';
import 'least_squares.dart';
import 'motion_fit.dart';

/// Result of the joint least-squares fit (technik.pdf 5.5, cost J).
class JointResult {
  const JointResult({
    required this.speed,
    required this.sigmaSpeed,
    required this.distance,
    required this.sigmaDistance,
    required this.t0,
    required this.converged,
  });

  /// Signed v in m/s.
  final double speed;
  final double sigmaSpeed;
  final double distance;
  final double sigmaDistance;
  final double t0;
  final bool converged;
}

/// Joint fit of v, d, t0 and ln f0_k to the TDOA block maxima, the tone
/// tracks and the lane-distance prior:
///
/// J = Σ w_i·[Δ_i − b/c·u(t_i) − Δ0]²/σ_Δ² + Σ [ln f_kj − ln f0_k +
/// ln(1 + v/c·u(t_j + δ))]²/σ_f² + (d − d_Spur)²/σ_d²
///
/// σ_Δ and σ_f come from the residuals of the single fits, inflated by the
/// overlap of blocks/frames; σ_d is the lateral spread. Start values from
/// the simple fusion ([startSpeed], d = |v|/|κ|, t0 of the TDOA fit).
/// Returns null without tone tracks (then the TDOA result stays).
JointResult? jointFit({
  required EventAnalysis analysis,
  required DopplerResult doppler,
  required AnalysisSetup setup,
  required NyooomConfig config,
  required double startSpeed,
  double? startT0,
}) {
  final fit = analysis.fit, correlogram = analysis.correlogram;
  final lane = analysis.record.distanceUsedM;
  if (fit == null || correlogram == null || lane == null) return null;
  if (!doppler.hasTone || doppler.tracks.isEmpty) return null;
  final c = setup.speedOfSound;
  final sign = fit.kappa >= 0 ? 1.0 : -1.0;

  // TDOA data: block maxima near the fitted curve.
  final ti = <double>[], di = <double>[], wi = <double>[];
  for (var i = 0; i < correlogram.rowCount; i++) {
    final t = analysis.windowStartS + correlogram.times[i];
    final r =
        correlogram.peakDelays[i] -
        analysis.fitter!.tdoaAt(t, kappa: fit.kappa, t0: fit.t0);
    if (r.abs() <= config.fitOutlierLimitS && correlogram.peakWeights[i] > 0) {
      ti.add(t);
      di.add(correlogram.peakDelays[i]);
      wi.add(correlogram.peakWeights[i]);
    }
  }
  if (ti.length < config.fitMinPoints) return null;
  final meanW = wi.reduce((a, b) => a + b) / wi.length;
  final sigmaTdoa =
      math.max(2e-6, fit.residualS) *
      math.sqrt(config.gccBlockLength / config.gccHop);
  final sigmaF =
      math.max(1e-4, doppler.residual ?? 1e-3) *
      math.sqrt(config.spectrogramWindow / config.spectrogramHop);
  final sigmaD = config.lateralSpreadM;
  final delta = doppler.offsetS;
  final tracks = doppler.tracks;

  double u(double t, double v, double d, double t0) =>
      directionCosineAt(t - t0, kappa: v / d, distance: d, speedOfSound: c);

  // Parameters: v (signed), d, t0, a_k = ln f0_k.
  final v0 = sign * startSpeed.abs();
  final d0 = startSpeed.abs() / fit.kappa.abs();
  final t00 = startT0 ?? fit.t0;
  final start = <double>[v0, d0, t00];
  for (final track in tracks) {
    var s = 0.0;
    for (final p in track.points) {
      s += math.log(p.f) + math.log(1 + v0 / c * u(p.t + delta, v0, d0, t00));
    }
    start.add(s / track.points.length);
  }

  Float64List residuals(Float64List p) {
    final v = p[0], d = p[1], t0 = p[2];
    final out = <double>[];
    for (var i = 0; i < ti.length; i++) {
      final model = setup.maxTdoa * u(ti[i], v, d, t0) + setup.channelOffset;
      out.add(math.sqrt(wi[i] / meanW) * (di[i] - model) / sigmaTdoa);
    }
    for (var k = 0; k < tracks.length; k++) {
      for (final pt in tracks[k].points) {
        final arg = 1 + v / c * u(pt.t + delta, v, d, t0);
        out.add((math.log(pt.f) - p[3 + k] + math.log(arg)) / sigmaF);
      }
    }
    out.add((d - lane) / sigmaD);
    return Float64List.fromList(out);
  }

  final result = levenbergMarquardt(
    residuals,
    Float64List.fromList(start),
    steps: [1e-4, 1e-4, 1e-5, for (final _ in tracks) 1e-7],
  );
  final p = result.parameters;
  final n = p.length;
  if (!(p[1] > 0) || !p[0].isFinite) return null;
  return JointResult(
    speed: p[0],
    sigmaSpeed: math.sqrt(result.covariance[0].abs()),
    distance: p[1],
    sigmaDistance: math.sqrt(result.covariance[n + 1].abs()),
    t0: p[2],
    converged: result.converged,
  );
}

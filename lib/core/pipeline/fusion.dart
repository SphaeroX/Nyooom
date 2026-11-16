import 'dart:math' as math;

import '../config/nyooom_config.dart';
import 'pass_record.dart';
import 'reasons.dart';

/// Class and reason of a measurement.
class QualityDecision {
  const QualityDecision(this.klasse, this.reason);
  final QualityClass klasse;
  final DowngradeReason? reason;
}

/// Central class logic (technik.pdf 5.6): an invalid TDOA track gives C;
/// otherwise A if a Doppler estimate exists that passed the acceleration
/// and distance checks, else B with the first failing reason.
QualityDecision classify({
  required DowngradeReason? trackReason,
  required bool hasTone,
  required bool accelerationDetected,
  required bool distanceCheckPassed,
}) {
  if (trackReason != null) return QualityDecision(QualityClass.c, trackReason);
  if (!hasTone) {
    return const QualityDecision(QualityClass.b, DowngradeReason.noTone);
  }
  if (accelerationDetected) {
    return const QualityDecision(QualityClass.b, DowngradeReason.acceleration);
  }
  if (!distanceCheckPassed) {
    return const QualityDecision(QualityClass.b, DowngradeReason.distanceCheck);
  }
  return const QualityDecision(QualityClass.a, null);
}

/// Inverse-variance weighted mean (technik.pdf 5.5).
({double v, double sigma}) weightedFusion({
  required double vT,
  required double sigmaT,
  required double vD,
  required double sigmaD,
}) {
  final wT = 1 / (sigmaT * sigmaT), wD = 1 / (sigmaD * sigmaD);
  return (v: (vT * wT + vD * wD) / (wT + wD), sigma: math.sqrt(1 / (wT + wD)));
}

class FusionResult {
  const FusionResult({
    required this.klasse,
    required this.reason,
    required this.v,
    required this.sigma,
    required this.dEst,
  });

  final QualityClass klasse;
  final DowngradeReason? reason;

  /// Result speed and uncertainty in m/s.
  final double v;
  final double sigma;

  /// d_est = v_D/|κ| in m, null without tone.
  final double? dEst;
}

/// Acceleration check (5.4), distance check and weighted fusion (5.5).
/// Speeds in m/s; [vD] null means no tone.
FusionResult fuse({
  required NyooomConfig config,
  required double vT,
  required double sigmaT,
  required double kappa,
  required double laneDistance,
  double? vD,
  double? sigmaD,
  double? vDWithAcceleration,
  bool frequencyRises = false,
}) {
  final hasTone = vD != null && sigmaD != null;
  // A tone that rises against the model changed at the source: the same
  // verdict as the acceleration regression (5.4).
  final acceleration =
      hasTone &&
      (frequencyRises ||
          (vDWithAcceleration != null &&
              (vDWithAcceleration - vD).abs() > config.accelerationCheckLimit));
  final dEst = hasTone ? vD / kappa.abs() : null;
  final distanceOk =
      dEst != null &&
      (dEst - laneDistance).abs() <=
          config.distanceCheckTolerance * laneDistance;
  final decision = classify(
    trackReason: null,
    hasTone: hasTone,
    accelerationDetected: acceleration,
    distanceCheckPassed: distanceOk,
  );
  if (decision.klasse == QualityClass.a) {
    final f = weightedFusion(vT: vT, sigmaT: sigmaT, vD: vD!, sigmaD: sigmaD!);
    return FusionResult(
      klasse: decision.klasse,
      reason: null,
      v: f.v,
      sigma: f.sigma,
      dEst: dEst,
    );
  }
  return FusionResult(
    klasse: decision.klasse,
    reason: decision.reason,
    v: vT,
    sigma: sigmaT,
    dEst: dEst,
  );
}

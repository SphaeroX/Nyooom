import 'dart:math' as math;
import 'dart:typed_data';

/// Signal model of one vehicle pass (technik.pdf 3.1 to 3.4).
///
/// The vehicle is a point source on a straight line at slant distance
/// [distance], passing the microphone pair at [t0] with constant signed
/// [speed] (positive in +x direction). Times without suffix are reception
/// times t; `...AtEmission` functions take the emission time te.
class PassByModel {
  const PassByModel({
    required this.speed,
    required this.distance,
    required this.t0,
    required this.micSpacing,
    required this.speedOfSound,
    this.channelOffset = 0,
  });

  /// Signed speed v in m/s.
  final double speed;

  /// Slant distance d in m.
  final double distance;

  /// Emission time of closest approach in s.
  final double t0;

  /// Effective microphone spacing b in m.
  final double micSpacing;

  /// Speed of sound c in m/s.
  final double speedOfSound;

  /// Channel offset Δ0 in s.
  final double channelOffset;

  /// κ = v/d in 1/s (technik.pdf 3.1).
  double get kappa => speed / distance;

  /// Largest TDOA b/c in s.
  double get maxTdoa => micSpacing / speedOfSound;

  /// Relative frequency jump (f_an − f_ab)/f_ab (technik.pdf 3.3/3.5).
  double get frequencyJump {
    final m = speed.abs() / speedOfSound;
    return (1 + m) / (1 - m) - 1;
  }

  /// Distance r(te) between source and microphone pair (3.1).
  double range(double emissionTime) {
    final x = speed * (emissionTime - t0);
    return math.sqrt(distance * distance + x * x);
  }

  /// Direction cosine u(te) (3.1).
  double directionCosineAtEmission(double emissionTime) {
    final k = kappa * (emissionTime - t0);
    return k / math.sqrt(1 + k * k);
  }

  /// Reception time t = te + r(te)/c (3.1).
  double receptionTime(double emissionTime) =>
      emissionTime + range(emissionTime) / speedOfSound;

  /// Inverse of [receptionTime], solved with Newton's method.
  double emissionTime(double receptionTime) =>
      solveEmissionTime(receptionTime, speed, distance, t0, speedOfSound);

  /// u at reception time t.
  double directionCosine(double receptionTime) =>
      directionCosineAtEmission(emissionTime(receptionTime));

  /// TDOA Δ(t) = b/c·u + Δ0 (technik.pdf 3.2).
  double tdoa(double receptionTime) =>
      maxTdoa * directionCosine(receptionTime) + channelOffset;

  /// Received frequency f = f0/(1 + v/c·u) (technik.pdf 3.3).
  double dopplerFrequency(double emittedFrequency, double receptionTime) =>
      emittedFrequency /
      (1 + speed / speedOfSound * directionCosine(receptionTime));
}

/// Solves te + sqrt(d² + (v·(te − t0))²)/c = t for te.
///
/// The left side is strictly increasing for |v| < c, so Newton's method from
/// te = t − d/c converges in a few steps.
double solveEmissionTime(
  double receptionTime,
  double speed,
  double distance,
  double t0,
  double speedOfSound,
) {
  var te = receptionTime - distance / speedOfSound;
  for (var i = 0; i < 30; i++) {
    final x = speed * (te - t0);
    final r = math.sqrt(distance * distance + x * x);
    final g = te + r / speedOfSound - receptionTime;
    final dg = 1 + speed * x / (r * speedOfSound);
    final step = g / dg;
    te -= step;
    if (step.abs() < 1e-13) break;
  }
  return te;
}

/// Interpolates [values] given on an emission-time grid onto reception
/// times (technik.pdf 3.1: model on a te grid, interpolated to t).
Float64List interpolateEmissionGrid({
  required List<double> emissionTimes,
  required List<double> values,
  required List<double> receptionTimes,
  required PassByModel model,
}) {
  final gridT = Float64List.fromList(
    emissionTimes.map(model.receptionTime).toList(),
  );
  final out = Float64List(receptionTimes.length);
  var j = 0;
  for (var i = 0; i < receptionTimes.length; i++) {
    final t = receptionTimes[i];
    if (t <= gridT.first) {
      out[i] = values.first;
      continue;
    }
    if (t >= gridT.last) {
      out[i] = values.last;
      continue;
    }
    if (gridT[j] > t) j = 0;
    while (gridT[j + 1] < t) {
      j++;
    }
    final w = (t - gridT[j]) / (gridT[j + 1] - gridT[j]);
    out[i] = values[j] * (1 - w) + values[j + 1] * w;
  }
  return out;
}

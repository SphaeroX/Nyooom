import 'dart:math' as math;

import '../model/acoustics.dart';
import 'scenarios.dart';

/// A lane of the simulated site.
class TrafficLane {
  const TrafficLane({required this.slantDistance, required this.direction});

  /// Slant distance of the lane centre in m.
  final double slantDistance;

  /// Direction of travel on this lane (+1 or −1).
  final int direction;
}

/// Deterministic random traffic for the simulation source.
///
/// Vehicles arrive with a minimum gap plus an exponential random part, drive
/// on a random lane (with some lateral spread), at normally distributed
/// speeds. A share of them is electric, some combustion cars accelerate.
class TrafficGenerator {
  TrafficGenerator({
    required this.lanes,
    this.seed = 1,
    this.minGapS = 6,
    this.meanExtraGapS = 8,
    this.meanSpeedKmh = 42,
    this.speedSpreadKmh = 8,
    this.electricShare = 0.35,
    this.warningToneShare = 0.3,
    this.acceleratingShare = 0.1,
    this.lateralSpreadM = 0.4,
    this.firstT0 = 5,
  }) : _random = math.Random(seed);

  final List<TrafficLane> lanes;
  final int seed;
  final double minGapS;
  final double meanExtraGapS;
  final double meanSpeedKmh;
  final double speedSpreadKmh;
  final double electricShare;
  final double warningToneShare;
  final double acceleratingShare;
  final double lateralSpreadM;
  final double firstT0;

  /// Emission-time span after which a vehicle has faded out completely.
  final double vehicleSpanS = 10;

  /// A vehicle is rendered while |t − t0| is below this span (vehicle span
  /// plus the largest sound travel time).
  final double audibleSpanS = 12;

  final math.Random _random;
  final List<VehiclePass> _schedule = [];

  /// All vehicles with t0 in [from, to).
  List<VehiclePass> passesBetween(double from, double to) {
    _extendTo(to);
    return _schedule.where((p) => p.t0 >= from && p.t0 < to).toList();
  }

  /// All vehicles that are audible somewhere in [from, to].
  List<VehiclePass> passesAffecting(double from, double to) {
    _extendTo(to + audibleSpanS);
    return _schedule
        .where((p) => p.t0 > from - audibleSpanS && p.t0 < to + audibleSpanS)
        .toList();
  }

  void _extendTo(double time) {
    while (_schedule.isEmpty || _schedule.last.t0 < time) {
      final t0 = _schedule.isEmpty
          ? firstT0
          : _schedule.last.t0 +
                minGapS -
                meanExtraGapS * math.log(1 - _random.nextDouble());
      _schedule.add(_vehicle(t0, _schedule.length));
    }
  }

  VehiclePass _vehicle(double t0, int index) {
    final lane = lanes[_random.nextInt(lanes.length)];
    final speedKmh = (meanSpeedKmh + speedSpreadKmh * _gauss())
        .clamp(15.0, 80.0)
        .toDouble();
    final distance = math.max(
      1.5,
      lane.slantDistance + lateralSpreadM * _gauss().clamp(-2.5, 2.5),
    );
    final electric = _random.nextDouble() < electricShare;
    final accelerating = _random.nextDouble() < acceleratingShare;
    final acceleration = accelerating ? (_random.nextBool() ? 0.6 : -0.6) : 0.0;
    final base = electric
        ? Scenarios.electric(
            speedKmh: speedKmh,
            distance: distance,
            direction: lane.direction,
            t0: t0,
            warningTone: _random.nextDouble() < warningToneShare,
            acceleration: acceleration,
            noiseRms: 0.06 + 0.04 * _random.nextDouble(),
          )
        : Scenarios.combustion(
            speedKmh: speedKmh,
            distance: distance,
            direction: lane.direction,
            t0: t0,
            acceleration: acceleration,
            fundamentalHz: 110 + 90 * _random.nextDouble(),
            toneLeadS: 0.1 * _random.nextDouble(),
            noiseRms: 0.1 + 0.1 * _random.nextDouble(),
            tone: _random.nextDouble() < 0.8,
          );
    return VehiclePass(
      kind: base.kind,
      speed: base.speed,
      distance: base.distance,
      t0: base.t0,
      acceleration: base.acceleration,
      noiseRms: base.noiseRms,
      tones: base.tones,
      toneLeadS: base.toneLeadS,
      noiseSeed: seed * 7919 + index,
      audibleSpanS: vehicleSpanS,
    );
  }

  double _gauss() {
    final u1 = 1 - _random.nextDouble();
    final u2 = _random.nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }

  /// Speed in km/h of [pass] (helper for UI and tests).
  static double speedKmh(VehiclePass pass) => toKmh(pass.speed.abs());
}

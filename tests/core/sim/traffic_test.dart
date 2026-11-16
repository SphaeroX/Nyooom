import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/core/sim/traffic.dart';
import 'package:test/test.dart';

void main() {
  const lanes = [
    TrafficLane(slantDistance: 4.1, direction: 1),
    TrafficLane(slantDistance: 7.2, direction: -1),
  ];

  test('schedule is deterministic and respects the minimum gap', () {
    final a = TrafficGenerator(lanes: lanes, seed: 4).passesBetween(0, 600);
    final b = TrafficGenerator(lanes: lanes, seed: 4).passesBetween(0, 600);
    expect(a.map((p) => p.t0), b.map((p) => p.t0));
    expect(a.length, greaterThan(20));
    for (var i = 1; i < a.length; i++) {
      expect(a[i].t0 - a[i - 1].t0, greaterThanOrEqualTo(6));
    }
  });

  test('vehicles drive on the lane that matches their direction', () {
    final passes = TrafficGenerator(
      lanes: lanes,
      seed: 2,
    ).passesBetween(0, 600);
    for (final p in passes) {
      final lane = p.speed > 0 ? lanes[0] : lanes[1];
      // Lateral spread sigma_d = 0.4 m (technik.pdf 5.5), clamped at 2.5 sigma.
      expect(p.distance, closeTo(lane.slantDistance, 1.0 + 1e-9));
    }
    expect(passes.where((p) => p.speed > 0), isNotEmpty);
    expect(passes.where((p) => p.speed < 0), isNotEmpty);
  });

  test('mixes electric and combustion cars with plausible speeds', () {
    final passes = TrafficGenerator(
      lanes: lanes,
      seed: 9,
    ).passesBetween(0, 900);
    expect(passes.where((p) => p.kind == VehicleKind.electric), isNotEmpty);
    expect(passes.where((p) => p.kind == VehicleKind.combustion), isNotEmpty);
    for (final p in passes) {
      expect(p.speed.abs() * 3.6, inInclusiveRange(15, 80));
      expect(p.noiseSeed, isNotNull);
    }
  });

  test('passesAffecting returns vehicles audible in a window', () {
    final gen = TrafficGenerator(lanes: lanes, seed: 4);
    final all = gen.passesBetween(0, 120);
    final some = gen.passesAffecting(30, 31);
    for (final p in all) {
      final audible =
          p.t0 > 30 - gen.audibleSpanS && p.t0 < 31 + gen.audibleSpanS;
      expect(some.contains(p), audible);
    }
  });
}

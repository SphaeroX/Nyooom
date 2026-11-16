import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/pipeline/least_squares.dart';
import 'package:test/test.dart';

void main() {
  test('fits an exponential decay and reports the covariance', () {
    final random = math.Random(1);
    final xs = List.generate(60, (i) => i * 0.1);
    final ys = [
      for (final x in xs)
        3 * math.exp(-0.7 * x) + 0.01 * (random.nextDouble() - 0.5),
    ];
    const sigma = 0.01 / 3.4641; // std of uniform(-0.005, 0.005)
    final r = levenbergMarquardt(
      (p) => Float64List.fromList([
        for (var i = 0; i < xs.length; i++)
          (ys[i] - p[0] * math.exp(-p[1] * xs[i])) / sigma,
      ]),
      Float64List.fromList([1, 0.2]),
    );
    expect(r.converged, isTrue);
    expect(r.parameters[0], closeTo(3, 0.01));
    expect(r.parameters[1], closeTo(0.7, 0.01));
    final sd0 = math.sqrt(r.covariance[0]);
    expect(sd0, greaterThan(0));
    expect(sd0, lessThan(0.01));
  });

  test('solves a small linear system', () {
    final x = solveLinear(
      [
        [4, 1, 0],
        [1, 3, 1],
        [0, 1, 2],
      ],
      [1, 2, 3],
    );
    expect(4 * x[0] + x[1], closeTo(1, 1e-12));
    expect(x[0] + 3 * x[1] + x[2], closeTo(2, 1e-12));
    expect(x[1] + 2 * x[2], closeTo(3, 1e-12));
  });
}

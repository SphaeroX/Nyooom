import 'dart:math' as math;
import 'dart:typed_data';

/// Result of [levenbergMarquardt].
class LmResult {
  const LmResult({
    required this.parameters,
    required this.covariance,
    required this.cost,
    required this.converged,
  });

  final Float64List parameters;

  /// Row-major (JᵀJ)⁻¹ at the solution; with residuals already divided by
  /// their standard deviation this is the parameter covariance.
  final Float64List covariance;

  /// Sum of squared residuals.
  final double cost;
  final bool converged;
}

/// Solves A·x = b by Gaussian elimination with partial pivoting.
List<double> solveLinear(List<List<double>> a, List<double> b) {
  final n = b.length;
  final m = [
    for (var i = 0; i < n; i++) [...a[i], b[i]],
  ];
  for (var c = 0; c < n; c++) {
    var pivot = c;
    for (var r = c + 1; r < n; r++) {
      if (m[r][c].abs() > m[pivot][c].abs()) pivot = r;
    }
    final tmp = m[c];
    m[c] = m[pivot];
    m[pivot] = tmp;
    final p = m[c][c];
    if (p == 0) throw StateError('singular matrix');
    for (var r = 0; r < n; r++) {
      if (r == c) continue;
      final f = m[r][c] / p;
      if (f == 0) continue;
      for (var k = c; k <= n; k++) {
        m[r][k] -= f * m[c][k];
      }
    }
  }
  return [for (var i = 0; i < n; i++) m[i][n] / m[i][i]];
}

/// General Levenberg–Marquardt with a numeric (central-difference)
/// Jacobian for small parameter counts (Task_19).
LmResult levenbergMarquardt(
  Float64List Function(Float64List p) residuals,
  Float64List start, {
  List<double>? steps,
  int maxIterations = 60,
}) {
  final n = start.length;
  final p = Float64List.fromList(start);
  final h = [
    for (var i = 0; i < n; i++) steps?[i] ?? math.max(1e-6, 1e-6 * p[i].abs()),
  ];
  double costOf(Float64List r) {
    var c = 0.0;
    for (final v in r) {
      c += v * v;
    }
    return c;
  }

  List<Float64List> jacobian(Float64List at) {
    final cols = <Float64List>[];
    for (var i = 0; i < n; i++) {
      final plus = Float64List.fromList(at)..[i] += h[i];
      final minus = Float64List.fromList(at)..[i] -= h[i];
      final rp = residuals(plus), rm = residuals(minus);
      cols.add(
        Float64List.fromList([
          for (var k = 0; k < rp.length; k++) (rp[k] - rm[k]) / (2 * h[i]),
        ]),
      );
    }
    return cols;
  }

  List<List<double>> normal(List<Float64List> j) => [
    for (var a = 0; a < n; a++)
      [
        for (var b = 0; b < n; b++)
          () {
            var s = 0.0;
            for (var k = 0; k < j[a].length; k++) {
              s += j[a][k] * j[b][k];
            }
            return s;
          }(),
      ],
  ];

  var r = residuals(p);
  var cost = costOf(r);
  var lambda = 1e-3;
  var converged = false;
  for (var iter = 0; iter < maxIterations; iter++) {
    final j = jacobian(p);
    final a = normal(j);
    final g = [
      for (var i = 0; i < n; i++)
        () {
          var s = 0.0;
          for (var k = 0; k < r.length; k++) {
            s += j[i][k] * r[k];
          }
          return s;
        }(),
    ];
    var improved = false;
    while (lambda < 1e10) {
      final damped = [
        for (var i = 0; i < n; i++)
          [
            for (var k = 0; k < n; k++)
              a[i][k] + (i == k ? lambda * (a[i][i] == 0 ? 1 : a[i][i]) : 0),
          ],
      ];
      List<double> dp;
      try {
        dp = solveLinear(damped, [for (final v in g) -v]);
      } on StateError {
        lambda *= 10;
        continue;
      }
      final trial = Float64List.fromList([
        for (var i = 0; i < n; i++) p[i] + dp[i],
      ]);
      final tr = residuals(trial);
      final tc = costOf(tr);
      if (tc.isFinite && tc < cost) {
        final relative = (cost - tc) / math.max(cost, 1e-300);
        p.setAll(0, trial);
        r = tr;
        cost = tc;
        lambda = math.max(lambda / 10, 1e-12);
        improved = true;
        if (relative < 1e-10) converged = true;
        break;
      }
      lambda *= 10;
    }
    if (!improved) {
      converged = true;
      break;
    }
    if (converged) break;
  }
  final j = jacobian(p);
  final a = normal(j);
  final cov = Float64List(n * n);
  try {
    for (var c = 0; c < n; c++) {
      final col = solveLinear(a, [
        for (var i = 0; i < n; i++) i == c ? 1.0 : 0.0,
      ]);
      for (var i = 0; i < n; i++) {
        cov[i * n + c] = col[i];
      }
    }
  } on StateError {
    cov.fillRange(0, cov.length, double.infinity);
  }
  return LmResult(
    parameters: p,
    covariance: cov,
    cost: cost,
    converged: converged,
  );
}

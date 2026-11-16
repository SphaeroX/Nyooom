import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/pipeline/fusion.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

void main() {
  test('weighted mean of technik.pdf 6.2: 2.7 and 1.9 km/h give about 1.6', () {
    final f = weightedFusion(
      vT: fromKmh(30),
      sigmaT: fromKmh(2.7),
      vD: fromKmh(30),
      sigmaD: fromKmh(1.9),
    );
    expect(toKmh(f.sigma), closeTo(1.6, 0.06));
    final g = weightedFusion(vT: 10, sigmaT: 1, vD: 12, sigmaD: 1);
    expect(g.v, closeTo(11, 1e-12));
  });

  group('classify (technik.pdf 5.6)', () {
    final cases =
        <(DowngradeReason?, bool, bool, bool, QualityClass, DowngradeReason?)>[
          // track reason, tone, acceleration, distance ok -> class, reason
          (null, true, false, true, QualityClass.a, null),
          (null, false, false, true, QualityClass.b, DowngradeReason.noTone),
          (null, false, true, false, QualityClass.b, DowngradeReason.noTone),
          (
            null,
            true,
            true,
            true,
            QualityClass.b,
            DowngradeReason.acceleration,
          ),
          (
            null,
            true,
            true,
            false,
            QualityClass.b,
            DowngradeReason.acceleration,
          ),
          (
            null,
            true,
            false,
            false,
            QualityClass.b,
            DowngradeReason.distanceCheck,
          ),
          for (final r in [
            DowngradeReason.overlap,
            DowngradeReason.notMonotonic,
            DowngradeReason.residual,
            DowngradeReason.outOfRange,
            DowngradeReason.clipping,
          ]) ...[
            (r, true, false, true, QualityClass.c, r),
            (r, false, true, false, QualityClass.c, r),
          ],
        ];
    for (final (track, tone, accel, distanceOk, klasse, reason) in cases) {
      test('$track tone=$tone accel=$accel distanceOk=$distanceOk', () {
        final d = classify(
          trackReason: track,
          hasTone: tone,
          accelerationDetected: accel,
          distanceCheckPassed: distanceOk,
        );
        expect(d.klasse, klasse);
        expect(d.reason, reason);
      });
    }
  });

  test('fuse applies the acceleration and distance checks', () {
    FusionResult run({
      double vD = 11,
      double vDg = 11.2,
      double kappa = 2.2,
      double lane = 5,
    }) => fuse(
      config: config,
      vT: 11,
      sigmaT: 0.8,
      kappa: kappa,
      laneDistance: lane,
      vD: vD,
      sigmaD: 0.5,
      vDWithAcceleration: vDg,
    );
    final a = run();
    expect(a.klasse, QualityClass.a);
    expect(a.dEst, closeTo(11 / 2.2, 1e-12));
    expect(run(vDg: 11 + fromKmh(2.5)).reason, DowngradeReason.acceleration);
    // d_est = 11/2.2 = 5 m against 7 m lane: 29 % off.
    expect(run(lane: 7).reason, DowngradeReason.distanceCheck);
    expect(run(lane: 6.2).klasse, QualityClass.a); // 19 % off
    final noTone = fuse(
      config: config,
      vT: 11,
      sigmaT: 0.8,
      kappa: 2.2,
      laneDistance: 5,
    );
    expect(noTone.klasse, QualityClass.b);
    expect(noTone.v, 11);
    expect(noTone.dEst, isNull);
  });
}

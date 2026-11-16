import 'dart:math' as math;

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/reference/reference_track.dart';
import 'package:nyooom/core/validation/validation.dart';
import 'package:test/test.dart';

const config = NyooomConfig();
const siteLat = 50.0, siteLon = 8.0;
const metresPerDegLat = 111195.0;
final metresPerDegLon = 111195.0 * math.cos(50 * math.pi / 180);

/// Drive along north-south line 6 m east of the site at [speed] m/s,
/// passing the site at [passMs]; [north] = direction of travel.
List<ReferencePoint> drive(
  int passMs,
  double speed, {
  bool north = true,
  int fromS = -20,
  int toS = 20,
  double offsetMs = 300,
}) => [
  for (var s = fromS; s <= toS; s++)
    ReferencePoint(
      timeUtcMs: passMs + s * 1000 + offsetMs.round(),
      lat:
          siteLat +
          (north ? 1 : -1) * speed * (s + offsetMs / 1000) / metresPerDegLat,
      lon: siteLon + 6 / metresPerDegLon,
      speed: speed,
    ),
];

PassRecord rec(
  int zeit,
  double? v, {
  QualityClass k = QualityClass.b,
  int dir = 1,
  DowngradeReason? reason,
}) => PassRecord(
  zeitUtcMs: zeit,
  offsetS: 0,
  richtung: dir,
  klasse: k,
  v: v,
  sigmaV: v == null ? null : 2,
  vLaufzeit: v,
  vDoppler: null,
  kappa: 1,
  dEst: null,
  nToene: 0,
  restLaufzeitUs: 5,
  pegel: 20,
  dauer: 1,
  reason: reason,
  laneIndex: 0,
  distanceUsedM: 5,
);

void main() {
  test('closest approach to the site is found between GPS samples', () {
    final track = ReferenceTrack(
      name: 't',
      source: ReferenceSource.logger,
      points: [...drive(100000, 10), ...drive(200000, 12, north: false)],
    );
    final passes = closestApproaches(
      track,
      siteLat: siteLat,
      siteLon: siteLon,
      config: config,
    );
    expect(passes, hasLength(2));
    expect(passes[0].timeUtcMs, closeTo(100000, 60));
    expect(passes[0].distanceM, closeTo(6, 0.5));
    expect(passes[0].referenceSpeed, closeTo(10, 1e-9));
    expect(passes[1].timeUtcMs, closeTo(200000, 60));
    expect(passes[1].bearingDeg, closeTo(180, 1));
    expect(passes[0].bearingDeg, closeTo(0, 1));
  });

  test('matching with clock offset and distractors', () {
    final refs = [
      const ReferencePassage(
        timeUtcMs: 100000,
        referenceSpeed: 10,
        distanceM: 6,
        bearingDeg: 0,
      ),
      const ReferencePassage(
        timeUtcMs: 200000,
        referenceSpeed: 12,
        distanceM: 6,
        bearingDeg: 180,
      ),
      const ReferencePassage(
        timeUtcMs: 300000,
        referenceSpeed: 9,
        distanceM: 6,
        bearingDeg: 0,
      ),
    ];
    final records = [
      rec(98500, 36), // 1.5 s early: matched
      rec(150000, 50), // distractor
      rec(201000, 44, dir: -1),
      rec(305000, 30), // 5 s off: not matched
    ];
    final m = matchReferences(refs, records, config: config);
    expect(m.matches, hasLength(2));
    expect(m.matches[0].record.zeitUtcMs, 98500);
    expect(m.matches[1].reference.timeUtcMs, 200000);
    expect(m.unmatchedReferences.single.timeUtcMs, 300000);
    expect(m.unmatchedRecords.map((r) => r.zeitUtcMs), [150000, 305000]);
  });

  test('error figures against hand calculation', () {
    final matches = [
      for (final (vRef, vMeas, k) in [
        (30.0, 31.0, QualityClass.a),
        (30.0, 29.0, QualityClass.a),
        (50.0, 52.0, QualityClass.b),
        (50.0, 48.0, QualityClass.b),
        (50.0, null, QualityClass.c),
      ])
        ValidationMatch(
          reference: ReferencePassage(
            timeUtcMs: 0,
            referenceSpeed: vRef / 3.6,
            distanceM: 5,
            bearingDeg: 0,
          ),
          record: rec(
            0,
            vMeas,
            k: k,
            reason: k == QualityClass.c ? DowngradeReason.residual : null,
          ),
        ),
    ];
    final r = ValidationReport.from(
      matches,
      config: config,
      plusXBearingDeg: 0,
    );
    expect(r.all.count, 4);
    expect(r.all.meanError, closeTo(0, 1e-12));
    expect(r.byClass[QualityClass.a]!.sd, closeTo(math.sqrt(2), 1e-12));
    expect(r.byClass[QualityClass.b]!.sd, closeTo(math.sqrt(8), 1e-12));
    expect(r.byStep[30]!.meanError, closeTo(0, 1e-9));
    expect(r.shareC, closeTo(0.2, 1e-12));
    expect(r.directionShare, 1);
  });

  group('acceptance (technik.pdf 8)', () {
    ValidationReport report({
      double bias = 0,
      double spreadA = 1,
      double spreadB = 2,
      int classC = 0,
      double trend = 0,
      int wrongDirection = 0,
    }) {
      final matches = <ValidationMatch>[];
      var i = 0;
      for (final step in [20.0, 30.0, 40.0, 50.0]) {
        // 4 × A and 4 × B per step, errors ±spread symmetric per class.
        for (var k = 0; k < 8; k++) {
          final klasse = k.isEven ? QualityClass.a : QualityClass.b;
          final spread = klasse == QualityClass.a ? spreadA : spreadB;
          final sign = (k ~/ 2).isEven ? 1 : -1;
          final v = step + bias + trend * (step - 35) + sign * spread;
          matches.add(
            ValidationMatch(
              reference: ReferencePassage(
                timeUtcMs: i * 1000,
                referenceSpeed: step / 3.6,
                distanceM: 5,
                bearingDeg: 0,
              ),
              record: rec(
                i * 1000,
                v,
                k: klasse,
                dir: i < wrongDirection ? -1 : 1,
              ),
            ),
          );
          i++;
        }
      }
      for (var c = 0; c < classC; c++) {
        matches.add(
          ValidationMatch(
            reference: const ReferencePassage(
              timeUtcMs: 0,
              referenceSpeed: 10,
              distanceM: 5,
              bearingDeg: 0,
            ),
            record: rec(
              0,
              null,
              k: QualityClass.c,
              reason: DowngradeReason.residual,
            ),
          ),
        );
      }
      return ValidationReport.from(matches, config: config, plusXBearingDeg: 0);
    }

    Map<AcceptanceCriterion, bool?> check(ValidationReport r) => {
      for (final c in r.acceptance(config)) c.criterion: c.passed,
    };

    test('a clean data set passes everything', () {
      expect(check(report()).values.every((p) => p == true), isTrue);
    });

    test('mean deviation: 0.9 passes, 1.1 fails', () {
      expect(check(report(bias: 0.9))[AcceptanceCriterion.meanError], isTrue);
      expect(check(report(bias: 1.1))[AcceptanceCriterion.meanError], isFalse);
    });

    test('per step and trend', () {
      expect(check(report(trend: 0.04))[AcceptanceCriterion.stepError], isTrue);
      expect(
        check(report(trend: 0.07))[AcceptanceCriterion.stepError],
        isFalse,
      );
    });

    test('spread of class A and B', () {
      expect(check(report(spreadA: 2.9))[AcceptanceCriterion.sdClassA], isTrue);
      expect(
        check(report(spreadA: 3.1))[AcceptanceCriterion.sdClassA],
        isFalse,
      );
      // Sample sd of 16 values ±s is s·√(16/15).
      expect(check(report(spreadB: 4.8))[AcceptanceCriterion.sdClassB], isTrue);
      expect(
        check(report(spreadB: 5.2))[AcceptanceCriterion.sdClassB],
        isFalse,
      );
    });

    test('share of class C', () {
      // 32 valid + 13 C = 28.9 %, 14 C = 30.4 %.
      expect(check(report(classC: 13))[AcceptanceCriterion.shareC], isTrue);
      expect(check(report(classC: 14))[AcceptanceCriterion.shareC], isFalse);
    });

    test('direction recognised in at least 99 %', () {
      expect(check(report())[AcceptanceCriterion.direction], isTrue);
      expect(
        check(report(wrongDirection: 1))[AcceptanceCriterion.direction],
        isFalse,
      );
      final r = report(wrongDirection: 1);
      expect(r.directionShare, closeTo(31 / 32, 1e-12));
    });

    test('direction is undetermined without the site bearing', () {
      final r = ValidationReport.from(
        report().matches,
        config: config,
        plusXBearingDeg: null,
      );
      expect(check(r)[AcceptanceCriterion.direction], isNull);
    });
  });
}

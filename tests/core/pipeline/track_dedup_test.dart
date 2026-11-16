import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/pipeline/track_dedup.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

PassRecord record(
  double t0,
  int direction, {
  QualityClass klasse = QualityClass.b,
  bool withFit = true,
}) => PassRecord(
  zeitUtcMs: (t0 * 1000).round(),
  offsetS: t0,
  richtung: withFit ? direction : 0,
  klasse: klasse,
  v: klasse == QualityClass.c ? null : 40,
  sigmaV: klasse == QualityClass.c ? null : 2,
  vLaufzeit: klasse == QualityClass.c ? null : 40,
  vDoppler: null,
  kappa: withFit ? direction * 2.0 : null,
  dEst: null,
  nToene: 0,
  restLaufzeitUs: 3,
  pegel: 20,
  dauer: 1,
  reason: klasse == QualityClass.c
      ? DowngradeReason.overlap
      : DowngradeReason.noTone,
  laneIndex: 0,
  distanceUsedM: 5,
);

void main() {
  test('the same track from two windows is reported once', () {
    final dedup = TrackDeduplicator(config: config);
    expect(dedup.accept(record(10.00, 1)), isTrue);
    expect(dedup.accept(record(10.04, 1)), isFalse);
    expect(dedup.accept(record(9.7, 1)), isFalse);
  });

  test('other direction or a later vehicle is a new vehicle', () {
    final dedup = TrackDeduplicator(config: config);
    expect(dedup.accept(record(10, 1)), isTrue);
    expect(dedup.accept(record(10.1, -1)), isTrue);
    expect(
      dedup.accept(record(10 + config.duplicateWindowS + 0.01, 1)),
      isTrue,
    );
  });

  test('a rejected event never hides a valid measurement', () {
    final dedup = TrackDeduplicator(config: config);
    expect(dedup.accept(record(10, 1, klasse: QualityClass.c)), isTrue);
    expect(dedup.accept(record(10.02, 1)), isTrue);
    // A rejected fit of a vehicle that was already measured is a repeat.
    expect(dedup.accept(record(10.05, 1, klasse: QualityClass.c)), isFalse);
    // Rejected without a track (clipping, unresolved overlap): always kept.
    expect(
      dedup.accept(record(10.03, 1, klasse: QualityClass.c, withFit: false)),
      isTrue,
    );
  });
}

import 'dart:io';

import 'package:nyooom/audio/wav.dart';
import 'package:nyooom/core/collect/collection_manifest.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/data/collection_evaluation.dart';
import 'package:test/test.dart';

// Regression tests on short excerpts of the first real recording
// (2026-11-23): window sill, microphones 2.5 m above the road and about
// 3 m from it, two wireless microphones 15 cm apart, 2 °C, 30 km/h zone.
// There is no reference speed, so the tests check what was heard (car or
// not, direction) and that nothing is invented, not the speed itself.

const config = NyooomConfig();

/// b and Δ0 as learned from the passes of that recording
/// (`tool/evaluate_collection.dart --b-schaetzen`).
final setup = AnalysisSetup(
  micSpacing: 0.142,
  channelOffset: -7.4e-6,
  swapChannels: false,
  speedOfSound: speedOfSound(2),
  lanes: [
    LaneGeometry(
      index: 0,
      direction: 0,
      slantDistance: slantDistance(3, 2.5 - config.sourceHeightM),
    ),
  ],
  speedLimitKmh: 30,
  startedAtUtcMs: 0,
);

ClipEvaluation evaluate(
  String file, {
  required double peakTimeS,
  required double levelDb,
  required bool overlap,
}) {
  final wav = decodeWav(File('tests/fixtures/$file').readAsBytesSync());
  return evaluateClip(
    deinterleavePcm16(wav.samples),
    ClipEntry(
      file: file,
      startS: 0,
      peakTimeS: peakTimeS,
      durationS: wav.frameCount / wav.sampleRate,
      peakLevelDb: levelDb,
      floorDb: 0,
      eventDurationS: 5,
      overlap: overlap,
    ),
    config: config,
    setup: setup,
  );
}

void main() {
  test('a real car leaves a valid track', () {
    // Clip 11 of the collection, 30.6 dB above the floor. The source is a
    // car 4 m long at 4 m distance, not a point: next to the closest
    // approach the correlation maximum sits up to 40 µs beside the curve.
    final result = evaluate(
      'fenster_auto_011.wav',
      peakTimeS: 2,
      levelDb: 30.6,
      overlap: false,
    );
    final record = result.vehicle;
    expect(record, isNotNull, reason: '${result.records.firstOrNull?.grund}');
    expect(record!.richtung, -1);
    // Closest approach as seen in the correlogram (zero crossing at 2.05 s).
    expect(record.offsetS, closeTo(2.05, 0.1));
    // 15 to 45 km/h for the stated geometry; the true speed is unknown.
    expect(record.v, inInclusiveRange(15, 45));
  });

  test('tyre noise without a tone gives no Doppler speed', () {
    // Clip 3: no tone track, and the sharpness of variant 2 is flat over
    // the candidates (5 to 7 below 30 km/h, falling above). The largest of
    // these values is not a tone.
    final result = evaluate(
      'fenster_auto_003.wav',
      peakTimeS: 2.5,
      levelDb: 22.6,
      overlap: true,
    );
    final record = result.vehicle;
    expect(record, isNotNull);
    expect(record!.richtung, 1);
    expect(record.vDoppler, isNull);
    expect(record.klasse, QualityClass.b);
    expect(record.reason, DowngradeReason.noTone);
  });

  test('the fading sound of a car that has passed is not a vehicle', () {
    // Clip 24, labelled "kein Auto": a source at a fixed direction.
    final result = evaluate(
      'fenster_kein_auto_024.wav',
      peakTimeS: 2,
      levelDb: 11.7,
      overlap: true,
    );
    expect(result.vehicleFound, isFalse);
  });
}

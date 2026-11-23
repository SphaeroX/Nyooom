import 'dart:convert';
import 'dart:io';

import 'package:nyooom/audio/wav.dart';
import 'package:nyooom/core/collect/collection_manifest.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/data/collection_evaluation.dart';
import 'package:test/test.dart';

// The clips have no tone: without Doppler variant 2 the search for one
// does not slow the suite down.
const config = NyooomConfig(dopplerVariant2: 0);

/// Device spacing of the simulated collection, deliberately not the
/// nominal 0.15 m.
const trueSpacing = 0.144;

ClipEntry entry(String file, ClipLabel label, {double startS = 0}) => ClipEntry(
  file: file,
  startS: startS,
  peakTimeS: startS + 4,
  durationS: 8,
  peakLevelDb: -30,
  floorDb: -60,
  eventDurationS: 3,
  overlap: false,
  label: label,
);

void writeClip(Directory dir, String file, StereoBlock signal) {
  File('${dir.path}/$file').writeAsBytesSync(
    encodeWavPcm16(interleavePcm16(signal), channels: 2, sampleRate: 48000),
  );
}

void main() {
  late Directory dir;
  late double speedOfSound;

  setUpAll(() {
    dir = Directory.systemTemp.createTempSync('nyooom_collection_eval');
    final car = Scenarios.render(
      Scenarios.electric(speedKmh: 36, distance: 4, direction: -1),
      micSpacing: trueSpacing,
    );
    speedOfSound = car.truths.single.speedOfSound;
    writeClip(dir, 'clip_001.wav', car.signal);
    // Background noise only: something else raised the level.
    final noise = PassBySimulator(
      Scenarios.setup(micSpacing: trueSpacing, backgroundRms: 0.01, seed: 5),
    ).render(8, const []);
    writeClip(dir, 'clip_002.wav', noise.signal);
    final manifest = CollectionManifest(
      id: 1,
      createdAtUtcMs: 1,
      source: 'live',
      deviceModel: 'Test',
      inputDevice: 'intern',
      sampleRate: 48000,
      recordedS: 200,
      clips: [
        // The clip was cut 100 s into the recording.
        entry('clip_001.wav', ClipLabel.vehicle, startS: 100),
        entry('clip_002.wav', ClipLabel.noVehicle, startS: 150),
      ],
    );
    File('${dir.path}/collection.json')
        .writeAsStringSync(jsonEncode(manifest.toJson()));
  });

  tearDownAll(() => dir.deleteSync(recursive: true));

  AnalysisSetup setup(double micSpacing) => AnalysisSetup(
    micSpacing: micSpacing,
    channelOffset: 0,
    swapChannels: false,
    speedOfSound: speedOfSound,
    lanes: const [LaneGeometry(index: 0, direction: 0, slantDistance: 4)],
    speedLimitKmh: 30,
    startedAtUtcMs: 0,
  );

  test('evaluates every clip against its label', () {
    final result = evaluateCollection(
      dir,
      config: config,
      setup: setup(trueSpacing),
    );
    expect(result.clips, hasLength(2));
    expect(result.vehicleClips, 1);
    expect(result.vehiclesFound, 1);
    expect(result.noVehicleClips, 1);
    expect(result.falseVehicles, 0);

    final car = result.clips.first;
    expect(car.clip.file, 'clip_001.wav');
    expect(car.vehicleFound, isTrue);
    final record = car.vehicle!;
    expect(record.klasse, isNot(QualityClass.c));
    expect(record.richtung, -1);
    // Tolerance of the TDOA speed for a point source (technik.pdf 8: 3 km/h
    // standard deviation in class A, 5 in class B).
    expect(record.v, closeTo(36, 3));
    // Times count from the start of the clip, not of the recording.
    expect(record.offsetS, closeTo(4, 0.1));

    final noise = result.clips.last;
    expect(noise.vehicleFound, isFalse);
    expect(noise.vehicle, isNull);
  });

  test('reports the effective spacing found in the passes', () {
    final result = evaluateCollection(dir, config: config, setup: setup(0.15));
    expect(result.plateau, isNotNull);
    expect(result.plateau!.micSpacing, closeTo(trueSpacing, 0.003));
    expect(result.clips.last.plateau, isNull);
  });

  test('missing manifest is reported', () {
    final empty = Directory.systemTemp.createTempSync('nyooom_empty');
    addTearDown(() => empty.deleteSync(recursive: true));
    expect(
      () => evaluateCollection(empty, config: config, setup: setup(0.15)),
      throwsA(isA<FileSystemException>()),
    );
  });
}

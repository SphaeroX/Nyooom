import 'dart:io';

import 'package:nyooom/audio/wav.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/data/series_analysis.dart';
import 'package:test/test.dart';

// A series recorded with b = 0.144 m and Δ0 = −8 µs, evaluated with the
// uncalibrated defaults (0.15 m, 0), as the first real recording was.

// Kept short for the suite: three passes are enough to learn here, and the
// Doppler steps, which find nothing in these passes without a tone, are
// made cheap (no variant 2, coarse spectrogram).
const config = NyooomConfig(
  plateauMinCount: 3,
  dopplerVariant2: 0,
  spectrogramHop: 2048,
);
const trueSpacing = 0.144;
const trueOffset = -8e-6;
const distance = 4.0;
const gapS = 10.0;

typedef Series = ({File file, AnalysisSetup setup, List<VehiclePass> passes});

Future<Series> series(Directory dir, int count) async {
  final sim = Scenarios.setup(
    micSpacing: trueSpacing,
    channelOffset: trueOffset,
    backgroundRms: 0.002,
  );
  final passes = [
    for (var i = 0; i < count; i++)
      VehiclePass(
        speed: (i.isEven ? 1 : -1) * fromKmh(30.0 + 6 * i),
        distance: distance,
        t0: 6 + gapS * i,
        noiseRms: 0.1,
        noiseSeed: i,
        audibleSpanS: 9,
      ),
  ];
  final rec = PassBySimulator(sim).render(12 + gapS * (count - 1), passes);
  final file = File('${dir.path}/audio_$count.wav');
  await file.writeAsBytes(
    encodeWavPcm16(interleavePcm16(rec.signal), channels: 2, sampleRate: 48000),
  );
  return (
    file: file,
    passes: passes,
    setup: AnalysisSetup(
      micSpacing: 0.15,
      channelOffset: 0,
      swapChannels: false,
      speedOfSound: sim.speedOfSound,
      speedLimitKmh: 50,
      startedAtUtcMs: 0,
      lanes: const [
        LaneGeometry(index: 0, direction: 0, slantDistance: distance),
      ],
    ),
  );
}

/// Mean relative error of κ against the simulated passes.
double kappaError(List<PassRecord> records, List<VehiclePass> truth) {
  expect(records, hasLength(truth.length));
  var sum = 0.0;
  for (var i = 0; i < truth.length; i++) {
    final kappa = truth[i].speed / truth[i].distance;
    sum += (records[i].kappa! / kappa - 1).abs();
  }
  return sum / truth.length;
}

void main() {
  late Directory dir;
  late Series three;
  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('nyooom_spacing');
    three = await series(dir, 3);
  });
  tearDownAll(() => dir.delete(recursive: true));

  test('enough passes teach spacing and offset', () async {
    final progress = <String>[];
    final learning = await learnSeriesSpacing(
      wavPath: three.file.path,
      setup: three.setup,
      config: config,
      onProgress: (p) => progress.add(p.phase),
    );
    expect(learning.active, isTrue);
    expect(learning.passCount, 3);
    // 1 % of b after the second round (plateau_calibration_test).
    expect(learning.learned!.micSpacing, closeTo(trueSpacing, 0.0015));
    expect(learning.learned!.channelOffset, closeTo(trueOffset, 3e-6));
    expect(learning.calibratedSpacing, 0.15);
    expect(progress, contains(startsWith('Mikrofonabstand')));
  });

  test('the evaluation with learning gets the speeds right', () async {
    final learned = await analyseSeriesInBackground(
      wavPath: three.file.path,
      setup: three.setup,
      config: config,
      learnSpacing: true,
    ).last;
    expect(learned.learning!.active, isTrue);
    expect(learned.learning!.learned!.micSpacing, closeTo(trueSpacing, 0.0015));
    // Evaluated with the assumed 0.15 m, κ is off by more than 5 %; with
    // the learned spacing the fit is within the 3 % of motion_fit_test.
    expect(kappaError(learned.result!, three.passes), lessThan(0.03));
  });

  test('too few passes: the result stays as it was', () async {
    final s = await series(dir, 2);
    final plain = await runSeriesAnalysis(
      wavPath: s.file.path,
      setup: s.setup,
      config: config,
    );
    expect(kappaError(plain, s.passes), greaterThan(0.05));
    final learned = await analyseSeriesInBackground(
      wavPath: s.file.path,
      setup: s.setup,
      config: config,
      learnSpacing: true,
    ).last;
    expect(learned.learning!.active, isFalse);
    expect(learned.learning!.passCount, 2);
    expect(
      learned.result!.map((r) => r.toJson()),
      plain.map((r) => r.toJson()),
    );
  });
}

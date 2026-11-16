import 'dart:io';

import 'package:nyooom/audio/wav.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/event_evaluator.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/data/series_analysis.dart';
import 'package:test/test.dart';

void main() {
  const config = NyooomConfig();

  test('file analysis in chunks equals the in-memory evaluation', () async {
    final dir = await Directory.systemTemp.createTemp('nyooom_analysis');
    final sim = Scenarios.setup(backgroundRms: 0.002);
    final passes = [
      for (final (i, kmh) in [(0, 30.0), (1, 45.0)])
        VehiclePass(
          speed: (i.isEven ? 1 : -1) * kmh / 3.6,
          distance: i.isEven ? 4.1 : 7.3,
          t0: 6 + 11.0 * i,
          noiseRms: 0.1,
          noiseSeed: i,
          audibleSpanS: 9,
        ),
    ];
    final rec = PassBySimulator(sim).render(24, passes);
    final file = File('${dir.path}/audio.wav');
    await file.writeAsBytes(
      encodeWavPcm16(
        interleavePcm16(rec.signal),
        channels: 2,
        sampleRate: 48000,
      ),
    );
    final setup = AnalysisSetup(
      micSpacing: sim.micSpacing,
      channelOffset: 0,
      swapChannels: false,
      speedOfSound: sim.speedOfSound,
      speedLimitKmh: 50,
      startedAtUtcMs: 0,
      lanes: const [
        LaneGeometry(index: 0, direction: 1, slantDistance: 4.1),
        LaneGeometry(index: 1, direction: -1, slantDistance: 7.3),
      ],
    );
    final progress = <double>[];
    final fromFile = await runSeriesAnalysis(
      wavPath: file.path,
      setup: setup,
      config: config,
      onProgress: (p) => progress.add(p.fraction),
    );
    // The WAV is quantised to 16 bit: compare with the decoded signal.
    final decoded = await readWavStereoRange(file, startS: 0, durationS: 24);
    final inMemory = evaluateSignal(decoded, config: config, setup: setup);
    expect(fromFile.map((r) => r.toJson()), inMemory.map((r) => r.toJson()));
    expect(fromFile, hasLength(2));
    expect(fromFile.every((r) => r.klasse == QualityClass.b), isTrue);
    expect(progress.last, 1);

    final streamed = await analyseSeriesInBackground(
      wavPath: file.path,
      setup: setup,
      config: config,
    ).last;
    expect(
      streamed.result!.map((r) => r.toJson()),
      inMemory.map((r) => r.toJson()),
    );
    await dir.delete(recursive: true);
  });
}

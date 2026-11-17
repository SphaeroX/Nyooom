import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/data/live_pipeline.dart';
import 'package:test/test.dart';

void main() {
  test('a continued recording reports file offsets', () async {
    const config = NyooomConfig();
    final sim = Scenarios.setup(backgroundRms: 0.002);
    final rec = PassBySimulator(sim)
        .render(14, [Scenarios.combustion(speedKmh: 35, distance: 4.1, t0: 6)]);
    final starts = <double>[];
    final live = LivePipeline(
      config: config,
      setup: const AnalysisSetup(
        micSpacing: 0.15,
        channelOffset: 0,
        swapChannels: false,
        speedOfSound: 343,
        speedLimitKmh: 50,
        startedAtUtcMs: 0,
        lanes: [LaneGeometry(index: 0, direction: 1, slantDistance: 4.1)],
      ),
      startOffsetS: 100,
      evaluator: (window, event, startS) async {
        starts.add(startS);
        return PassRecord(
          zeitUtcMs: 0,
          offsetS: startS,
          richtung: 0,
          klasse: QualityClass.c,
          v: null,
          sigmaV: null,
          vLaufzeit: null,
          vDoppler: null,
          kappa: null,
          dEst: null,
          nToene: 0,
          restLaufzeitUs: null,
          pegel: 0,
          dauer: 0,
          reason: DowngradeReason.overlap,
          laneIndex: null,
          distanceUsedM: null,
        );
      },
    );
    live.add(rec.signal);
    await live.finish();
    expect(starts, isNotEmpty);
    for (final s in starts) {
      expect(s, inInclusiveRange(100, 114));
    }
  });
}

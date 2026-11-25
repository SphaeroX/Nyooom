import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/model/acoustics.dart' as acoustics;
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/series/temperature_log.dart';
import 'package:nyooom/data/live_pipeline.dart';
import 'package:test/test.dart';

void main() {
  test('a temperature update during the recording changes c from its '
      'position on', () async {
    final setup = AnalysisSetup(
      micSpacing: 0.15,
      channelOffset: 0,
      swapChannels: false,
      speedOfSound: acoustics.speedOfSound(10),
      speedLimitKmh: 50,
      startedAtUtcMs: 0,
      lanes: const [LaneGeometry(index: 0, direction: 1, slantDistance: 5)],
    );
    final live = LivePipeline(
      config: const NyooomConfig(),
      setup: setup,
      evaluator: (window, event, startS) async =>
          throw UnimplementedError() as PassRecord,
    );
    live.addTemperatureReading(
      const TemperatureReading(
        offsetS: 300,
        temperatureC: 4,
        utcMs: 300000,
        source: TemperatureReading.sourceGps,
      ),
    );
    expect(live.setup.speedOfSoundAt(10), acoustics.speedOfSound(10));
    expect(live.setup.speedOfSoundAt(400), acoustics.speedOfSound(4));
    expect(live.setup.temperatureLog!.first.temperatureC, 10);
    await live.dispose();
  });
}

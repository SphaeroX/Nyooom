import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/events/event_detector.dart';
import 'package:nyooom/core/model/acoustics.dart' as acoustics;
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/pipeline/event_evaluator.dart';
import 'package:nyooom/core/series/temperature_log.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/data/event_pipeline.dart';
import 'package:test/test.dart';

const config = NyooomConfig(dopplerVariant2: 0);

AnalysisSetup setup(double speedOfSound, {List<TemperatureReading>? log}) =>
    AnalysisSetup(
      micSpacing: Scenarios.setup().micSpacing,
      channelOffset: 0,
      swapChannels: false,
      speedOfSound: speedOfSound,
      speedLimitKmh: 50,
      startedAtUtcMs: 0,
      lanes: const [
        LaneGeometry(index: 0, direction: 1, slantDistance: 5),
        LaneGeometry(index: 1, direction: -1, slantDistance: 5),
      ],
      temperatureLog: log,
    );

void main() {
  test('each event window is evaluated with c at its signal position', () {
    // Recorded at -10 °C; the series started at 25 °C, a reading at
    // 0.5 s reports -10 °C. The window lies after that reading.
    final sim = Scenarios.setup(backgroundRms: 0.002, temperatureC: -10);
    final pass = Scenarios.combustion(
      speedKmh: 50,
      distance: 5,
      t0: 6,
      fundamentalHz: 200,
    );
    final rec = PassBySimulator(sim).render(12, [pass]);
    final event = detectEvents(rec.signal, config: config).single;
    final window = windowOf(rec.signal, event, 48000);
    final startS = (event.windowStartS * 48000).round() / 48000;
    expect(startS, greaterThan(0.5));
    const log = [
      TemperatureReading(
        offsetS: 0,
        temperatureC: 25,
        utcMs: 0,
        source: TemperatureReading.sourceStart,
      ),
      TemperatureReading(
        offsetS: 0.5,
        temperatureC: -10,
        utcMs: 500,
        source: TemperatureReading.sourceGps,
      ),
    ];
    final cStart = acoustics.speedOfSound(25);
    final cCold = acoustics.speedOfSound(-10);

    final withLog = EventPipeline(
      config: config,
      setup: setup(cStart, log: log),
    ).evaluateAll(window, event, windowStartS: startS);
    final cold = EventPipeline(
      config: config,
      setup: setup(cCold),
    ).evaluateAll(window, event, windowStartS: startS);
    final warm = EventPipeline(
      config: config,
      setup: setup(cStart),
    ).evaluateAll(window, event, windowStartS: startS);

    expect(withLog, hasLength(cold.length));
    expect(withLog.first.vLaufzeit, cold.first.vLaufzeit);
    expect(withLog.first.v, cold.first.v);
    // A 35 K error in c is visible in the travel-time speed.
    expect(warm.first.vLaufzeit, isNot(cold.first.vLaufzeit));
  });
}

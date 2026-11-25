import 'package:nyooom/core/calibration/self_calibration.dart';
import 'package:nyooom/core/model/acoustics.dart' as acoustics;
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/series/temperature_log.dart';
import 'package:test/test.dart';

AnalysisSetup setupWith(List<TemperatureReading>? log) => AnalysisSetup(
  micSpacing: 0.15,
  channelOffset: 0,
  swapChannels: false,
  speedOfSound: acoustics.speedOfSound(10),
  speedLimitKmh: 50,
  startedAtUtcMs: 0,
  lanes: const [LaneGeometry(index: 0, direction: 1, slantDistance: 5)],
  temperatureLog: log,
);

void main() {
  const log = [
    TemperatureReading(
      offsetS: 0,
      temperatureC: 10,
      utcMs: 0,
      source: TemperatureReading.sourceStart,
    ),
    TemperatureReading(
      offsetS: 600,
      temperatureC: 20,
      utcMs: 600000,
      source: TemperatureReading.sourceGps,
    ),
  ];

  test('without a temperature log c is the same everywhere', () {
    final setup = setupWith(null);
    expect(setup.speedOfSoundAt(0), setup.speedOfSound);
    expect(setup.speedOfSoundAt(5000), setup.speedOfSound);
    expect(identical(setup.atOffset(100), setup), isTrue);
  });

  test('c follows the temperature at the signal position', () {
    final setup = setupWith(log);
    expect(setup.speedOfSoundAt(10), acoustics.speedOfSound(10));
    expect(setup.speedOfSoundAt(700), acoustics.speedOfSound(20));
    final late = setup.atOffset(700);
    expect(late.speedOfSound, acoustics.speedOfSound(20));
    expect(late.maxTdoa, closeTo(0.15 / acoustics.speedOfSound(20), 1e-15));
    expect(late.micSpacing, setup.micSpacing);
    expect(late.lanes.single.slantDistance, 5);
  });

  test('a new reading extends the log', () {
    final setup = setupWith(log.take(1).toList())
        .withTemperatureReading(log[1]);
    expect(setup.temperatureLog, log);
    expect(setup.speedOfSoundAt(600), acoustics.speedOfSound(20));
  });

  test('learned spacing and lane distances keep the log', () {
    final setup = setupWith(log);
    expect(
      setup.withCalibration(micSpacing: 0.2, channelOffset: 0).temperatureLog,
      log,
    );
    expect(withLearnedDistances(setup, const []).temperatureLog, log);
  });
}

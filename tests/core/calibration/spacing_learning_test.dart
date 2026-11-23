import 'package:nyooom/core/calibration/plateau_calibration.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

PlateauEstimate estimate(double b, [double offset = 0]) => PlateauEstimate(
  micSpacing: b,
  channelOffset: offset,
  blocksBefore: 20,
  blocksAfter: 20,
);

const setup = AnalysisSetup(
  micSpacing: 0.15,
  channelOffset: 2e-6,
  swapChannels: true,
  speedOfSound: 340,
  lanes: [LaneGeometry(index: 0, direction: 0, slantDistance: 5)],
  speedLimitKmh: 30,
  startedAtUtcMs: 7,
);

void main() {
  test('enough passes: the median replaces the calibration', () {
    final learning = judgeSpacing(
      [
        for (final b in [0.141, 0.142, 0.142, 0.144, 0.120]) estimate(b, -6e-6),
      ],
      micSpacing: 0.15,
      channelOffset: 0,
      config: config,
    );
    expect(learning.passCount, config.plateauMinCount);
    expect(learning.active, isTrue);
    expect(learning.warning, isFalse);
    expect(learning.learned!.micSpacing, 0.142);
    expect(learning.learned!.channelOffset, -6e-6);
    expect(learning.learned!.passCount, 5);
    expect(learning.deviation, closeTo(0.142 / 0.15 - 1, 1e-12));
  });

  test('too few passes: the calibration stays', () {
    final learning = judgeSpacing(
      [estimate(0.142), estimate(0.143)],
      micSpacing: 0.15,
      channelOffset: 0,
      config: config,
    );
    expect(learning.active, isFalse);
    expect(learning.learned, isNull);
    expect(learning.warning, isFalse);
    expect(learning.estimate!.micSpacing, closeTo(0.1425, 1e-12));

    final none = judgeSpacing(
      const [],
      micSpacing: 0.15,
      channelOffset: 0,
      config: config,
    );
    expect(none.passCount, 0);
    expect(none.estimate, isNull);
    expect(none.deviation, isNull);
  });

  test('an implausible value is not used but reported', () {
    // More than plateauMaxDeviation away from the calibration: a curved
    // road, a wall or swapped settings, not a property of the device.
    final learning = judgeSpacing(
      [for (var i = 0; i < 8; i++) estimate(0.10)],
      micSpacing: 0.15,
      channelOffset: 0,
      config: config,
    );
    expect(learning.active, isFalse);
    expect(learning.warning, isTrue);
    expect(learning.learned, isNull);
  });

  test('the learned values go into the analysis setup', () {
    final learning = judgeSpacing(
      [for (var i = 0; i < 5; i++) estimate(0.142, -6e-6)],
      micSpacing: setup.micSpacing,
      channelOffset: setup.channelOffset,
      config: config,
    );
    final learned = learning.applyTo(setup);
    expect(learned.micSpacing, 0.142);
    expect(learned.channelOffset, -6e-6);
    // Everything else is untouched.
    expect(learned.swapChannels, isTrue);
    expect(learned.speedOfSound, 340);
    expect(learned.lanes.single.slantDistance, 5);
    expect(learned.speedLimitKmh, 30);
    expect(learned.startedAtUtcMs, 7);

    final inactive = judgeSpacing(
      [estimate(0.142)],
      micSpacing: setup.micSpacing,
      channelOffset: setup.channelOffset,
      config: config,
    );
    expect(inactive.applyTo(setup).micSpacing, 0.15);
    expect(inactive.applyTo(setup).channelOffset, 2e-6);
  });
}

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/capture.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/ui/calibration/calibration_controller.dart';
import 'package:nyooom/ui/providers.dart';

/// Counts the recordings of a simulated phone.
class _CountingCapture extends SimulatedCalibrationCapture {
  final steps = <CalibrationStep>[];

  @override
  Future<StereoBlock> capture(CalibrationStep step, Duration duration) {
    steps.add(step);
    return super.capture(step, duration);
  }
}

void main() {
  late NyooomDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = NyooomDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        calibrationCountdownProvider.overrideWithValue(
          const CalibrationCountdown(
            seconds: 3,
            tick: Duration(milliseconds: 1),
          ),
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('gives the user 5 s to walk away before a recording starts', () {
    final defaults = ProviderContainer();
    addTearDown(defaults.dispose);
    final countdown = defaults.read(calibrationCountdownProvider);
    expect(countdown.seconds, 5);
    expect(countdown.tick, const Duration(seconds: 1));
  });

  test('clap recordings are long enough for three claps', () {
    expect(
      calibrationStepDuration[CalibrationStep.clapsRight]!.inSeconds,
      greaterThanOrEqualTo(5),
    );
    expect(
      calibrationStepDuration[CalibrationStep.clapsLeft]!.inSeconds,
      greaterThanOrEqualTo(5),
    );
  });

  test('counts down, then records the step', () async {
    final capture = _CountingCapture();
    final controller = container.read(calibrationProvider.notifier);
    controller.begin(capture, 20);
    final seen = <int?>[];
    var recordingSeen = false;
    container.listen(calibrationProvider, (_, s) {
      if (s.countdown != null && (seen.isEmpty || seen.last != s.countdown)) {
        seen.add(s.countdown);
      }
      if (s.busy == CalibrationStep.clapsRight && s.countdown == null) {
        recordingSeen = true;
      }
    });

    await controller.recordAfterCountdown(CalibrationStep.clapsRight);

    expect(seen, [3, 2, 1]);
    expect(recordingSeen, isTrue);
    expect(capture.steps, [CalibrationStep.clapsRight]);
    final state = container.read(calibrationProvider);
    expect(state.busy, isNull);
    expect(state.countdown, isNull);
    expect(state.right!.count, greaterThan(0));
    expect(controller.stepPassed(CalibrationStep.clapsRight), isTrue);
    expect(controller.stepPassed(CalibrationStep.clapsLeft), isFalse);
  });

  test('a cancelled countdown records nothing', () async {
    final capture = _CountingCapture();
    final controller = container.read(calibrationProvider.notifier);
    controller.begin(capture, 20);
    final run = controller.recordAfterCountdown(CalibrationStep.clapsLeft);
    expect(container.read(calibrationProvider).countdown, 3);
    controller.cancelCountdown();
    await run;

    expect(capture.steps, isEmpty);
    final state = container.read(calibrationProvider);
    expect(state.busy, isNull);
    expect(state.countdown, isNull);
    expect(state.left, isNull);
  });

  test('all steps pass for a good simulated phone', () async {
    final controller = container.read(calibrationProvider.notifier);
    controller.begin(SimulatedCalibrationCapture(), 20);
    for (final step in CalibrationStep.values) {
      await controller.recordAfterCountdown(step);
      expect(controller.stepPassed(step), isTrue, reason: step.name);
    }
    expect(container.read(calibrationProvider).result, isNotNull);
  });
}

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/capture.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:nyooom/ui/calibration/calibration_controller.dart';
import 'package:nyooom/ui/providers.dart';

void main() {
  late NyooomDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = NyooomDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test(
    'runs all checks with a simulated phone and stores the result',
    () async {
      final controller = container.read(calibrationProvider.notifier);
      controller.begin(SimulatedCalibrationCapture(micSpacing: 0.15), 20);
      await controller.record(CalibrationStep.clapsRight);
      await controller.record(CalibrationStep.clapsLeft);
      await controller.record(CalibrationStep.constantSignal);

      final state = container.read(calibrationProvider);
      expect(state.stereo!.passed, isTrue);
      expect(state.mapping!.swapChannels, isFalse);
      expect(state.processing!.passed, isTrue);
      expect(state.clipping!.passed, isTrue);
      expect(state.result!.micSpacing, closeTo(0.15 * 343.2 / 343, 0.0015));

      final id = await controller.save();
      final repo = NyooomRepository(db);
      final device = await repo.ensureDevice('Simulation');
      final latest = (await repo.latestCalibration(device))!;
      expect(latest.id, id);
      expect(latest.micSpacingM, state.result!.micSpacing);
      expect(latest.checksJson, contains('stereo'));
    },
  );

  test('cannot save before both clap recordings exist', () async {
    final controller = container.read(calibrationProvider.notifier);
    controller.begin(SimulatedCalibrationCapture(), 20);
    await controller.record(CalibrationStep.clapsRight);
    expect(container.read(calibrationProvider).result, isNull);
    expect(controller.save, throwsStateError);
  });
}

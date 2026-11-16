import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:nyooom/ui/calibration/calibration_controller.dart';
import 'package:nyooom/ui/calibration/calibration_screen.dart';
import 'package:nyooom/ui/providers.dart';

class _SimulationOn extends SimulationDefault {
  @override
  bool build() => true;
}

void main() {
  late NyooomDatabase db;

  setUp(() => db = NyooomDatabase(NativeDatabase.memory()));

  Future<ProviderContainer> pumpWizard(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          simulationDefaultProvider.overrideWith(_SimulationOn.new),
          calibrationCountdownProvider.overrideWithValue(
            const CalibrationCountdown(
              seconds: 2,
              tick: Duration(milliseconds: 20),
            ),
          ),
        ],
        child: const MaterialApp(home: CalibrationScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(CalibrationScreen)),
    );
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key(key)));
    await tester.pumpAndSettle();
  }

  /// Starts the recording of the current step and waits until it is done.
  Future<void> record(WidgetTester tester, ProviderContainer c) async {
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('wizard-record')));
      while (c.read(calibrationProvider).busy == null) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      while (c.read(calibrationProvider).busy != null) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('guides a layperson step by step to a saved calibration', (
    tester,
  ) async {
    final c = await pumpWizard(tester);

    // Welcome page: what is needed.
    expect(find.text('Schritt 1 von 6'), findsOneWidget);
    expect(find.textContaining('3 m'), findsWidgets);
    await tap(tester, 'wizard-next');

    // Set up the phone.
    expect(find.text('Schritt 2 von 6'), findsOneWidget);
    await tap(tester, 'wizard-next');

    // Claps right: the next button is locked until it worked.
    expect(find.text('Schritt 3 von 6'), findsOneWidget);
    expect(find.textContaining('2 Sekunden'), findsWidgets);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('wizard-next')))
          .onPressed,
      isNull,
    );
    await record(tester, c);
    expect(find.byKey(const Key('wizard-step-ok')), findsOneWidget);
    await tap(tester, 'wizard-next');

    // Claps left.
    expect(find.text('Schritt 4 von 6'), findsOneWidget);
    await record(tester, c);
    expect(find.byKey(const Key('wizard-step-ok')), findsOneWidget);
    await tap(tester, 'wizard-next');

    // Constant signal can be skipped without a loudspeaker.
    expect(find.text('Schritt 5 von 6'), findsOneWidget);
    await tap(tester, 'wizard-skip');

    // Result and save.
    expect(find.text('Schritt 6 von 6'), findsOneWidget);
    expect(find.textContaining('cm'), findsWidgets);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('wizard-save')));
      while (c.read(calibrationProvider).savedId == null) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    });
    await tester.pumpAndSettle();
    final repo = NyooomRepository(db);
    final saved = await tester.runAsync(
      () async => repo.latestCalibration(await repo.ensureDevice('Simulation')),
    );
    expect(saved, isNotNull);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(db.close);
  });

  testWidgets('shows a big countdown before the recording starts', (
    tester,
  ) async {
    final c = await pumpWizard(tester);
    await tap(tester, 'wizard-next');
    await tap(tester, 'wizard-next');

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('wizard-record')));
      while (c.read(calibrationProvider).countdown == null) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    });
    await tester.pump();
    expect(find.byKey(const Key('wizard-countdown')), findsOneWidget);

    await tap(tester, 'wizard-cancel');
    expect(find.byKey(const Key('wizard-countdown')), findsNothing);
    expect(c.read(calibrationProvider).right, isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.runAsync(db.close);
  });
}

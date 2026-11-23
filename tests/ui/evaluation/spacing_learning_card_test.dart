import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/core/calibration/plateau_calibration.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/ui/evaluation/spacing_learning_card.dart';

const config = NyooomConfig();

PlateauEstimate estimate(double b) => PlateauEstimate(
  micSpacing: b,
  channelOffset: -6e-6,
  blocksBefore: 20,
  blocksAfter: 20,
);

Future<void> pumpCard(WidgetTester tester, SpacingInfo info) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [spacingInfoProvider.overrideWith((ref, id) async => info)],
      child: const MaterialApp(
        home: Scaffold(body: SpacingLearningCard(seriesId: 1)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the learned spacing next to the calibration', (
    tester,
  ) async {
    await pumpCard(
      tester,
      const SpacingInfo(
        calibratedSpacing: 0.15,
        learned: LearnedSpacing(
          micSpacing: 0.142,
          channelOffset: -6e-6,
          passCount: 9,
        ),
      ),
    );
    expect(find.textContaining('14.2 cm'), findsOneWidget);
    expect(find.textContaining('-6 µs'), findsOneWidget);
    expect(find.textContaining('9 Vorbeifahrten'), findsOneWidget);
    expect(find.textContaining('15.0 cm'), findsOneWidget);
  });

  testWidgets('without learned value the calibration is named', (tester) async {
    await pumpCard(
      tester,
      const SpacingInfo(calibratedSpacing: 0.148, learned: null),
    );
    expect(find.textContaining('14.8 cm'), findsOneWidget);
    expect(find.textContaining('Noch nicht gelernt'), findsOneWidget);
    expect(find.textContaining('${config.plateauMinCount}'), findsOneWidget);
  });

  group('note after an evaluation', () {
    SpacingLearning judge(List<double> spacings) => judgeSpacing(
      [for (final b in spacings) estimate(b)],
      micSpacing: 0.15,
      channelOffset: 0,
      config: config,
    );

    test('nothing to say when the learned value is used', () {
      expect(spacingNote(judge(List.filled(6, 0.142)), config), isNull);
    });

    test('too few passes', () {
      final note = spacingNote(judge([0.142, 0.143]), config)!;
      expect(note, contains('2'));
      expect(note, contains('${config.plateauMinCount}'));
      expect(note, contains('nicht gelernt'));
    });

    test('implausible value', () {
      final note = spacingNote(judge(List.filled(6, 0.10)), config)!;
      expect(note, contains('10.0 cm'));
      expect(note, contains('33 %'));
      expect(note, contains('nicht übernommen'));
    });
  });
}

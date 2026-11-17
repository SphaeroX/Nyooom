import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/ui/help/help_screen.dart';
import 'package:nyooom/ui/help/onboarding_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: HelpScreen()));
  }

  testWidgets('erklärt kurz, was die App macht', (tester) async {
    await pump(tester);
    expect(find.text('Was macht Nyooom?'), findsOneWidget);
  });

  testWidgets('zeigt die Schritte nach der Installation in Reihenfolge', (
    tester,
  ) async {
    await pump(tester);
    expect(helpSteps.length, greaterThanOrEqualTo(5));
    for (var i = 0; i < helpSteps.length; i++) {
      final title = find.text('${i + 1}. ${helpSteps[i].title}');
      await tester.scrollUntilVisible(title, 200);
      expect(title, findsOneWidget);
    }
  });

  testWidgets('öffnet die Einführung erneut', (tester) async {
    await pump(tester);
    final button = find.byKey(const Key('help-show-onboarding'));
    await tester.scrollUntilVisible(button, 200);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-skip')));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(HelpScreen), findsOneWidget);
  });
}

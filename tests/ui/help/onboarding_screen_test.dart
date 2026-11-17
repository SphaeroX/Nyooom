import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/ui/help/onboarding_screen.dart';

void main() {
  Future<List<int>> pump(WidgetTester tester) async {
    final done = <int>[];
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(onDone: () => done.add(1))),
    );
    return done;
  }

  testWidgets('führt Seite für Seite durch den Ablauf', (tester) async {
    final done = await pump(tester);
    expect(find.text('Willkommen bei Nyooom'), findsOneWidget);
    for (var i = 1; i < onboardingPages.length; i++) {
      await tester.tap(find.byKey(const Key('onboarding-next')));
      await tester.pumpAndSettle();
      expect(find.text(onboardingPages[i].title), findsOneWidget);
    }
    expect(done, isEmpty);
    expect(find.text('Los geht’s'), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(done, hasLength(1));
  });

  testWidgets('lässt sich überspringen', (tester) async {
    final done = await pump(tester);
    await tester.tap(find.byKey(const Key('onboarding-skip')));
    await tester.pumpAndSettle();
    expect(done, hasLength(1));
  });

  testWidgets('erklärt Gerät prüfen, Standort, Messung und Ergebnis', (
    tester,
  ) async {
    await pump(tester);
    final titles = onboardingPages.map((p) => p.title).join(' ');
    expect(titles, contains('Gerät'));
    expect(titles, contains('Standort'));
    expect(titles, contains('Messen'));
    expect(titles, contains('Ergebnis'));
  });
}

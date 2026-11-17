import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/ui/help/onboarding_screen.dart';
import 'package:nyooom/ui/home/home_screen.dart';

class _Done extends OnboardingDone {
  _Done(this.initial);
  final bool initial;
  int completed = 0;

  @override
  Future<bool> build() async => initial;

  @override
  Future<void> complete() async {
    completed++;
    state = const AsyncData(true);
  }
}

void main() {
  Future<_Done> pump(WidgetTester tester, {required bool done}) async {
    final notifier = _Done(done);
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [onboardingDoneProvider.overrideWith(() => notifier)],
        child: const MaterialApp(
          home: OnboardingGate(child: Text('Startseite')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return notifier;
  }

  testWidgets('zeigt beim ersten Start die Einführung', (tester) async {
    final n = await pump(tester, done: false);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('onboarding-skip')));
    await tester.pumpAndSettle();
    expect(n.completed, 1);
    expect(find.text('Startseite'), findsOneWidget);
  });

  testWidgets('geht danach direkt zur Startseite', (tester) async {
    await pump(tester, done: true);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.text('Startseite'), findsOneWidget);
  });

  test('Hilfe ist ein eigener Tab der Startseite', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(homeTabsProvider).map((t) => t.label), contains('Hilfe'));
  });
}

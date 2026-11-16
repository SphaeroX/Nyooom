import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/ui/sites/site_form.dart';

void main() {
  late List<SiteSpec> submitted;

  Future<void> pump(WidgetTester tester, {SiteSpec? initial}) async {
    submitted = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SiteForm(initial: initial, onSubmit: submitted.add),
        ),
      ),
    );
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('save-site')));
    await tester.tap(find.byKey(const Key('save-site')));
    await tester.pump();
  }

  testWidgets('submits a valid site with comma decimals', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('site-name')), 'Ringstraße');
    await tester.enterText(find.byKey(const Key('lane-distance-0')), '4,5');
    await save(tester);
    expect(submitted.single.name, 'Ringstraße');
    expect(submitted.single.lanes.single.horizontalDistance, 4.5);
    expect(submitted.single.micHeight, 1.2);
    expect(submitted.single.speedLimitKmh, 50);
  });

  testWidgets('blocks saving with an invalid distance', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('site-name')), 'A');
    await tester.enterText(find.byKey(const Key('lane-distance-0')), '0');
    await save(tester);
    expect(submitted, isEmpty);
    expect(find.textContaining('größer als 0'), findsOneWidget);
  });

  testWidgets('warns but saves outside the recommended range', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('site-name')), 'A');
    await tester.enterText(find.byKey(const Key('lane-distance-0')), '2');
    await tester.enterText(find.byKey(const Key('mic-height')), '1,0');
    await tester.pump();
    expect(find.textContaining('außerhalb von 3 bis 10 m'), findsOneWidget);
    await save(tester);
    expect(submitted, hasLength(1));
  });

  testWidgets('a second lane gets the opposite direction', (tester) async {
    await pump(tester);
    await tester.enterText(find.byKey(const Key('site-name')), 'A');
    await tester.ensureVisible(find.byKey(const Key('add-lane')));
    await tester.tap(find.byKey(const Key('add-lane')));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('lane-distance-1')), '7');
    await save(tester);
    expect(submitted.single.lanes.map((l) => l.direction), [1, -1]);
  });

  testWidgets('shows an existing site', (tester) async {
    await pump(
      tester,
      initial: const SiteSpec(
        name: 'Alt',
        lanes: [LaneSpec(horizontalDistance: 6, direction: -1)],
        micHeight: 1.4,
        speedLimitKmh: 30,
      ),
    );
    expect(find.text('Alt'), findsOneWidget);
    expect(find.text('6.0'), findsOneWidget);
    expect(find.text('30.0'), findsOneWidget);
  });
}

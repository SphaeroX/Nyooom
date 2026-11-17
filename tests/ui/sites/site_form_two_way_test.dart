import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/ui/sites/site_form.dart';

void main() {
  testWidgets('a lane can be marked as two-way', (tester) async {
    final submitted = <SiteSpec>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SiteForm(onSubmit: submitted.add)),
      ),
    );
    await tester.enterText(find.byKey(const Key('site-name')), 'Gasse');
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('lane-direction-0')),
        matching: find.text('⇄'),
      ),
    );
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('save-site')));
    await tester.tap(find.byKey(const Key('save-site')));
    await tester.pump();
    expect(submitted.single.lanes.single.direction, 0);
    expect(submitted.single.lanes.single.isTwoWay, isTrue);
  });
}

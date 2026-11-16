import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:nyooom/ui/providers.dart';
import 'package:nyooom/ui/series/series_screens.dart';

void main() {
  test('new series use the microphones by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(simulationDefaultProvider), isFalse);
  });

  testWidgets('without a site, a quick test site can be created', (
    tester,
  ) async {
    final db = NyooomDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(home: SeriesStartScreen()),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quick-site')), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('quick-site')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    final sites = await tester.runAsync(() => NyooomRepository(db).sites());
    expect(sites, hasLength(1));
    expect(find.byKey(const Key('quick-site')), findsNothing);
    final start = tester.widget<FilledButton>(
      find.byKey(const Key('start-series')),
    );
    expect(start.onPressed, isNotNull);

    await tester.runAsync(db.close);
  });
}

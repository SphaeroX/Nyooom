import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/outdoor_temperature.dart';
import 'package:nyooom/data/repository.dart';
import 'package:nyooom/ui/providers.dart';
import 'package:nyooom/ui/series/series_screens.dart';
import 'package:nyooom/ui/weather/outdoor_temperature_providers.dart';

class FixedTemperature implements OutdoorTemperatureService {
  FixedTemperature(this.result);
  final Future<OutdoorTemperature> Function() result;
  @override
  Future<OutdoorTemperature> current() => result();
}

Future<void> pumpStart(
  WidgetTester tester,
  NyooomDatabase db,
  OutdoorTemperatureService service,
) async {
  await tester.runAsync(
    () => NyooomRepository(db).createSite(
      const SiteSpec(
        name: 'Gasse',
        lanes: [LaneSpec(horizontalDistance: 4, direction: 1)],
        micHeight: 1.2,
        speedLimitKmh: 30,
      ),
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        outdoorTemperatureServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(home: SeriesStartScreen()),
    ),
  );
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the GPS button fills in the outdoor temperature and turns '
      'on the auto update', (tester) async {
    final db = NyooomDatabase(NativeDatabase.memory());
    await pumpStart(
      tester,
      db,
      FixedTemperature(
        () async => const OutdoorTemperature(temperatureC: 7.36, utcMs: 0),
      ),
    );
    // The auto update option appears after a GPS lookup.
    expect(find.byKey(const Key('auto-temperature')), findsNothing);

    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('temperature-gps')));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('temperature')),
    );
    expect(field.controller!.text, '7.4');
    expect(find.textContaining('340.'), findsNothing);
    expect(find.textContaining('c = 335.'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(find.byKey(const Key('auto-temperature')))
          .value,
      isTrue,
    );
    await tester.runAsync(db.close);
  });

  testWidgets('a failed lookup leaves the field and shows why', (tester) async {
    final db = NyooomDatabase(NativeDatabase.memory());
    await pumpStart(
      tester,
      db,
      FixedTemperature(
        () async => throw const OutdoorTemperatureException(
          'Wetterdienst nicht erreichbar.',
        ),
      ),
    );
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('temperature-gps')));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('temperature')),
    );
    expect(field.controller!.text, '15');
    expect(find.text('Wetterdienst nicht erreichbar.'), findsOneWidget);
    await tester.runAsync(db.close);
  });
}

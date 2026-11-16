import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/core/reference/reference_logger.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/ui/providers.dart';
import 'package:nyooom/ui/reference/reference_screens.dart';

void main() {
  testWidgets('logger shows the current GPS speed and point count', (
    tester,
  ) async {
    final positions = StreamController<PositionSample>();
    final db = NyooomDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          positionStreamProvider.overrideWithValue(() => positions.stream),
        ],
        child: const MaterialApp(home: LoggerScreen()),
      ),
    );
    await tester.tap(find.byKey(const Key('start-logger')));
    await tester.pump();
    for (var i = 0; i < 3; i++) {
      positions.add(
        PositionSample(
          timeUtcMs: 1763300000000 + i * 1000,
          lat: 50,
          lon: 8 + i * 1e-4,
          speed: 8.5,
          accuracyM: 4,
        ),
      );
    }
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('3 Punkte'), findsOneWidget);
    expect(find.text('30.6 km/h'), findsOneWidget);
    expect(find.text('Genauigkeit 4 m'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await positions.close();
    await tester.runAsync(db.close);
  });
}

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/audio/wav.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:nyooom/data/series_storage.dart';
import 'package:nyooom/ui/common/rgba_image_view.dart';
import 'package:nyooom/ui/inspection/inspection_screen.dart';
import 'package:nyooom/ui/providers.dart';

void main() {
  testWidgets('the viewer opens a fixture series without errors', (
    tester,
  ) async {
    late Directory dir;
    late NyooomDatabase db;
    late int seriesId;
    await tester.runAsync(() async {
      dir = await Directory.systemTemp.createTemp('nyooom_inspect');
      db = NyooomDatabase(NativeDatabase.memory());
      final repo = NyooomRepository(db);
      final siteId = await repo.createSite(
        const SiteSpec(
          name: 'Fixture',
          lanes: [LaneSpec(horizontalDistance: 4, direction: 1)],
          micHeight: 1.2,
          speedLimitKmh: 50,
        ),
      );
      seriesId = await repo.createSeries(
        siteId: siteId,
        temperatureC: 20,
        startedAtUtcMs: 0,
        directory: dir.path,
        sourceHeight: 0.3,
        configJson: '{}',
      );
      final rec = Scenarios.render(
        Scenarios.combustion(speedKmh: 40, distance: 4.1, t0: 1.5),
        durationS: 3,
      );
      final storage = SeriesStorage(dir);
      await storage.create(seriesId);
      await storage
          .wavFile(seriesId)
          .writeAsBytes(
            encodeWavPcm16(
              interleavePcm16(rec.signal),
              channels: 2,
              sampleRate: 48000,
            ),
          );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          seriesStorageProvider.overrideWith((ref) async => SeriesStorage(dir)),
        ],
        child: MaterialApp(home: InspectionScreen(seriesId: seriesId)),
      ),
    );
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (find.byType(RgbaImageView).evaluate().length >= 2) break;
    }
    expect(find.byType(RgbaImageView), findsNWidgets(2));
    expect(find.textContaining('Korrelogramm'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      await db.close();
      await dir.delete(recursive: true);
    });
  });
}

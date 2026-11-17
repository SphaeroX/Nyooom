import 'dart:io';

import 'package:drift/native.dart';
import 'package:nyooom/core/series/recording_segment.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:test/test.dart';

Future<int> seedSeries(NyooomRepository repo) async {
  final siteId = await repo.createSite(
    const SiteSpec(
      name: 'A',
      lanes: [LaneSpec(horizontalDistance: 4, direction: 1)],
      micHeight: 1.2,
      speedLimitKmh: 50,
    ),
  );
  return repo.createSeries(
    siteId: siteId,
    temperatureC: 10,
    startedAtUtcMs: 1000,
    directory: 'x',
    sourceHeight: 0.3,
    configJson: '{}',
  );
}

void main() {
  test('resuming a series adds a segment and reopens it', () async {
    final db = NyooomDatabase(NativeDatabase.memory());
    final repo = NyooomRepository(db);
    final id = await seedSeries(repo);
    await repo.finishSeries(id, endedAtUtcMs: 11000);
    expect((await repo.series(id))!.durationS, 10);

    await repo.resumeSeries(id, offsetS: 10, resumedAtUtcMs: 100000);
    var series = (await repo.series(id))!;
    expect(series.endedAtUtcMs, isNull);
    expect(series.segments, const [
      RecordingSegment(offsetS: 0, startedAtUtcMs: 1000),
      RecordingSegment(offsetS: 10, startedAtUtcMs: 100000),
    ]);

    await repo.finishSeries(id, endedAtUtcMs: 105000);
    series = (await repo.series(id))!;
    expect(series.durationS, 15);
    final setup = (await repo.analysisSetup(id))!;
    expect(setup.utcMsAt(12), 102000);
    await db.close();
  });

  test('a series without pause has one segment', () async {
    final db = NyooomDatabase(NativeDatabase.memory());
    final repo = NyooomRepository(db);
    final id = await seedSeries(repo);
    expect((await repo.series(id))!.segments, const [
      RecordingSegment(offsetS: 0, startedAtUtcMs: 1000),
    ]);
    await db.close();
  });

  test('migration from schema 4 keeps series readable', () async {
    final dir = await Directory.systemTemp.createTemp('nyooom_migrate5');
    final file = File('${dir.path}/db.sqlite');
    var db = NyooomDatabase(NativeDatabase(file));
    final id = await seedSeries(NyooomRepository(db));
    await db.customStatement(
      'ALTER TABLE measurement_series DROP COLUMN segments_json',
    );
    await db.customStatement('PRAGMA user_version = 4');
    await db.close();

    db = NyooomDatabase(NativeDatabase(file));
    final repo = NyooomRepository(db);
    expect((await repo.series(id))!.segments, hasLength(1));
    await repo.resumeSeries(id, offsetS: 3, resumedAtUtcMs: 9000);
    expect((await repo.series(id))!.segments, hasLength(2));
    await db.close();
    await dir.delete(recursive: true);
  });
}

import 'dart:io';

import 'package:drift/native.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/model/acoustics.dart' as acoustics;
import 'package:nyooom/core/series/temperature_log.dart';
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
  const reading = TemperatureReading(
    offsetS: 900,
    temperatureC: 14,
    utcMs: 901000,
    source: TemperatureReading.sourceGps,
  );

  test('a series without updates has no temperature log', () async {
    final db = NyooomDatabase(NativeDatabase.memory());
    final repo = NyooomRepository(db);
    final id = await seedSeries(repo);
    expect((await repo.series(id))!.temperatureLog, isEmpty);
    expect((await repo.analysisSetup(id))!.temperatureLog, isNull);
    await db.close();
  });

  test('a temperature update is stored after the start value and used by '
      'the analysis', () async {
    final db = NyooomDatabase(NativeDatabase.memory());
    final repo = NyooomRepository(db);
    final id = await seedSeries(repo);
    await repo.addTemperatureReading(id, reading);

    final series = (await repo.series(id))!;
    expect(series.temperatureLog, const [
      TemperatureReading(
        offsetS: 0,
        temperatureC: 10,
        utcMs: 1000,
        source: TemperatureReading.sourceStart,
      ),
      reading,
    ]);
    // The start values of the series stay as they were.
    expect(series.temperatureC, 10);
    expect(series.speedOfSound, acoustics.speedOfSound(10));

    final setup = (await repo.analysisSetup(id))!;
    expect(setup.speedOfSoundAt(100), acoustics.speedOfSound(10));
    expect(setup.speedOfSoundAt(1000), acoustics.speedOfSound(14));
    final learned = (await repo.learnedSetup(id, const NyooomConfig()))!;
    expect(learned.setup.temperatureLog, hasLength(2));
    await db.close();
  });

  test('an unchanged temperature adds no reading', () async {
    final db = NyooomDatabase(NativeDatabase.memory());
    final repo = NyooomRepository(db);
    final id = await seedSeries(repo);
    await repo.addTemperatureReading(id, reading);
    await repo.addTemperatureReading(
      id,
      const TemperatureReading(
        offsetS: 1800,
        temperatureC: 14,
        utcMs: 1801000,
        source: TemperatureReading.sourceGps,
      ),
    );
    expect((await repo.series(id))!.temperatureLog, hasLength(2));
    await db.close();
  });

  test('migration from schema 6 keeps series readable', () async {
    final dir = await Directory.systemTemp.createTemp('nyooom_migrate7');
    final file = File('${dir.path}/db.sqlite');
    var db = NyooomDatabase(NativeDatabase(file));
    final id = await seedSeries(NyooomRepository(db));
    await db.customStatement(
      'ALTER TABLE measurement_series DROP COLUMN temperature_log_json',
    );
    await db.customStatement('PRAGMA user_version = 6');
    await db.close();

    db = NyooomDatabase(NativeDatabase(file));
    final repo = NyooomRepository(db);
    expect((await repo.series(id))!.temperatureLog, isEmpty);
    await repo.addTemperatureReading(id, reading);
    expect((await repo.series(id))!.temperatureLog, hasLength(2));
    await db.close();
    await dir.delete(recursive: true);
  });
}

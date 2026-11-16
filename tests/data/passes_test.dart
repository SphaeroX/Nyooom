import 'dart:io';

import 'package:drift/native.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:test/test.dart';

const record = PassRecord(
  zeitUtcMs: 1700000006000,
  offsetS: 6,
  richtung: -1,
  klasse: QualityClass.b,
  v: 31.5,
  sigmaV: 2.6,
  vLaufzeit: 31.5,
  vDoppler: null,
  kappa: -1.71,
  dEst: null,
  nToene: 0,
  restLaufzeitUs: 6.2,
  pegel: 21.3,
  dauer: 1.45,
  reason: DowngradeReason.noTone,
  laneIndex: 1,
  distanceUsedM: 7.3,
  sigmaLaufzeit: 2.6,
);

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
    startedAtUtcMs: 1700000000000,
    directory: 'x',
    sourceHeight: 0.3,
    configJson: '{}',
  );
}

void main() {
  test(
    'pass records survive a database round trip with all 9.1 fields',
    () async {
      final db = NyooomDatabase(NativeDatabase.memory());
      final repo = NyooomRepository(db);
      final id = await seedSeries(repo);
      await repo.replacePasses(id, [record, record.copyWith(v: 40)]);
      await repo.replacePasses(id, [record]);
      final loaded = (await repo.passes(id)).single;
      expect(loaded.toJson(), record.toJson());
      expect(loaded.vDoppler, isNull);
      expect(loaded.dEst, isNull);
      await db.close();
    },
  );

  test('migration from schema 1 keeps existing passes readable', () async {
    final dir = await Directory.systemTemp.createTemp('nyooom_migrate');
    final file = File('${dir.path}/db.sqlite');
    // Build a schema-1 database: current schema minus the new columns.
    var db = NyooomDatabase(NativeDatabase(file));
    final repo = NyooomRepository(db);
    final id = await seedSeries(repo);
    await repo.addPass(id, record);
    await db.customStatement('ALTER TABLE passes DROP COLUMN sigma_laufzeit');
    await db.customStatement('ALTER TABLE passes DROP COLUMN sigma_doppler');
    await db.customStatement('PRAGMA user_version = 1');
    await db.close();

    db = NyooomDatabase(NativeDatabase(file));
    final loaded = (await NyooomRepository(db).passes(id)).single;
    expect(loaded.v, 31.5);
    expect(loaded.sigmaLaufzeit, isNull);
    await NyooomRepository(db).addPass(id, record);
    expect((await NyooomRepository(db).passes(id)).last.sigmaLaufzeit, 2.6);
    await db.close();
    await dir.delete(recursive: true);
  });
}

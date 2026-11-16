import 'package:drift/native.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:test/test.dart';

void main() {
  late NyooomDatabase db;
  late NyooomRepository repo;

  setUp(() {
    db = NyooomDatabase(NativeDatabase.memory());
    repo = NyooomRepository(db);
  });
  tearDown(() => db.close());

  const site = SiteSpec(
    name: 'Hauptstraße',
    lanes: [
      LaneSpec(horizontalDistance: 4, direction: 1),
      LaneSpec(horizontalDistance: 7.5, direction: -1),
    ],
    micHeight: 1.2,
    speedLimitKmh: 50,
  );

  test('stores a site with two lanes', () async {
    final id = await repo.createSite(site);
    final stored = await repo.site(id);
    expect(stored!.spec.name, 'Hauptstraße');
    expect(stored.spec.lanes, site.lanes);
    expect(stored.spec.micHeight, 1.2);
    expect((await repo.sites()).single.id, id);
  });

  test('updates a site and replaces its lanes', () async {
    final id = await repo.createSite(site);
    await repo.updateSite(
      id,
      const SiteSpec(
        name: 'Neu',
        lanes: [LaneSpec(horizontalDistance: 5, direction: -1)],
        micHeight: 1.3,
        speedLimitKmh: 30,
      ),
    );
    final stored = (await repo.site(id))!;
    expect(stored.spec.name, 'Neu');
    expect(stored.spec.lanes.single.horizontalDistance, 5);
  });

  test(
    'creates and loads a series with derived c and slant distances',
    () async {
      final siteId = await repo.createSite(site);
      final deviceId = await repo.ensureDevice('Pixel 8');
      final seriesId = await repo.createSeries(
        siteId: siteId,
        deviceId: deviceId,
        temperatureC: 20,
        startedAtUtcMs: 1000,
        directory: '/tmp/s1',
        sourceHeight: 0.3,
        configJson: '{}',
      );
      final series = (await repo.series(seriesId))!;
      expect(series.speedOfSound, closeTo(343.2, 0.05));
      expect(series.slantDistances[0], closeTo(4.1, 1e-9)); // sqrt(16 + 0.81)
      expect(series.siteName, 'Hauptstraße');
      expect(series.endedAtUtcMs, isNull);

      await repo.finishSeries(seriesId, endedAtUtcMs: 61000);
      expect((await repo.series(seriesId))!.durationS, 60);
      expect(await repo.allSeries(), hasLength(1));
    },
  );

  test('deleting a site cascades to lanes, series and passes', () async {
    final siteId = await repo.createSite(site);
    final seriesId = await repo.createSeries(
      siteId: siteId,
      temperatureC: 10,
      startedAtUtcMs: 0,
      directory: 'x',
      sourceHeight: 0.3,
      configJson: '{}',
    );
    await db
        .into(db.passes)
        .insert(
          PassesCompanion.insert(
            seriesId: seriesId,
            zeit: 5,
            offsetS: 5,
            richtung: 1,
            klasse: 'B',
            nToene: 0,
            pegel: 20,
            dauer: 1.5,
          ),
        );
    await repo.deleteSite(siteId);
    expect(await repo.allSeries(), isEmpty);
    expect(await db.select(db.passes).get(), isEmpty);
    expect(await db.select(db.lanes).get(), isEmpty);
  });

  test('ensureDevice returns the same id for the same model', () async {
    final a = await repo.ensureDevice('Pixel 8');
    final b = await repo.ensureDevice('Pixel 8');
    final c = await repo.ensureDevice('Pixel 8', inputDevice: 'USB');
    expect(a, b);
    expect(c, isNot(a));
  });
}

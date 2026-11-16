import 'package:drift/native.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:test/test.dart';

PassRecord a(double dEst) => PassRecord(
  zeitUtcMs: 0,
  offsetS: 0,
  richtung: 1,
  klasse: QualityClass.a,
  v: 40,
  sigmaV: 1.5,
  vLaufzeit: 41,
  vDoppler: 40,
  kappa: 40 / 3.6 / dEst,
  dEst: dEst,
  nToene: 2,
  restLaufzeitUs: 5,
  pegel: 20,
  dauer: 1,
  reason: null,
  laneIndex: 0,
  distanceUsedM: 4.1,
  sigmaLaufzeit: 2.7,
  sigmaDoppler: 1.9,
);

void main() {
  test('learned distances of a site are used and records recomputed', () async {
    const config = NyooomConfig();
    final db = NyooomDatabase(NativeDatabase.memory());
    final repo = NyooomRepository(db);
    final siteId = await repo.createSite(
      const SiteSpec(
        name: 'S',
        lanes: [LaneSpec(horizontalDistance: 4, direction: 1)],
        micHeight: 1.2,
        speedLimitKmh: 50,
      ),
    );
    Future<int> series() => repo.createSeries(
      siteId: siteId,
      temperatureC: 20,
      startedAtUtcMs: 0,
      directory: 'x',
      sourceHeight: 0.3,
      configJson: '{}',
    );
    final first = await series();
    await repo.replacePasses(first, [for (var i = 0; i < 20; i++) a(3.9)]);
    final second = await series();
    await repo.replacePasses(second, [for (var i = 0; i < 12; i++) a(3.9)]);

    final learned = (await repo.learnedSetup(second, config))!;
    expect(learned.learning.single.countA, 32);
    expect(learned.learning.single.active, isTrue);
    expect(learned.setup.lanes.single.slantDistance, closeTo(3.9, 1e-12));

    final changed = await repo.recomputeSiteWithLearning(siteId, config);
    expect(changed, 32);
    final records = await repo.passes(first);
    expect(records.first.distanceUsedM, closeTo(3.9, 1e-12));
    expect(records.first.vLaufzeit, closeTo(40, 1e-9));
    await db.close();
  });
}

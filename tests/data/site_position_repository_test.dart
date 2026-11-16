import 'package:drift/native.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:test/test.dart';

void main() {
  test('site position and +x bearing are stored', () async {
    final db = NyooomDatabase(NativeDatabase.memory());
    final repo = NyooomRepository(db);
    final id = await repo.createSite(
      const SiteSpec(
        name: 'Geo',
        lanes: [LaneSpec(horizontalDistance: 4, direction: 1)],
        micHeight: 1.2,
        speedLimitKmh: 50,
        latitude: 50.1,
        longitude: 8.6,
        plusXBearingDeg: 92.5,
      ),
    );
    final s = (await repo.site(id))!.spec;
    expect(s.latitude, 50.1);
    expect(s.longitude, 8.6);
    expect(s.plusXBearingDeg, 92.5);
    await db.close();
  });
}

import 'package:drift/native.dart';
import 'package:nyooom/core/reference/reference_track.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:test/test.dart';

void main() {
  test('a reference track survives a database round trip', () async {
    final db = NyooomDatabase(NativeDatabase.memory());
    final repo = NyooomRepository(db);
    const track = ReferenceTrack(
      name: 'Tempomat 30',
      source: ReferenceSource.logger,
      points: [
        ReferencePoint(
          timeUtcMs: 1000,
          lat: 50,
          lon: 8,
          speed: 8.3,
          accuracyM: 3,
          speedAccuracy: 0.2,
        ),
        ReferencePoint(
          timeUtcMs: 2000,
          lat: 50,
          lon: 8.0001,
          speed: 8.4,
          speedDerived: true,
        ),
      ],
    );
    final id = await repo.addReferenceTrack(track);
    final loaded = (await repo.referenceTrack(id))!;
    expect(loaded.name, 'Tempomat 30');
    expect(loaded.source, ReferenceSource.logger);
    expect(loaded.points, hasLength(2));
    expect(loaded.points[0].accuracyM, 3);
    expect(loaded.points[1].speedDerived, isTrue);
    expect((await repo.referenceTracks()).single.id, id);
    await repo.deleteReferenceTrack(id);
    expect(await repo.referenceTracks(), isEmpty);
    expect(await db.select(db.referencePoints).get(), isEmpty);
    await db.close();
  });
}

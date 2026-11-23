import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:nyooom/core/calibration/plateau_calibration.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:test/test.dart';

Future<int> seedSeries(NyooomRepository repo, {bool calibrated = false}) async {
  final siteId = await repo.createSite(
    const SiteSpec(
      name: 'Fenster',
      lanes: [LaneSpec(horizontalDistance: 4.4, direction: 0)],
      micHeight: 2.5,
      speedLimitKmh: 30,
    ),
  );
  int? deviceId, calibrationId;
  if (calibrated) {
    deviceId = await repo.ensureDevice('Pixel', inputDevice: 'USB');
    calibrationId = await repo.addCalibration(
      CalibrationsCompanion.insert(
        deviceId: deviceId,
        micSpacingM: 0.148,
        channelOffsetS: 3e-6,
        temperatureC: 2,
        createdAtUtcMs: 1,
        swapChannels: const Value(true),
      ),
    );
  }
  return repo.createSeries(
    siteId: siteId,
    deviceId: deviceId,
    calibrationId: calibrationId,
    temperatureC: 2,
    startedAtUtcMs: 1000,
    directory: 'x',
    sourceHeight: 0.3,
    configJson: '{}',
  );
}

const learned = LearnedSpacing(
  micSpacing: 0.142,
  channelOffset: -6e-6,
  passCount: 9,
);

void main() {
  test('learned spacing is stored with the series and used', () async {
    final db = NyooomDatabase(NativeDatabase.memory());
    final repo = NyooomRepository(db);
    final id = await seedSeries(repo, calibrated: true);
    expect(await repo.learnedSpacing(id), isNull);
    expect((await repo.analysisSetup(id))!.micSpacing, 0.148);

    await repo.setLearnedSpacing(id, learned);
    final stored = (await repo.learnedSpacing(id))!;
    expect(stored.micSpacing, 0.142);
    expect(stored.channelOffset, -6e-6);
    expect(stored.passCount, 9);

    final setup = (await repo.analysisSetup(id))!;
    expect(setup.micSpacing, 0.142);
    expect(setup.channelOffset, -6e-6);
    // The channel assignment is not learned.
    expect(setup.swapChannels, isTrue);
    // Self-calibration of the lanes and the live mode build on it.
    final withLanes = (await repo.learnedSetup(id, const NyooomConfig()))!;
    expect(withLanes.setup.micSpacing, 0.142);

    // The calibration itself stays available: learning starts from it.
    final calibrated = (await repo.analysisSetup(id, learnedSpacing: false))!;
    expect(calibrated.micSpacing, 0.148);
    expect(calibrated.channelOffset, 3e-6);
    final base = (await repo.learnedSetup(
      id,
      const NyooomConfig(),
      learnedSpacing: false,
    ))!;
    expect(base.setup.micSpacing, 0.148);

    await repo.setLearnedSpacing(id, null);
    expect(await repo.learnedSpacing(id), isNull);
    expect((await repo.analysisSetup(id))!.micSpacing, 0.148);
    await db.close();
  });

  test('another series is not affected', () async {
    final db = NyooomDatabase(NativeDatabase.memory());
    final repo = NyooomRepository(db);
    final first = await seedSeries(repo);
    final second = await seedSeries(repo);
    await repo.setLearnedSpacing(first, learned);
    expect((await repo.analysisSetup(second))!.micSpacing, 0.15);
    await db.close();
  });

  test('migration from schema 5 keeps series readable', () async {
    final dir = await Directory.systemTemp.createTemp('nyooom_migrate6');
    final file = File('${dir.path}/db.sqlite');
    var db = NyooomDatabase(NativeDatabase(file));
    final id = await seedSeries(NyooomRepository(db));
    for (final column in [
      'learned_mic_spacing_m',
      'learned_channel_offset_s',
      'learned_pass_count',
    ]) {
      await db.customStatement(
        'ALTER TABLE measurement_series DROP COLUMN $column',
      );
    }
    await db.customStatement('PRAGMA user_version = 5');
    await db.close();

    db = NyooomDatabase(NativeDatabase(file));
    final repo = NyooomRepository(db);
    expect(await repo.learnedSpacing(id), isNull);
    await repo.setLearnedSpacing(id, learned);
    expect((await repo.learnedSpacing(id))!.passCount, 9);
    await db.close();
    await dir.delete(recursive: true);
  });
}

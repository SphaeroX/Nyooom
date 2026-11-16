import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/native.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/export/json_export.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/pipeline/reasons.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:nyooom/data/series_export.dart';
import 'package:nyooom/data/series_storage.dart';
import 'package:test/test.dart';

void main() {
  test('exports CSV, JSON and a ZIP with the raw audio', () async {
    final dir = await Directory.systemTemp.createTemp('nyooom_export');
    final db = NyooomDatabase(NativeDatabase.memory());
    final repo = NyooomRepository(db);
    final storage = SeriesStorage(dir);
    final siteId = await repo.createSite(
      const SiteSpec(
        name: 'Ring',
        lanes: [LaneSpec(horizontalDistance: 4, direction: 1)],
        micHeight: 1.2,
        speedLimitKmh: 50,
      ),
    );
    final id = await repo.createSeries(
      siteId: siteId,
      temperatureC: 12,
      startedAtUtcMs: 1763300000000,
      directory: dir.path,
      sourceHeight: 0.3,
      configJson: '{"sampleRate": 48000}',
    );
    const record = PassRecord(
      zeitUtcMs: 1763300005000,
      offsetS: 5,
      richtung: 1,
      klasse: QualityClass.b,
      v: 44,
      sigmaV: 2.5,
      vLaufzeit: 44,
      vDoppler: null,
      kappa: 2.9,
      dEst: null,
      nToene: 0,
      restLaufzeitUs: 6,
      pegel: 20,
      dauer: 1,
      reason: DowngradeReason.noTone,
      laneIndex: 0,
      distanceUsedM: 4.1,
    );
    await repo.replacePasses(id, [record]);
    await storage.create(id);
    await storage.wavFile(id).writeAsBytes(List.filled(100000, 7));

    final result = await exportSeries(
      repo: repo,
      storage: storage,
      seriesId: id,
      target: Directory('${dir.path}/export'),
      config: const NyooomConfig(),
      zipWithAudio: true,
    );
    final csv = await result.files[0].readAsString();
    expect(
      csv.split('\n')[1],
      startsWith('2025-11-16T13:33:25.000Z;1;B;44.00'),
    );
    final json = SeriesExport.fromJsonText(
      await result.files[1].readAsString(),
    );
    expect(json.records.single.toJson(), record.toJson());
    expect(json.series['site'], 'Ring');
    expect(json.statistics['B']['count'], 1);

    final archive = ZipDecoder().decodeBytes(await result.zip!.readAsBytes());
    expect(archive.files.map((f) => f.name).toSet(), {
      'nyooom_messreihe_${id}_vorbeifahrten.csv',
      'nyooom_messreihe_$id.json',
      'einheiten.txt',
      'audio.wav',
    });
    expect(
      archive.files.firstWhere((f) => f.name == 'audio.wav').content,
      List.filled(100000, 7),
    );
    await db.close();
    await dir.delete(recursive: true);
  });
}

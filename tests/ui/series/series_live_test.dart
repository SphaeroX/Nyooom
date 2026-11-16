import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:nyooom/data/series_storage.dart';
import 'package:nyooom/ui/providers.dart';
import 'package:nyooom/ui/series/series_recording_controller.dart';

import '../../helpers/fake_stereo_recorder.dart';

void main() {
  test('live evaluation stores records even without raw audio', () async {
    final dir = await Directory.systemTemp.createTemp('nyooom_live');
    final db = NyooomDatabase(NativeDatabase.memory());
    final recorder = FakeStereoRecorder();
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        seriesStorageProvider.overrideWith((ref) async => SeriesStorage(dir)),
        recorderFactoryProvider.overrideWithValue(
          ({required simulate, required lanes}) => recorder,
        ),
      ],
    );
    final repo = NyooomRepository(db);
    final siteId = await repo.createSite(
      const SiteSpec(
        name: 'Live',
        lanes: [LaneSpec(horizontalDistance: 4, direction: 1)],
        micHeight: 1.2,
        speedLimitKmh: 50,
      ),
    );
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(siteId: siteId, temperatureC: 20, saveRawAudio: false),
    );
    final id = container.read(seriesRecordingProvider).seriesId!;

    // 14 s with one pass at 40 km/h on the lane, sent in 20-ms blocks.
    final rec = Scenarios.render(
      Scenarios.combustion(speedKmh: 40, distance: 4.1, t0: 6),
      durationS: 14,
    );
    final pcm = interleavePcm16(rec.signal).buffer.asUint8List();
    const blockBytes = 960 * 4;
    for (var o = 0; o < pcm.length; o += blockBytes) {
      recorder.emit(
        Uint8List.sublistView(pcm, o, (o + blockBytes).clamp(0, pcm.length)),
      );
      if (o % (blockBytes * 50) == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await controller.stop();

    final stored = await repo.passes(id);
    expect(stored, hasLength(1));
    expect(stored.single.klasse, isNot(QualityClass.c));
    expect(stored.single.v, closeTo(40, 2));
    expect(container.read(seriesRecordingProvider).liveRecords, hasLength(1));
    expect(await SeriesStorage(dir).wavFile(id).exists(), isFalse);

    container.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });
}

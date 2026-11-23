import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/core/site/site.dart';
import 'package:nyooom/data/collection_storage.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/repository.dart';
import 'package:nyooom/data/series_storage.dart';
import 'package:nyooom/ui/collect/collect_controller.dart';
import 'package:nyooom/ui/providers.dart';
import 'package:nyooom/ui/series/series_recording_controller.dart';

import '../../helpers/fake_stereo_recorder.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

/// Emits [signal] in blocks of 0.1 s.
Future<void> emit(FakeStereoRecorder recorder, StereoBlock signal) async {
  const frames = 4800;
  for (var i = 0; i < signal.length; i += frames) {
    final end = i + frames > signal.length ? signal.length : i + frames;
    recorder.emit(
      interleavePcm16(
        StereoBlock(
          Float64List.sublistView(signal.left, i, end),
          Float64List.sublistView(signal.right, i, end),
        ),
      ).buffer.asUint8List(),
    );
  }
  await flush();
}

void main() {
  late Directory dir;
  late NyooomDatabase db;
  late FakeStereoRecorder recorder;
  late ProviderContainer container;
  late CollectionStorage collections;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nyooom_series_clips');
    db = NyooomDatabase(NativeDatabase.memory());
    recorder = FakeStereoRecorder();
    collections = CollectionStorage(Directory('${dir.path}/c'));
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        seriesStorageProvider.overrideWith((ref) async => SeriesStorage(dir)),
        collectionStorageProvider.overrideWith((ref) async => collections),
        liveEvaluationProvider.overrideWithValue(false),
        recorderFactoryProvider.overrideWithValue(
          ({required simulate, required lanes}) => recorder,
        ),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  Future<int> createSite() => NyooomRepository(db).createSite(
    const SiteSpec(
      name: 'Gasse',
      lanes: [LaneSpec(horizontalDistance: 4, direction: 0)],
      micHeight: 1.2,
      speedLimitKmh: 30,
    ),
  );

  SimulatedRecording pass() => PassBySimulator(
    Scenarios.setup(backgroundRms: 0.002),
  ).render(20, [Scenarios.combustion(speedKmh: 40, distance: 4.1, t0: 8)]);

  test('a series with the collector on cuts its events into clips of the '
      'series, also after continuing it', () async {
    final siteId = await createSite();
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(siteId: siteId, temperatureC: 15, collectClips: true),
    );
    final id = container.read(seriesRecordingProvider).seriesId!;
    final rec = pass();
    await emit(recorder, rec.signal);
    await controller.stop();

    var m = (await collections.forSeries(id))!;
    expect(m.source, seriesCollectionSource(id));
    expect(m.clips, hasLength(1));
    expect(m.recordedS, closeTo(20, 1e-6));
    expect(await collections.clipFile(m.id, m.clips.first.file).exists(), true);

    await controller.resume(id);
    await emit(recorder, rec.signal);
    await controller.stop();

    m = (await collections.forSeries(id))!;
    expect(m.clips, hasLength(2));
    // The second clip lies in the continued part of the series.
    expect(
      m.clips[1].peakTimeS,
      closeTo(20 + rec.truths.single.receptionT0, 0.3),
    );
    expect(m.recordedS, closeTo(40, 1e-6));
  });

  test('without the collector no clips are stored', () async {
    final siteId = await createSite();
    final controller = container.read(seriesRecordingProvider.notifier);
    await controller.start(
      SeriesStartRequest(siteId: siteId, temperatureC: 15),
    );
    final id = container.read(seriesRecordingProvider).seriesId!;
    await emit(recorder, pass().signal);
    await controller.stop();
    expect(await collections.forSeries(id), isNull);
  });
}

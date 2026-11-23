import 'dart:io';
import 'dart:typed_data';

import 'package:nyooom/core/collect/collection_manifest.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/data/collection_evaluation.dart';
import 'package:nyooom/data/collection_storage.dart';
import 'package:test/test.dart';

// No tone in the clips: without Doppler variant 2 the suite stays fast.
const config = NyooomConfig(dopplerVariant2: 0);

CollectionManifest base(int id, String source) => CollectionManifest(
  id: id,
  createdAtUtcMs: id,
  source: source,
  deviceModel: 'Fake Phone',
  inputDevice: 'intern',
  sampleRate: config.sampleRate,
  clips: const [],
);

/// Feeds [signal] in blocks of 0.1 s like the live recorder.
void feed(LiveClipCollection live, StereoBlock signal) {
  const frames = 4800;
  for (var i = 0; i < signal.length; i += frames) {
    final end = i + frames > signal.length ? signal.length : i + frames;
    live.add(
      StereoBlock(
        Float64List.sublistView(signal.left, i, end),
        Float64List.sublistView(signal.right, i, end),
      ),
    );
  }
}

void main() {
  late Directory root;
  late CollectionStorage storage;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nyooom_series_clips');
    storage = CollectionStorage(root);
  });

  tearDown(() => root.delete(recursive: true));

  test('the collection of a series is found by its source', () async {
    await storage.write(base(1, 'live'));
    await storage.write(base(2, seriesCollectionSource(7)));
    await storage.write(base(3, seriesCollectionSource(8)));
    await storage.write(base(4, seriesCollectionSource(7)));
    expect((await storage.forSeries(7))?.id, 4);
    expect((await storage.forSeries(8))?.id, 3);
    expect(await storage.forSeries(9), isNull);
  });

  test('a live collection stores clips while recording, shifted by the '
      'start offset of the segment', () async {
    final rec = PassBySimulator(
      Scenarios.setup(backgroundRms: 0.002),
    ).render(25, [Scenarios.combustion(speedKmh: 40, distance: 4.1, t0: 10)]);
    final live = LiveClipCollection(
      storage: storage,
      manifest: base(5, seriesCollectionSource(3)),
      config: config,
      offsetS: 100,
    );
    feed(live, rec.signal);
    final m = await live.finish(recordedS: 125);

    expect(m.clips, hasLength(1));
    expect(m.recordedS, 125);
    expect(
      m.clips.single.peakTimeS,
      closeTo(100 + rec.truths.single.receptionT0, 0.3),
    );
    expect(m.clips.single.startS, greaterThan(100));
    expect(await storage.clipFile(5, m.clips.single.file).exists(), isTrue);
    expect((await storage.read(5))?.clips, hasLength(1));
  });

  test('a stored clip is evaluated directly', () async {
    final car = Scenarios.render(
      Scenarios.electric(speedKmh: 36, distance: 4, direction: -1),
      micSpacing: 0.15,
    );
    await storage.writeClip(6, 'clip_001.wav', car.signal, config.sampleRate);
    final clip = ClipEntry(
      file: 'clip_001.wav',
      startS: 50,
      peakTimeS: 54,
      durationS: car.signal.length / config.sampleRate,
      peakLevelDb: -30,
      floorDb: -60,
      eventDurationS: 3,
      overlap: false,
    );
    final result = await evaluateStoredClip(
      storage,
      6,
      clip,
      config: config,
      setup: AnalysisSetup(
        micSpacing: 0.15,
        channelOffset: 0,
        swapChannels: false,
        speedOfSound: car.truths.single.speedOfSound,
        lanes: const [LaneGeometry(index: 0, direction: 0, slantDistance: 4)],
        speedLimitKmh: 30,
        startedAtUtcMs: 0,
      ),
    );
    expect(result.vehicleFound, isTrue);
    // TDOA speed tolerance for a point source (technik.pdf 8: 3 km/h).
    expect(result.vehicle!.v, closeTo(36, 3));
  });
}

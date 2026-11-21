import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:nyooom/audio/wav.dart';
import 'package:nyooom/core/collect/collection_manifest.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:nyooom/data/collection_storage.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

CollectionManifest empty(int id) => CollectionManifest(
  id: id,
  createdAtUtcMs: id,
  source: 'live',
  deviceModel: 'Fake Phone',
  inputDevice: 'intern',
  sampleRate: config.sampleRate,
  clips: const [],
);

void main() {
  late Directory root;
  late CollectionStorage storage;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nyooom_collect');
    storage = CollectionStorage(root);
  });

  tearDown(() => root.delete(recursive: true));

  test('stores clips as WAV and lists collections newest first', () async {
    final block = StereoBlock(
      Float64List.fromList([0.5, -0.5, 0.25]),
      Float64List.fromList([0.1, 0.2, 0.3]),
    );
    final file = await storage.writeClip(1, 'clip_001.wav', block, 48000);
    final wav = decodeWav(await file.readAsBytes());
    expect(wav.channels, 2);
    expect(wav.frameCount, 3);

    await storage.write(empty(1));
    await storage.write(empty(5));
    final list = await storage.list();
    expect(list.map((m) => m.id), [5, 1]);
    expect((await storage.read(1))?.deviceModel, 'Fake Phone');
  });

  test('deleting removes clips and manifest', () async {
    await storage.write(empty(3));
    await storage.delete(3);
    expect(await storage.read(3), isNull);
    expect(await storage.list(), isEmpty);
  });

  test(
    'the ZIP export contains clips, collection.json and labels.csv',
    () async {
      final block = StereoBlock(Float64List(10), Float64List(10));
      await storage.writeClip(7, 'clip_001.wav', block, 48000);
      final m = empty(7).withClip(
        const ClipEntry(
          file: 'clip_001.wav',
          startS: 0,
          peakTimeS: 4,
          durationS: 8,
          peakLevelDb: -20,
          floorDb: -50,
          eventDurationS: 1,
          overlap: false,
          label: ClipLabel.vehicle,
        ),
      );
      await storage.write(m);
      final zip = await storage.exportZip(7, Directory('${root.path}/out'));
      final archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
      final names = archive.files.map((f) => f.name).toSet();
      expect(names, {'clip_001.wav', 'collection.json', 'labels.csv'});
      final json = jsonDecode(
        utf8.decode(archive.findFile('collection.json')!.content as List<int>),
      );
      expect((json['clips'] as List).single['label'], 'auto');
    },
  );

  test('a recorded series is cut into clips of its passes', () async {
    final rec = PassBySimulator(Scenarios.setup(backgroundRms: 0.002))
        .render(40, [
          Scenarios.combustion(speedKmh: 40, distance: 4.1, t0: 10),
          Scenarios.electric(speedKmh: 30, distance: 4.1, t0: 28),
        ]);
    final wav = File('${root.path}/audio.wav');
    await wav.writeAsBytes(
      encodeWavPcm16(
        interleavePcm16(rec.signal),
        channels: 2,
        sampleRate: config.sampleRate,
      ),
    );
    final progress = <double>[];
    final m = await collectFromWav(
      storage: storage,
      wav: wav,
      config: config,
      base: empty(9),
      onProgress: progress.add,
    );
    expect(m.clips, hasLength(2));
    expect(m.clips.every((c) => c.label == ClipLabel.open), isTrue);
    expect(m.clips[0].peakTimeS, closeTo(rec.truths[0].receptionT0, 0.3));
    expect(await storage.clipFile(9, m.clips[1].file).exists(), isTrue);
    expect((await storage.read(9))?.clips, hasLength(2));
    expect(progress.last, closeTo(1, 1e-9));
  });
}

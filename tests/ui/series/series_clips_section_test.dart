import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/audio/clip_player.dart';
import 'package:nyooom/core/collect/collection_manifest.dart';
import 'package:nyooom/core/pipeline/pass_record.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/data/collection_evaluation.dart';
import 'package:nyooom/data/collection_storage.dart';
import 'package:nyooom/data/series_storage.dart';
import 'package:nyooom/ui/collect/collect_controller.dart';
import 'package:nyooom/ui/providers.dart';
import 'package:nyooom/ui/series/series_clips_section.dart';

class FakeClipPlayer implements ClipPlayer {
  final played = <String>[];
  final _done = StreamController<void>.broadcast();

  @override
  Future<void> play(String path) async => played.add(path);

  @override
  Future<void> stop() async {}

  @override
  Stream<void> get completions => _done.stream;
}

ClipEntry clip(String file, double startS, [ClipLabel l = ClipLabel.open]) =>
    ClipEntry(
      file: file,
      startS: startS,
      peakTimeS: startS + 4,
      durationS: 8,
      peakLevelDb: -25,
      floorDb: -50,
      eventDurationS: 1.5,
      overlap: false,
      label: l,
    );

const vehicle = PassRecord(
  zeitUtcMs: 0,
  offsetS: 4,
  richtung: 1,
  klasse: QualityClass.a,
  v: 42.3,
  sigmaV: 1.2,
  vLaufzeit: 42.3,
  vDoppler: null,
  kappa: 1,
  dEst: null,
  nToene: 0,
  restLaufzeitUs: 5,
  pegel: 25,
  dauer: 1.5,
  reason: null,
  laneIndex: 0,
  distanceUsedM: 4.1,
);

void main() {
  late Directory dir;
  late CollectionStorage storage;
  late FakeClipPlayer player;
  late List<String> analysed;

  setUp(() async {
    dir = (await Directory.systemTemp.createTemp('nyooom_clips_section'))
        .absolute;
    storage = CollectionStorage(dir);
    player = FakeClipPlayer();
    analysed = [];
    final silence = StereoBlock(Float64List(8), Float64List(8));
    for (final f in ['clip_001.wav', 'clip_002.wav']) {
      await storage.writeClip(77, f, silence, 48000);
    }
    await storage.write(
      CollectionManifest(
        id: 77,
        createdAtUtcMs: 77,
        source: seriesCollectionSource(5),
        deviceModel: 'Fake Phone',
        inputDevice: 'intern',
        sampleRate: 48000,
        recordedS: 120,
        clips: [
          clip('clip_001.wav', 10, ClipLabel.vehicle),
          clip('clip_002.wav', 60),
        ],
      ),
    );
  });

  tearDown(() => dir.delete(recursive: true));

  Widget app() => ProviderScope(
    overrides: [
      collectionStorageProvider.overrideWith((ref) async => storage),
      seriesStorageProvider.overrideWith((ref) async => SeriesStorage(dir)),
      clipPlayerProvider.overrideWithValue(player),
      clipAnalyzerProvider.overrideWithValue((seriesId, m, c) async {
        analysed.add('$seriesId/${m.id}/${c.file}');
        return ClipEvaluation(
          clip: c,
          records: c.file == 'clip_001.wav' ? const [vehicle] : const [],
        );
      }),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: SeriesClipsSection(seriesId: 5)),
      ),
    ),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  testWidgets('lists the clips of the series with their labels', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await settle(tester);
    expect(find.text('Clips der Messreihe'), findsOneWidget);
    expect(find.textContaining('2 Clips · 1 markiert'), findsOneWidget);
    expect(find.textContaining('clip_001.wav'), findsOneWidget);
    expect(find.textContaining('clip_002.wav'), findsOneWidget);
    expect(find.textContaining('Auto'), findsWidgets);
  });

  testWidgets('a clip is played from the list', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await tester.tap(find.byKey(const Key('series-clip-play-1')));
    await settle(tester);
    expect(player.played.single, endsWith('clip_002.wav'));
  });

  testWidgets('a clip is analysed and its result shown', (tester) async {
    await tester.pumpWidget(app());
    await settle(tester);
    await tester.tap(find.byKey(const Key('series-clip-analyze-0')));
    await settle(tester);
    expect(analysed, ['5/77/clip_001.wav']);
    expect(find.textContaining('42.3 ± 1.2 km/h'), findsOneWidget);

    await tester.tap(find.byKey(const Key('series-clip-analyze-1')));
    await settle(tester);
    expect(find.text('Kein Fahrzeug erkannt'), findsOneWidget);
  });
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/audio/clip_player.dart';
import 'package:nyooom/core/collect/collection_manifest.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/data/collection_storage.dart';
import 'package:nyooom/ui/collect/collect_screens.dart';
import 'package:nyooom/ui/collect/collect_controller.dart';
import 'package:nyooom/ui/export/export_buttons.dart';

class FakeClipPlayer implements ClipPlayer {
  final played = <String>[];
  int stops = 0;
  final _done = StreamController<void>.broadcast();

  void finishClip() => _done.add(null);

  @override
  Future<void> play(String path) async => played.add(path);

  @override
  Future<void> stop() async => stops++;

  @override
  Stream<void> get completions => _done.stream;
}

ClipEntry clip(String file, [ClipLabel label = ClipLabel.open]) => ClipEntry(
  file: file,
  startS: 0,
  peakTimeS: 4,
  durationS: 8,
  peakLevelDb: -25,
  floorDb: -50,
  eventDurationS: 1.5,
  overlap: false,
  label: label,
);

void main() {
  late Directory dir;
  late CollectionStorage storage;
  late FakeClipPlayer player;
  late List<List<File>> shared;

  setUp(() async {
    dir = (await Directory.systemTemp.createTemp('nyooom_label')).absolute;
    storage = CollectionStorage(dir);
    player = FakeClipPlayer();
    shared = [];
    final silence = StereoBlock(Float64List(8), Float64List(8));
    for (final f in ['clip_001.wav', 'clip_002.wav', 'clip_003.wav']) {
      await storage.writeClip(42, f, silence, 48000);
    }
    await storage.write(
      CollectionManifest(
        id: 42,
        createdAtUtcMs: 42,
        source: 'live',
        deviceModel: 'Fake Phone',
        inputDevice: 'intern',
        sampleRate: 48000,
        recordedS: 120,
        clips: [
          clip('clip_001.wav', ClipLabel.vehicle),
          clip('clip_002.wav'),
          clip('clip_003.wav'),
        ],
      ),
    );
  });

  tearDown(() => dir.delete(recursive: true));

  Widget app(Widget home) => ProviderScope(
    overrides: [
      collectionStorageProvider.overrideWith((ref) async => storage),
      clipPlayerProvider.overrideWithValue(player),
      collectExportDirectoryProvider.overrideWith(
        (ref) async => Directory('${dir.path}/export'),
      ),
      fileSharerProvider.overrideWithValue((files, subject) async {
        shared.add(files);
      }),
    ],
    child: MaterialApp(home: home),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
  }

  testWidgets('starts at the first open clip and plays it', (tester) async {
    await tester.pumpWidget(app(const ClipLabelScreen(collectionId: 42)));
    await settle(tester);
    expect(find.text('Clip 2 von 3'), findsOneWidget);
    expect(player.played.single, endsWith('clip_002.wav'));
  });

  testWidgets('a label is saved and the next clip plays', (tester) async {
    await tester.pumpWidget(app(const ClipLabelScreen(collectionId: 42)));
    await settle(tester);
    await tester.tap(find.byKey(const Key('label-vehicle')));
    await settle(tester);

    final m = await tester.runAsync(() => storage.read(42));
    expect(m!.clips[1].label, ClipLabel.vehicle);
    expect(find.text('Clip 3 von 3'), findsOneWidget);
    expect(player.played.last, endsWith('clip_003.wav'));

    await tester.tap(find.byKey(const Key('label-no-vehicle')));
    await settle(tester);
    final m2 = await tester.runAsync(() => storage.read(42));
    expect(m2!.clips[2].label, ClipLabel.noVehicle);
    expect(find.textContaining('Alle 3 Clips markiert'), findsOneWidget);
  });

  testWidgets('labels can be changed after going back', (tester) async {
    await tester.pumpWidget(app(const ClipLabelScreen(collectionId: 42)));
    await settle(tester);
    await tester.tap(find.byKey(const Key('clip-previous')));
    await settle(tester);
    expect(find.text('Clip 1 von 3'), findsOneWidget);
    await tester.tap(find.byKey(const Key('label-unclear')));
    await settle(tester);
    final m = await tester.runAsync(() => storage.read(42));
    expect(m!.clips[0].label, ClipLabel.unclear);
  });

  testWidgets('the list shows progress and exports a ZIP', (tester) async {
    await tester.pumpWidget(app(const CollectionListScreen()));
    await settle(tester);
    expect(find.textContaining('3 Clips'), findsOneWidget);
    expect(find.textContaining('1 markiert'), findsOneWidget);

    await tester.tap(find.byKey(const Key('collection-export-42')));
    // The ZIP is streamed file by file: wait until it is shared.
    for (var i = 0; i < 200 && shared.isEmpty; i++) {
      await settle(tester);
    }
    expect(shared.single.single.path, endsWith('.zip'));
  });
}

import 'package:nyooom/core/collect/collection_manifest.dart';
import 'package:test/test.dart';

ClipEntry clip(String file, {ClipLabel label = ClipLabel.open}) => ClipEntry(
  file: file,
  startS: 12.5,
  peakTimeS: 16.5,
  durationS: 8,
  peakLevelDb: -30.25,
  floorDb: -52,
  eventDurationS: 2.1,
  overlap: false,
  label: label,
);

CollectionManifest manifest() => CollectionManifest(
  id: 1700000000000,
  createdAtUtcMs: 1700000000000,
  source: 'live',
  deviceModel: 'Pixel 8',
  inputDevice: 'intern',
  sampleRate: 48000,
  clips: [
    clip('clip_001.wav', label: ClipLabel.vehicle),
    clip('clip_002.wav'),
    clip('clip_003.wav', label: ClipLabel.noVehicle),
  ],
);

void main() {
  test('survives a JSON round trip', () {
    final m = manifest();
    final back = CollectionManifest.fromJson(m.toJson());
    expect(back.toJson(), m.toJson());
    expect(back.clips[0].label, ClipLabel.vehicle);
    expect(back.clips[1].label, ClipLabel.open);
  });

  test('labels are stored with readable names', () {
    final json = manifest().toJson();
    final clips = json['clips'] as List;
    expect((clips[0] as Map)['label'], 'auto');
    expect((clips[1] as Map)['label'], 'offen');
    expect((clips[2] as Map)['label'], 'kein_auto');
    expect(ClipLabel.unclear.key, 'unklar');
  });

  test('labelling one clip leaves the others alone', () {
    final m = manifest().withLabel(1, ClipLabel.unclear);
    expect(m.clips.map((c) => c.label), [
      ClipLabel.vehicle,
      ClipLabel.unclear,
      ClipLabel.noVehicle,
    ]);
    expect(m.labelledCount, 3);
    expect(manifest().labelledCount, 2);
    expect(manifest().firstOpenIndex, 1);
  });

  test('appending clips numbers the files', () {
    final m = CollectionManifest(
      id: 1,
      createdAtUtcMs: 1,
      source: 'live',
      deviceModel: 'x',
      inputDevice: 'intern',
      sampleRate: 48000,
      clips: const [],
    );
    expect(m.nextClipFile, 'clip_001.wav');
    expect(manifest().nextClipFile, 'clip_004.wav');
  });

  test('CSV has one row per clip with the label', () {
    final lines = labelsCsv(manifest()).trim().split('\n');
    expect(lines.first, startsWith('datei;'));
    expect(lines, hasLength(4));
    expect(lines[1], startsWith('clip_001.wav;'));
    expect(lines[1], endsWith(';auto'));
    expect(lines[1], contains('-30.25'));
  });
}

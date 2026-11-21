import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import '../audio/wav.dart';
import '../core/collect/clip_collector.dart';
import '../core/collect/collection_manifest.dart';
import '../core/config/nyooom_config.dart';
import '../core/signal/pcm.dart';
import 'series_export.dart' show writeZipFile;

/// File layout of clip collections:
/// `<root>/collections/<id>/clip_001.wav …` and `collection.json`.
class CollectionStorage {
  CollectionStorage(this.root);

  final Directory root;

  static const manifestName = 'collection.json';
  static const labelsName = 'labels.csv';

  String get _sep => Platform.pathSeparator;

  Directory get _base => Directory('${root.path}${_sep}collections');

  Directory directoryFor(int id) => Directory('${_base.path}$_sep$id');

  File clipFile(int id, String name) =>
      File('${directoryFor(id).path}$_sep$name');

  File _manifestFile(int id) => clipFile(id, manifestName);

  /// Writes [block] as 16-bit stereo WAV.
  Future<File> writeClip(
    int id,
    String name,
    StereoBlock block,
    int sampleRate,
  ) async {
    await directoryFor(id).create(recursive: true);
    final file = clipFile(id, name);
    await file.writeAsBytes(
      encodeWavPcm16(
        interleavePcm16(block),
        channels: 2,
        sampleRate: sampleRate,
      ),
    );
    return file;
  }

  Future<void> write(CollectionManifest manifest) async {
    await directoryFor(manifest.id).create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await _manifestFile(manifest.id)
        .writeAsString(encoder.convert(manifest.toJson()));
  }

  Future<CollectionManifest?> read(int id) async {
    final file = _manifestFile(id);
    if (!await file.exists()) return null;
    return CollectionManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
  }

  /// All collections, newest first.
  Future<List<CollectionManifest>> list() async {
    if (!await _base.exists()) return const [];
    final out = <CollectionManifest>[];
    await for (final e in _base.list()) {
      if (e is! Directory) continue;
      final id = int.tryParse(e.uri.pathSegments.lastWhere((s) => s != ''));
      if (id == null) continue;
      final m = await read(id);
      if (m != null) out.add(m);
    }
    out.sort((a, b) => b.id.compareTo(a.id));
    return out;
  }

  Future<void> delete(int id) async {
    final dir = directoryFor(id);
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  /// ZIP with all clips, `collection.json` and `labels.csv` in [target].
  Future<File> exportZip(int id, Directory target) async {
    final manifest = await read(id);
    if (manifest == null) throw StateError('Sammlung $id nicht gefunden');
    await target.create(recursive: true);
    final labels = File('${target.path}$_sep$labelsName');
    await labels.writeAsString(labelsCsv(manifest));
    final zip = File('${target.path}${_sep}sammlung_$id.zip');
    await writeZipFile(zip, {
      for (final c in manifest.clips) c.file: clipFile(id, c.file),
      manifestName: _manifestFile(id),
      labelsName: labels,
    });
    return zip;
  }
}

/// Entry of [clip] under file name [file].
ClipEntry clipEntry(CollectedClip clip, String file, int sampleRate) =>
    ClipEntry(
      file: file,
      startS: clip.startS,
      peakTimeS: clip.event.peakTimeS,
      durationS: clip.durationS(sampleRate),
      peakLevelDb: clip.event.peakLevelDb,
      floorDb: clip.event.floorDb,
      eventDurationS: clip.event.durationS,
      overlap: clip.event.overlap,
    );

/// Cuts the event clips out of a recorded series ([wav]) into the
/// collection [base]; reports the processed fraction to [onProgress].
Future<CollectionManifest> collectFromWav({
  required CollectionStorage storage,
  required File wav,
  required NyooomConfig config,
  required CollectionManifest base,
  void Function(double fraction)? onProgress,
}) async {
  final info = await readWavInfo(wav);
  if (info.sampleRate != config.sampleRate) {
    throw FormatException(
      'Abtastrate ${info.sampleRate} Hz, erwartet ${config.sampleRate} Hz',
    );
  }
  final collector = ClipCollector(config: config);
  var manifest = base;
  Future<void> store(CollectedClip clip) async {
    final name = manifest.nextClipFile;
    await storage.writeClip(manifest.id, name, clip.signal, config.sampleRate);
    manifest = manifest.withClip(clipEntry(clip, name, config.sampleRate));
  }

  final chunkS = config.eventWindowS;
  final total = info.durationS;
  for (var t = 0.0; t < total; t += chunkS) {
    final block = await readWavStereoRange(
      wav,
      startS: t,
      durationS: math.min(chunkS, total - t),
    );
    for (final c in collector.add(block)) {
      await store(c);
    }
    onProgress?.call(math.min(1, (t + chunkS) / total));
  }
  for (final c in collector.finish()) {
    await store(c);
  }
  manifest = manifest.withRecorded(total);
  await storage.write(manifest);
  onProgress?.call(1);
  return manifest;
}

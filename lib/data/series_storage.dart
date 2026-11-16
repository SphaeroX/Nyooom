import 'dart:convert';
import 'dart:io';

import '../core/series/series_metadata.dart';

/// File layout of measurement series:
/// `<root>/series/<id>/audio.wav` and `<root>/series/<id>/metadata.json`.
class SeriesStorage {
  SeriesStorage(this.root);

  final Directory root;

  static const wavName = 'audio.wav';
  static const metadataName = 'metadata.json';

  Directory directoryFor(int seriesId) => Directory(
    [root.path, 'series', '$seriesId'].join(Platform.pathSeparator),
  );

  File wavFile(int seriesId) =>
      File('${directoryFor(seriesId).path}${Platform.pathSeparator}$wavName');

  File metadataFile(int seriesId) => File(
    '${directoryFor(seriesId).path}${Platform.pathSeparator}$metadataName',
  );

  Future<Directory> create(int seriesId) =>
      directoryFor(seriesId).create(recursive: true);

  Future<void> writeMetadata(SeriesMetadata metadata) async {
    await create(metadata.seriesId);
    const encoder = JsonEncoder.withIndent('  ');
    await metadataFile(metadata.seriesId)
        .writeAsString(encoder.convert(metadata.toJson()));
  }

  Future<SeriesMetadata?> readMetadata(int seriesId) async {
    final file = metadataFile(seriesId);
    if (!await file.exists()) return null;
    return SeriesMetadata.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
  }

  /// Total size of all files of the series in bytes.
  Future<int> sizeBytes(int seriesId) async {
    final dir = directoryFor(seriesId);
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final e in dir.list(recursive: true)) {
      if (e is File) total += await e.length();
    }
    return total;
  }

  Future<void> delete(int seriesId) async {
    final dir = directoryFor(seriesId);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

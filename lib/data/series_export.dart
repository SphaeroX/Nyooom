import 'dart:convert';
import 'dart:io';

import '../core/config/nyooom_config.dart';
import '../core/export/csv_export.dart';
import '../core/export/json_export.dart';
import '../core/export/zip_writer.dart';
import '../core/stats/statistics.dart';
import 'repository.dart';
import 'series_storage.dart';

/// Files of an export.
class ExportResult {
  const ExportResult({required this.files, this.zip});

  /// passes.csv, series.json, einheiten.txt
  final List<File> files;

  /// ZIP with all files and the raw audio, if requested.
  final File? zip;
}

/// Writes the export of series [seriesId] into [target] (Task_14).
Future<ExportResult> exportSeries({
  required NyooomRepository repo,
  required SeriesStorage storage,
  required int seriesId,
  required Directory target,
  required NyooomConfig config,
  bool zipWithAudio = false,
}) async {
  final series = (await repo.series(seriesId))!;
  final setup = (await repo.analysisSetup(seriesId))!;
  final records = await repo.passes(seriesId);
  final report = StatisticsReport.from(
    records,
    limitKmh: series.site.spec.speedLimitKmh,
  );
  await target.create(recursive: true);
  final base = 'nyooom_messreihe_$seriesId';
  final csv = File('${target.path}/${base}_vorbeifahrten.csv');
  await csv.writeAsString(passesToCsv(records));
  final units = File('${target.path}/einheiten.txt');
  await units.writeAsString(unitsText());
  final json = File('${target.path}/$base.json');
  await json.writeAsString(
    SeriesExport(
      series: {
        'id': series.id,
        'site': series.siteName,
        'startedAtUtc': DateTime.fromMillisecondsSinceEpoch(
          series.startedAtUtcMs,
          isUtc: true,
        ).toIso8601String(),
        'durationS': series.durationS,
        'temperatureC': series.temperatureC,
        'speedOfSound': series.speedOfSound,
        'simulated': series.row.simulated,
        'micHeightM': series.site.spec.micHeight,
        'speedLimitKmh': series.site.spec.speedLimitKmh,
      },
      setup: setup.toJson(),
      config: jsonDecode(series.row.configJson) as Map<String, dynamic>,
      statistics: _summary(report),
      records: records,
    ).toJsonText(),
  );
  final files = [csv, json, units];
  File? zip;
  if (zipWithAudio) {
    zip = File('${target.path}/$base.zip');
    final sources = <String, File>{
      for (final f in files) f.uri.pathSegments.last: f,
    };
    final wav = storage.wavFile(seriesId);
    if (await wav.exists()) sources['audio.wav'] = wav;
    final meta = storage.metadataFile(seriesId);
    if (await meta.exists()) sources['metadata.json'] = meta;
    await writeZipFile(zip, sources);
  }
  return ExportResult(files: files, zip: zip);
}

Map<String, dynamic> _summary(StatisticsReport r) {
  Map<String, dynamic> s(SpeedStats x) => {
    'count': x.count,
    'median': x.median,
    'v85': x.v85,
    'v85Corrected': x.v85Corrected,
    'mean': x.mean,
    'sd': x.sd,
    'overLimitShare': x.overLimitShare,
  };
  return {
    'total': r.total,
    'A': s(r.overall.a),
    'B': s(r.overall.b),
    'AB': s(r.overall.ab),
    'classC': {
      'count': r.classC.count,
      'share': r.classC.share,
      'reasons': {
        for (final e in r.classC.reasons.entries) e.key.code: e.value,
      },
    },
  };
}

/// Streams files into an uncompressed ZIP without loading them completely
/// (CRC is computed in a first pass).
Future<void> writeZipFile(File target, Map<String, File> sources) async {
  final out = await target.open(mode: FileMode.write);
  final entries = <ZipEntry>[];
  try {
    var offset = 0;
    for (final e in sources.entries) {
      final crc = Crc32();
      var size = 0;
      await for (final chunk in e.value.openRead()) {
        crc.add(chunk);
        size += chunk.length;
      }
      final name = utf8.encode(e.key);
      final header = ZipWriter.localHeader(name, crc.value, size);
      await out.writeFrom(header);
      await for (final chunk in e.value.openRead()) {
        await out.writeFrom(chunk);
      }
      entries.add(ZipEntry(name, crc.value, size, offset));
      offset += header.length + size;
    }
    await out.writeFrom(ZipWriter.centralDirectory(entries, offset));
  } finally {
    await out.close();
  }
}

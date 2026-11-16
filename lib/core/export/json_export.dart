import 'dart:convert';

import '../pipeline/pass_record.dart';
import 'csv_export.dart';

/// JSON export of a series: series data, setup (site, calibration),
/// configuration, statistics summary and all records (technik.pdf 9.1).
class SeriesExport {
  const SeriesExport({
    required this.series,
    required this.setup,
    required this.config,
    required this.statistics,
    required this.records,
  });

  static const format = 'nyooom-series';
  static const version = 1;

  final Map<String, dynamic> series;
  final Map<String, dynamic> setup;
  final Map<String, dynamic> config;
  final Map<String, dynamic> statistics;
  final List<PassRecord> records;

  Map<String, dynamic> toJson() => {
    'format': format,
    'version': version,
    'units': columnUnits,
    'series': series,
    'setup': setup,
    'config': config,
    'statistics': statistics,
    'records': [for (final r in records) r.toJson()],
  };

  String toJsonText() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory SeriesExport.fromJsonText(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    if (j['format'] != format) {
      throw const FormatException('Not a Nyooom series export');
    }
    return SeriesExport(
      series: (j['series'] as Map).cast<String, dynamic>(),
      setup: (j['setup'] as Map).cast<String, dynamic>(),
      config: (j['config'] as Map).cast<String, dynamic>(),
      statistics: (j['statistics'] as Map).cast<String, dynamic>(),
      records: [
        for (final r in j['records'] as List)
          PassRecord.fromJson((r as Map).cast<String, Object?>()),
      ],
    );
  }
}

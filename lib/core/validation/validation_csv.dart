import '../export/csv_export.dart';
import 'validation.dart';

/// Matches of a validation as CSV (same conventions as the export, Task_14).
String validationToCsv(
  List<ValidationMatch> matches, {
  required double? plusXBearingDeg,
}) {
  final b = StringBuffer()
    ..writeln(
      [
        'zeit_referenz',
        'v_referenz',
        'abstand_referenz',
        'zeit',
        'klasse',
        'richtung',
        'richtung_erwartet',
        'v',
        'fehler',
        'grund',
      ].join(csvSeparator),
    );
  String iso(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();
  for (final m in matches) {
    final expected = expectedDirection(m.reference, plusXBearingDeg);
    b.writeln(
      [
        iso(m.reference.timeUtcMs),
        m.reference.referenceKmh.toStringAsFixed(2),
        m.reference.distanceM.toStringAsFixed(1),
        iso(m.record.zeitUtcMs),
        m.record.klasse.label,
        '${m.record.richtung}',
        expected == null ? '' : '$expected',
        m.record.v?.toStringAsFixed(2) ?? '',
        m.errorKmh?.toStringAsFixed(2) ?? '',
        m.record.grund ?? '',
      ].map(csvField).join(csvSeparator),
    );
  }
  return b.toString();
}

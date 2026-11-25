import '../pipeline/pass_record.dart';

/// Column names of the CSV export: the fields of technik.pdf 9.1, then the
/// position of t0 in the series WAV (`audio_pos_s`, `audio_pos`) so a pass
/// can be found in the raw audio.
const csvColumns = [
  'zeit',
  'richtung',
  'klasse',
  'v',
  'sigma_v',
  'v_laufzeit',
  'v_doppler',
  'kappa',
  'd_est',
  'n_toene',
  'rest_laufzeit',
  'pegel',
  'dauer',
  'grund',
  'audio_pos_s',
  'audio_pos',
];

/// Units of the columns (technik.pdf 9.1), written to `einheiten.txt` and
/// into the JSON export.
const columnUnits = {
  'zeit': 'ISO 8601, UTC',
  'richtung': '+1 oder -1',
  'klasse': 'A, B oder C',
  'v': 'km/h',
  'sigma_v': 'km/h',
  'v_laufzeit': 'km/h',
  'v_doppler': 'km/h',
  'kappa': '1/s',
  'd_est': 'm',
  'n_toene': '-',
  'rest_laufzeit': 'µs',
  'pegel': 'dB',
  'dauer': 's',
  'grund': 'Text',
  'audio_pos_s':
      's ab Beginn der WAV (Pausen fortgesetzter Reihen nicht enthalten)',
  'audio_pos': 'h:mm:ss.s ab Beginn der WAV',
};

/// Separator `;`, decimal point `.`, empty field for missing values
/// (decision Task_14: opens in spreadsheets with a semicolon setting and is
/// unambiguous for scripts).
const csvSeparator = ';';

/// Quotes a field if it contains the separator, quotes or line breaks.
String csvField(String value) {
  if (value.contains(csvSeparator) ||
      value.contains('"') ||
      value.contains('\n') ||
      value.contains('\r')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

/// [seconds] as `h:mm:ss.s`, rounded to tenths.
String formatAudioPosition(double seconds) {
  final tenths = (seconds * 10).round();
  final h = tenths ~/ 36000;
  final m = tenths ~/ 600 % 60;
  final s = tenths ~/ 10 % 60;
  final t = tenths % 10;
  String two(int v) => v.toString().padLeft(2, '0');
  return '$h:${two(m)}:${two(s)}.$t';
}

String _num(double? v, int digits) =>
    v == null ? '' : v.toStringAsFixed(digits);

/// Records as CSV text (header line plus one line per record).
String passesToCsv(List<PassRecord> records) {
  final b = StringBuffer()..writeln(csvColumns.join(csvSeparator));
  for (final r in records) {
    final fields = [
      DateTime.fromMillisecondsSinceEpoch(
        r.zeitUtcMs,
        isUtc: true,
      ).toIso8601String(),
      '${r.richtung}',
      r.klasse.label,
      _num(r.v, 2),
      _num(r.sigmaV, 2),
      _num(r.vLaufzeit, 2),
      _num(r.vDoppler, 2),
      _num(r.kappa, 4),
      _num(r.dEst, 3),
      '${r.nToene}',
      _num(r.restLaufzeitUs, 1),
      _num(r.pegel, 1),
      _num(r.dauer, 2),
      r.grund ?? '',
      _num(r.offsetS, 2),
      formatAudioPosition(r.offsetS),
    ];
    b.writeln(fields.map(csvField).join(csvSeparator));
  }
  return b.toString();
}

/// Text of `einheiten.txt`.
String unitsText() => [
  'Spalte;Einheit',
  for (final e in columnUnits.entries) '${e.key};${e.value}',
].join('\n');

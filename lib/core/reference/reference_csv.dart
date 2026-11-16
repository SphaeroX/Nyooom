import 'reference_track.dart';

/// A line of a CSV log that could not be read.
class CsvLineError {
  const CsvLineError(this.line, this.message);

  /// 1-based line number.
  final int line;
  final String message;
}

class ReferenceCsvResult {
  const ReferenceCsvResult(this.track, this.errors);
  final ReferenceTrack track;
  final List<CsvLineError> errors;
}

/// Reads simple GPS logger CSV files. Recognised columns (case-insensitive):
/// time (`time`, `zeit`, `timestamp`, `datetime`, `date`), latitude
/// (`lat`, `latitude`, `breite`), longitude (`lon`, `lng`, `longitude`,
/// `laenge`), speed in m/s (`speed`, `speed_ms`, `speed_mps`) or km/h
/// (`speed_kmh`, `kmh`, `geschwindigkeit`). Separator `;`, `,` or tab.
/// Times: ISO 8601, `yyyy-MM-dd HH:mm:ss` (taken as UTC), epoch seconds or
/// milliseconds.
ReferenceCsvResult parseReferenceCsv(String text, {String name = 'CSV'}) {
  final lines = text.split(RegExp(r'\r?\n'));
  final errors = <CsvLineError>[];
  if (lines.isEmpty || lines.first.trim().isEmpty) {
    return ReferenceCsvResult(
      ReferenceTrack(name: name, source: ReferenceSource.csv, points: const []),
      const [CsvLineError(1, 'Kopfzeile fehlt')],
    );
  }
  final separator = [
    ';',
    '\t',
    ',',
  ].firstWhere((s) => lines.first.contains(s), orElse: () => ',');
  final header = [
    for (final h in lines.first.split(separator)) h.trim().toLowerCase(),
  ];
  int col(List<String> names) => header.indexWhere(names.contains);
  final iTime = col(['time', 'zeit', 'timestamp', 'datetime', 'date']);
  final iLat = col(['lat', 'latitude', 'breite']);
  final iLon = col(['lon', 'lng', 'longitude', 'laenge', 'länge']);
  final iMs = col(['speed', 'speed_ms', 'speed_mps']);
  final iKmh = col(['speed_kmh', 'kmh', 'geschwindigkeit']);
  if (iTime < 0 || iLat < 0 || iLon < 0) {
    return ReferenceCsvResult(
      ReferenceTrack(name: name, source: ReferenceSource.csv, points: const []),
      const [CsvLineError(1, 'Spalten für Zeit, Breite und Länge fehlen')],
    );
  }
  final points = <ReferencePoint>[];
  for (var n = 1; n < lines.length; n++) {
    final line = lines[n];
    if (line.trim().isEmpty) continue;
    final f = line.split(separator).map((s) => s.trim()).toList();
    final needed = [
      iTime,
      iLat,
      iLon,
      iMs,
      iKmh,
    ].reduce((a, b) => a > b ? a : b);
    if (f.length <= needed) {
      errors.add(CsvLineError(n + 1, 'zu wenige Spalten'));
      continue;
    }
    final t = parseTimeUtcMs(f[iTime]);
    final lat = double.tryParse(f[iLat]);
    final lon = double.tryParse(f[iLon]);
    if (t == null || lat == null || lon == null) {
      errors.add(CsvLineError(n + 1, 'Zeit oder Position nicht lesbar'));
      continue;
    }
    double? speed;
    if (iMs >= 0 && f[iMs].isNotEmpty) speed = double.tryParse(f[iMs]);
    if (speed == null && iKmh >= 0 && f[iKmh].isNotEmpty) {
      final kmh = double.tryParse(f[iKmh]);
      speed = kmh == null ? null : kmh / 3.6;
    }
    points.add(ReferencePoint(timeUtcMs: t, lat: lat, lon: lon, speed: speed));
  }
  points.sort((a, b) => a.timeUtcMs.compareTo(b.timeUtcMs));
  return ReferenceCsvResult(
    ReferenceTrack(
      name: name,
      source: ReferenceSource.csv,
      points: deriveSpeeds(points),
    ),
    errors,
  );
}

/// Parses the supported time formats to UTC milliseconds.
int? parseTimeUtcMs(String s) {
  final numeric = num.tryParse(s);
  if (numeric != null) {
    // Epoch milliseconds are > 1e11, epoch seconds below.
    return numeric > 1e11 ? numeric.round() : (numeric * 1000).round();
  }
  var text = s.replaceFirst(' ', 'T');
  final hasZone = RegExp(r'(Z|[+-]\d\d:?\d\d)$').hasMatch(text);
  if (!hasZone) text = '${text}Z';
  return DateTime.tryParse(text)?.toUtc().millisecondsSinceEpoch;
}

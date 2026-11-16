import 'reference_track.dart';

/// Tolerant GPX reader for track points (`trkpt`, also `rtept`/`wpt`):
/// position, time and an optional speed element (`<speed>` or an extension
/// such as `<gpxtpx:speed>`, in m/s). Missing speeds are derived from the
/// positions. A full XML parser is not needed for this subset.
ReferenceTrack parseGpx(String text, {String? fallbackName}) {
  final name =
      RegExp(r'<trk>\s*<name>([^<]*)</name>').firstMatch(text)?.group(1) ??
      RegExp(r'<name>([^<]*)</name>').firstMatch(text)?.group(1) ??
      fallbackName ??
      'GPX';
  final pointPattern = RegExp(
    r'<(trkpt|rtept|wpt)\b([^>]*?)(/>|>([\s\S]*?)</\1>)',
  );
  final points = <ReferencePoint>[];
  for (final m in pointPattern.allMatches(text)) {
    final attrs = m.group(2) ?? '';
    final body = m.group(4) ?? '';
    final lat = _attr(attrs, 'lat');
    final lon = _attr(attrs, 'lon');
    final time = RegExp(r'<time>([^<]+)</time>').firstMatch(body)?.group(1);
    if (lat == null || lon == null || time == null) continue;
    final t = DateTime.tryParse(time.trim());
    if (t == null) continue;
    final speed = RegExp(r'<(?:\w+:)?speed>([^<]+)</(?:\w+:)?speed>')
        .firstMatch(body)
        ?.group(1);
    points.add(
      ReferencePoint(
        timeUtcMs: t.toUtc().millisecondsSinceEpoch,
        lat: lat,
        lon: lon,
        speed: speed == null ? null : double.tryParse(speed.trim()),
      ),
    );
  }
  points.sort((a, b) => a.timeUtcMs.compareTo(b.timeUtcMs));
  return ReferenceTrack(
    name: name.trim(),
    source: ReferenceSource.gpx,
    points: deriveSpeeds(points),
  );
}

double? _attr(String attrs, String key) {
  final m = RegExp('\\b$key\\s*=\\s*["\']([^"\']+)["\']').firstMatch(attrs);
  return m == null ? null : double.tryParse(m.group(1)!);
}

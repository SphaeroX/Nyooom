import 'dart:convert';

/// One continuous part of a measurement series. A series that was stopped
/// and continued has several; the WAV holds them back to back, so
/// [offsetS] is the position of the part in the file and [startedAtUtcMs]
/// the wall-clock time at that position.
class RecordingSegment {
  const RecordingSegment({required this.offsetS, required this.startedAtUtcMs});

  factory RecordingSegment.fromJson(Map<String, dynamic> json) =>
      RecordingSegment(
        offsetS: (json['offsetS'] as num).toDouble(),
        startedAtUtcMs: (json['startedAtUtcMs'] as num).toInt(),
      );

  /// Position in the recorded signal in s.
  final double offsetS;
  final int startedAtUtcMs;

  Map<String, dynamic> toJson() => {
    'offsetS': offsetS,
    'startedAtUtcMs': startedAtUtcMs,
  };

  @override
  bool operator ==(Object other) =>
      other is RecordingSegment &&
      other.offsetS == offsetS &&
      other.startedAtUtcMs == startedAtUtcMs;

  @override
  int get hashCode => Object.hash(offsetS, startedAtUtcMs);

  @override
  String toString() => 'RecordingSegment($offsetS s @ $startedAtUtcMs)';
}

/// The segment [offsetS] lies in ([segments] sorted by offset), or null.
RecordingSegment? segmentAt(List<RecordingSegment> segments, double offsetS) {
  RecordingSegment? found;
  for (final s in segments) {
    if (s.offsetS <= offsetS) found = s;
  }
  return found ?? (segments.isEmpty ? null : segments.first);
}

/// Wall-clock time in UTC ms at [offsetS] of the recorded signal.
int utcMsAtOffset(
  List<RecordingSegment> segments,
  double offsetS, {
  required int fallbackStartUtcMs,
}) {
  final s = segmentAt(segments, offsetS);
  if (s == null) return fallbackStartUtcMs + (offsetS * 1000).round();
  return s.startedAtUtcMs + ((offsetS - s.offsetS) * 1000).round();
}

/// Recorded signal duration in s without the pauses; null while recording.
double? recordedDurationS(
  List<RecordingSegment> segments, {
  required int? endedAtUtcMs,
}) {
  if (endedAtUtcMs == null || segments.isEmpty) return null;
  final last = segments.last;
  return last.offsetS + (endedAtUtcMs - last.startedAtUtcMs) / 1000;
}

String segmentsToJson(List<RecordingSegment> segments) =>
    jsonEncode([for (final s in segments) s.toJson()]);

List<RecordingSegment> segmentsFromJson(String? json) => json == null
    ? const []
    : [
        for (final m in jsonDecode(json) as List)
          RecordingSegment.fromJson((m as Map).cast<String, dynamic>()),
      ];

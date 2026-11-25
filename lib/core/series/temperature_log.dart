import 'dart:convert';

/// Air temperature at one position of the recorded signal. A series with
/// automatic update collects several; c of an event follows the reading
/// at or before its position (technik.pdf 3.5, 7.3).
class TemperatureReading {
  const TemperatureReading({
    required this.offsetS,
    required this.temperatureC,
    required this.utcMs,
    required this.source,
  });

  factory TemperatureReading.fromJson(Map<String, dynamic> json) =>
      TemperatureReading(
        offsetS: (json['offsetS'] as num).toDouble(),
        temperatureC: (json['temperatureC'] as num).toDouble(),
        utcMs: (json['utcMs'] as num).toInt(),
        source: json['source'] as String? ?? sourceStart,
      );

  /// Value entered (or fetched) on the start screen.
  static const sourceStart = 'start';

  /// Fetched from the weather service at the GPS position.
  static const sourceGps = 'gps';

  /// Position in the recorded signal in s.
  final double offsetS;
  final double temperatureC;

  /// Wall-clock time of the reading (UTC, ms).
  final int utcMs;
  final String source;

  Map<String, dynamic> toJson() => {
    'offsetS': offsetS,
    'temperatureC': temperatureC,
    'utcMs': utcMs,
    'source': source,
  };

  @override
  bool operator ==(Object other) =>
      other is TemperatureReading &&
      other.offsetS == offsetS &&
      other.temperatureC == temperatureC &&
      other.utcMs == utcMs &&
      other.source == source;

  @override
  int get hashCode => Object.hash(offsetS, temperatureC, utcMs, source);

  @override
  String toString() =>
      'TemperatureReading($temperatureC °C @ $offsetS s, $source)';
}

/// Temperature in °C at [offsetS] ([log] sorted by offset): the last
/// reading at or before it, the first one before all readings, and
/// [fallbackC] without readings.
double temperatureAt(
  List<TemperatureReading> log,
  double offsetS, {
  required double fallbackC,
}) {
  if (log.isEmpty) return fallbackC;
  var found = log.first;
  for (final r in log) {
    if (r.offsetS <= offsetS) found = r;
  }
  return found.temperatureC;
}

/// [log] with [reading] appended, unchanged if the temperature is the same
/// as the last one.
List<TemperatureReading> appendTemperatureReading(
  List<TemperatureReading> log,
  TemperatureReading reading,
) => log.isNotEmpty && log.last.temperatureC == reading.temperatureC
    ? log
    : [...log, reading];

String temperatureLogToJson(List<TemperatureReading> log) =>
    jsonEncode([for (final r in log) r.toJson()]);

List<TemperatureReading> temperatureLogFromJson(String? json) => json == null
    ? const []
    : [
        for (final m in jsonDecode(json) as List)
          TemperatureReading.fromJson((m as Map).cast<String, dynamic>()),
      ];

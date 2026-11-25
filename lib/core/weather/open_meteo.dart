import 'dart:convert';

/// Open-Meteo forecast API (free, no key): current air temperature 2 m
/// above ground at a position.
final Uri openMeteoBaseUri = Uri.parse('https://api.open-meteo.com');

/// Request for the current temperature at the position. The coordinates
/// are rounded to two decimals (about 1 km): enough for the weather, and
/// the exact position does not leave the phone.
Uri openMeteoCurrentUri({
  required double latitude,
  required double longitude,
  Uri? base,
}) => (base ?? openMeteoBaseUri).replace(
  path: '/v1/forecast',
  queryParameters: {
    'latitude': latitude.toStringAsFixed(2),
    'longitude': longitude.toStringAsFixed(2),
    'current': 'temperature_2m',
  },
);

/// Current temperature in °C from an Open-Meteo answer; throws
/// [FormatException] if it has none.
double parseOpenMeteoTemperature(String body) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    throw const FormatException('Antwort ist kein JSON.');
  }
  if (json is Map) {
    final current = json['current'];
    if (current is Map) {
      final t = current['temperature_2m'];
      if (t is num) return t.toDouble();
    }
  }
  throw const FormatException('Antwort enthält keine Temperatur.');
}

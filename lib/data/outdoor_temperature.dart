import 'dart:convert';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../core/weather/open_meteo.dart';

/// Outdoor air temperature at the phone's position.
class OutdoorTemperature {
  const OutdoorTemperature({required this.temperatureC, required this.utcMs});

  final double temperatureC;

  /// When it was fetched (UTC, ms).
  final int utcMs;
}

/// Why no temperature could be fetched, as text for the user.
class OutdoorTemperatureException implements Exception {
  const OutdoorTemperatureException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Source of the current outdoor temperature (replaced in tests).
abstract interface class OutdoorTemperatureService {
  /// Throws [OutdoorTemperatureException].
  Future<OutdoorTemperature> current();
}

typedef Position2D = ({double latitude, double longitude});

/// Current GPS position, or null without permission or fix.
typedef Locate = Future<Position2D?> Function();

/// GPS position → Open-Meteo (free, no key). Phones have no outdoor
/// temperature sensor, so the weather service's 2 m temperature is used.
class GpsOutdoorTemperatureService implements OutdoorTemperatureService {
  GpsOutdoorTemperatureService({
    Locate? locate,
    this.baseUri,
    DateTime Function()? now,
    this.timeout = const Duration(seconds: 15),
  }) : _locate = locate ?? locateWithGeolocator,
       _now = now ?? DateTime.now;

  final Locate _locate;
  final DateTime Function() _now;

  /// Other server than [openMeteoBaseUri] (tests).
  final Uri? baseUri;
  final Duration timeout;

  @override
  Future<OutdoorTemperature> current() async {
    final position = await _locate();
    if (position == null) {
      throw const OutdoorTemperatureException(
        'Standort nicht verfügbar (GPS aus oder keine Berechtigung).',
      );
    }
    final uri = openMeteoCurrentUri(
      latitude: position.latitude,
      longitude: position.longitude,
      base: baseUri,
    );
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      if (response.statusCode != 200) {
        throw OutdoorTemperatureException(
          'Wetterdienst antwortet mit Fehler ${response.statusCode}.',
        );
      }
      return OutdoorTemperature(
        temperatureC: parseOpenMeteoTemperature(body),
        utcMs: _now().toUtc().millisecondsSinceEpoch,
      );
    } on OutdoorTemperatureException {
      rethrow;
    } on FormatException {
      throw const OutdoorTemperatureException(
        'Wetterdienst liefert keine Temperatur.',
      );
    } catch (_) {
      throw const OutdoorTemperatureException(
        'Wetterdienst nicht erreichbar (keine Internetverbindung?).',
      );
    } finally {
      client.close(force: true);
    }
  }
}

/// Position from the phone's location service; a coarse fix is enough for
/// the weather.
Future<Position2D?> locateWithGeolocator() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    Position? last;
    try {
      last = await Geolocator.getLastKnownPosition();
    } catch (_) {
      // Not supported on every platform; ask for a current fix.
    }
    final p =
        last ??
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 20),
          ),
        );
    return (latitude: p.latitude, longitude: p.longitude);
  } catch (_) {
    return null;
  }
}

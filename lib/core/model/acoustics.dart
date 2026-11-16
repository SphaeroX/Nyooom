import 'dart:math' as math;

/// Speed of sound at 0 °C in m/s (technik.pdf 3.5).
const double speedOfSoundAtZeroC = 331.3;

/// 0 °C in kelvin.
const double zeroCelsiusInKelvin = 273.15;

/// Speed of sound in m/s for an air temperature in °C (technik.pdf 3.5).
double speedOfSound(double temperatureC) =>
    speedOfSoundAtZeroC * math.sqrt(1 + temperatureC / zeroCelsiusInKelvin);

/// Slant distance between the microphone pair and the source path
/// (technik.pdf 3.1): d = sqrt(dh² + Δh²).
double slantDistance(double horizontalDistance, double heightDifference) =>
    math.sqrt(
      horizontalDistance * horizontalDistance +
          heightDifference * heightDifference,
    );

/// Converts m/s to km/h (only at output boundaries).
double toKmh(double metresPerSecond) => metresPerSecond * 3.6;

/// Converts km/h to m/s.
double fromKmh(double kilometresPerHour) => kilometresPerHour / 3.6;

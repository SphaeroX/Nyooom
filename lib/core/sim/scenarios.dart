import '../model/acoustics.dart';
import 'passby_simulator.dart';

export 'passby_simulator.dart';

/// Reusable synthetic scenarios (fixture factory).
///
/// Typical vehicle sound models, deliberately simple:
/// - combustion: tyre noise plus an engine tone with harmonics whose pitch
///   follows the speed;
/// - electric: quieter tyre noise, a warning tone (AVAS) only on request.
class Scenarios {
  Scenarios._();

  /// Default microphone spacing of the simulated phone in m.
  static const double defaultMicSpacing = 0.15;

  /// Default air temperature in °C.
  static const double defaultTemperatureC = 20;

  static SimulationSetup setup({
    double micSpacing = defaultMicSpacing,
    double temperatureC = defaultTemperatureC,
    double channelOffset = 0,
    double backgroundRms = 0.002,
    int seed = 1,
    int sampleRate = 48000,
  }) => SimulationSetup(
    sampleRate: sampleRate,
    micSpacing: micSpacing,
    speedOfSound: speedOfSound(temperatureC),
    channelOffset: channelOffset,
    backgroundRms: backgroundRms,
    seed: seed,
  );

  /// Combustion car with engine tone (fundamental plus five harmonics).
  static VehiclePass combustion({
    required double speedKmh,
    required double distance,
    int direction = 1,
    double t0 = 4,
    bool tone = true,
    double acceleration = 0,
    double toneLeadS = 0,
    double fundamentalHz = 160,
    double noiseRms = 0.15,
    double toneAmplitude = 0.06,
  }) => VehiclePass(
    kind: VehicleKind.combustion,
    speed: direction * fromKmh(speedKmh),
    distance: distance,
    t0: t0,
    acceleration: direction * acceleration,
    noiseRms: noiseRms,
    toneLeadS: toneLeadS,
    tones: tone
        ? [
            for (var k = 1; k <= 6; k++)
              ToneSpec(fundamentalHz * k, toneAmplitude / k),
          ]
        : const [],
  );

  /// Electric car: tyre noise only, optionally a warning tone (AVAS).
  static VehiclePass electric({
    required double speedKmh,
    required double distance,
    int direction = 1,
    double t0 = 4,
    bool warningTone = false,
    double acceleration = 0,
    double noiseRms = 0.08,
  }) => VehiclePass(
    kind: VehicleKind.electric,
    speed: direction * fromKmh(speedKmh),
    distance: distance,
    t0: t0,
    acceleration: direction * acceleration,
    noiseRms: noiseRms,
    tones: warningTone
        ? const [
            ToneSpec(500, 0.03),
            ToneSpec(1000, 0.02),
            ToneSpec(1500, 0.01),
          ]
        : const [],
  );

  /// Renders a single pass with background noise at [snrDb].
  static SimulatedRecording render(
    VehiclePass pass, {
    double durationS = 8,
    double snrDb = 30,
    double channelOffset = 0,
    double micSpacing = defaultMicSpacing,
    double temperatureC = defaultTemperatureC,
    int seed = 1,
  }) => PassBySimulator(
    setup(
      micSpacing: micSpacing,
      temperatureC: temperatureC,
      channelOffset: channelOffset,
      backgroundRms: backgroundRmsForSnr(pass, snrDb),
      seed: seed,
    ),
  ).render(durationS, [pass]);
}

import '../model/acoustics.dart' as acoustics;
import '../series/recording_segment.dart';
import '../series/temperature_log.dart';

/// Geometry of one lane as the evaluation needs it.
class LaneGeometry {
  const LaneGeometry({
    required this.index,
    required this.direction,
    required this.slantDistance,
  });

  final int index;

  /// +1, −1, or 0 for a lane used in both directions.
  final int direction;

  /// Slant distance d_Spur in m (technik.pdf 7.2).
  final double slantDistance;
}

/// Device and site constants for evaluating one measurement series.
class AnalysisSetup {
  const AnalysisSetup({
    required this.micSpacing,
    required this.channelOffset,
    required this.swapChannels,
    required this.speedOfSound,
    required this.lanes,
    required this.speedLimitKmh,
    required this.startedAtUtcMs,
    this.segments,
    this.temperatureLog,
  });

  /// Default b without calibration in m (typical phone, technik.pdf 4.1).
  static const double defaultMicSpacing = 0.15;

  final double micSpacing;
  final double channelOffset;
  final bool swapChannels;
  final double speedOfSound;
  final List<LaneGeometry> lanes;
  final double speedLimitKmh;
  final int startedAtUtcMs;

  /// Parts of a series that was stopped and continued; null or empty for
  /// one continuous recording starting at [startedAtUtcMs].
  final List<RecordingSegment>? segments;

  /// Air temperature over the recording (automatic update); null or empty:
  /// [speedOfSound] holds for the whole series.
  final List<TemperatureReading>? temperatureLog;

  /// c in m/s at [offsetS] of the recorded signal.
  double speedOfSoundAt(double offsetS) {
    final log = temperatureLog;
    if (log == null || log.isEmpty) return speedOfSound;
    return acoustics.speedOfSound(temperatureAt(log, offsetS, fallbackC: 0));
  }

  /// The setup with a fixed c for an event at [offsetS]; itself without a
  /// temperature log.
  AnalysisSetup atOffset(double offsetS) {
    final log = temperatureLog;
    if (log == null || log.isEmpty) return this;
    return _copy(speedOfSound: speedOfSoundAt(offsetS), temperatureLog: null);
  }

  /// The setup with [reading] added to the temperature log; a missing log
  /// starts with [speedOfSound]'s temperature at position 0.
  AnalysisSetup withTemperatureReading(TemperatureReading reading) {
    final log = temperatureLog;
    final base = log == null || log.isEmpty
        ? [
            TemperatureReading(
              offsetS: 0,
              temperatureC: acoustics.temperatureForSpeedOfSound(speedOfSound),
              utcMs: startedAtUtcMs,
              source: TemperatureReading.sourceStart,
            ),
          ]
        : log;
    return _copy(
      speedOfSound: speedOfSound,
      temperatureLog: appendTemperatureReading(base, reading),
    );
  }

  AnalysisSetup _copy({
    required double speedOfSound,
    required List<TemperatureReading>? temperatureLog,
  }) => AnalysisSetup(
    micSpacing: micSpacing,
    channelOffset: channelOffset,
    swapChannels: swapChannels,
    speedOfSound: speedOfSound,
    lanes: lanes,
    speedLimitKmh: speedLimitKmh,
    startedAtUtcMs: startedAtUtcMs,
    segments: segments,
    temperatureLog: temperatureLog,
  );

  /// Wall-clock time in UTC ms at [offsetS] of the recorded signal.
  int utcMsAt(double offsetS) => utcMsAtOffset(
    segments ?? const [],
    offsetS,
    fallbackStartUtcMs: startedAtUtcMs,
  );

  /// b/c in s.
  double get maxTdoa => micSpacing / speedOfSound;

  /// The same setup with another b and Δ0 (learned from the passes).
  AnalysisSetup withCalibration({
    required double micSpacing,
    required double channelOffset,
  }) => AnalysisSetup(
    micSpacing: micSpacing,
    channelOffset: channelOffset,
    swapChannels: swapChannels,
    speedOfSound: speedOfSound,
    lanes: lanes,
    speedLimitKmh: speedLimitKmh,
    startedAtUtcMs: startedAtUtcMs,
    segments: segments,
    temperatureLog: temperatureLog,
  );

  /// The lane vehicles with [direction] use (technik.pdf 5.3), or null;
  /// a two-way lane (direction 0) serves both directions.
  LaneGeometry? laneFor(int direction) {
    for (final l in lanes) {
      if (l.direction == direction || l.direction == 0) return l;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'micSpacing': micSpacing,
    'channelOffset': channelOffset,
    'swapChannels': swapChannels,
    'speedOfSound': speedOfSound,
    'speedLimitKmh': speedLimitKmh,
    'startedAtUtcMs': startedAtUtcMs,
    if ((segments?.length ?? 0) > 1)
      'segments': [for (final s in segments!) s.toJson()],
    if ((temperatureLog?.length ?? 0) > 1)
      'temperatureLog': [for (final r in temperatureLog!) r.toJson()],
    'lanes': [
      for (final l in lanes)
        {
          'index': l.index,
          'direction': l.direction,
          'slantDistance': l.slantDistance,
        },
    ],
  };
}

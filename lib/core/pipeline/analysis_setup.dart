import '../series/recording_segment.dart';

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

  /// Wall-clock time in UTC ms at [offsetS] of the recorded signal.
  int utcMsAt(double offsetS) => utcMsAtOffset(
    segments ?? const [],
    offsetS,
    fallbackStartUtcMs: startedAtUtcMs,
  );

  /// b/c in s.
  double get maxTdoa => micSpacing / speedOfSound;

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

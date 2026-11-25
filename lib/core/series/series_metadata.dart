import 'recording_segment.dart';
import 'temperature_log.dart';

/// Lane entry of [SeriesMetadata].
class LaneMetadata {
  const LaneMetadata({
    required this.horizontalDistance,
    required this.direction,
    required this.slantDistance,
  });

  factory LaneMetadata.fromJson(Map<String, dynamic> json) => LaneMetadata(
    horizontalDistance: (json['horizontalDistanceM'] as num).toDouble(),
    direction: (json['direction'] as num).toInt(),
    slantDistance: (json['slantDistanceM'] as num).toDouble(),
  );

  final double horizontalDistance;
  final int direction;
  final double slantDistance;

  Map<String, dynamic> toJson() => {
    'horizontalDistanceM': horizontalDistance,
    'direction': direction,
    'slantDistanceM': slantDistance,
  };
}

/// Device calibration used by a series (technik.pdf 7.1).
class CalibrationMetadata {
  const CalibrationMetadata({
    required this.micSpacing,
    required this.channelOffset,
    required this.calibratedAtUtcMs,
    required this.temperatureC,
  });

  factory CalibrationMetadata.fromJson(Map<String, dynamic> json) =>
      CalibrationMetadata(
        micSpacing: (json['micSpacingM'] as num).toDouble(),
        channelOffset: (json['channelOffsetS'] as num).toDouble(),
        calibratedAtUtcMs: (json['calibratedAtUtcMs'] as num).toInt(),
        temperatureC: (json['temperatureC'] as num).toDouble(),
      );

  final double micSpacing;
  final double channelOffset;
  final int calibratedAtUtcMs;
  final double temperatureC;

  Map<String, dynamic> toJson() => {
    'micSpacingM': micSpacing,
    'channelOffsetS': channelOffset,
    'calibratedAtUtcMs': calibratedAtUtcMs,
    'temperatureC': temperatureC,
  };
}

/// Content of `metadata.json` next to the raw WAV of a series
/// (technik.pdf 4.4 last paragraph).
class SeriesMetadata {
  const SeriesMetadata({
    required this.seriesId,
    required this.siteName,
    required this.deviceModel,
    required this.audioSource,
    required this.effects,
    required this.sampleRate,
    required this.lanes,
    required this.micHeight,
    required this.sourceHeight,
    required this.temperatureC,
    required this.speedOfSound,
    required this.speedLimitKmh,
    required this.swapChannels,
    required this.startedAtUtcMs,
    required this.calibration,
    required this.config,
    required this.simulated,
    required this.saveRawAudio,
    this.inputDevice = 'intern',
    this.collectClips = false,
    this.segments = const [],
    this.temperatureAutoUpdate = false,
    this.temperatureLog = const [],
  });

  /// Channel convention of the stored WAV (see docs/architecture.md).
  static const channelMappingText =
      'left = microphone at x = -b/2, right = microphone at x = +b/2; '
      'TDOA = arrival left - arrival right = +b/c*u + delta0';

  factory SeriesMetadata.fromJson(Map<String, dynamic> json) => SeriesMetadata(
    seriesId: (json['seriesId'] as num).toInt(),
    siteName: json['siteName'] as String,
    deviceModel: json['deviceModel'] as String,
    audioSource: json['audioSource'] as String,
    effects: {
      for (final e in (json['effects'] as Map).entries)
        '${e.key}': '${e.value}',
    },
    sampleRate: (json['sampleRate'] as num).toInt(),
    lanes: [
      for (final l in json['lanes'] as List)
        LaneMetadata.fromJson((l as Map).cast<String, dynamic>()),
    ],
    micHeight: (json['micHeightM'] as num).toDouble(),
    sourceHeight: (json['sourceHeightM'] as num).toDouble(),
    temperatureC: (json['temperatureC'] as num).toDouble(),
    speedOfSound: (json['speedOfSound'] as num).toDouble(),
    speedLimitKmh: (json['speedLimitKmh'] as num).toDouble(),
    swapChannels: json['swapChannels'] == true,
    startedAtUtcMs: (json['startedAtUtcMs'] as num).toInt(),
    calibration: json['calibration'] == null
        ? null
        : CalibrationMetadata.fromJson(
            (json['calibration'] as Map).cast<String, dynamic>(),
          ),
    config: (json['config'] as Map).cast<String, dynamic>(),
    simulated: json['simulated'] == true,
    saveRawAudio: json['saveRawAudio'] != false,
    inputDevice: json['inputDevice'] as String? ?? 'intern',
    collectClips: json['collectClips'] == true,
    segments: [
      for (final m in json['segments'] as List? ?? const [])
        RecordingSegment.fromJson((m as Map).cast<String, dynamic>()),
    ],
    temperatureAutoUpdate: json['temperatureAutoUpdate'] == true,
    temperatureLog: [
      for (final m in json['temperatureLog'] as List? ?? const [])
        TemperatureReading.fromJson((m as Map).cast<String, dynamic>()),
    ],
  );

  final int seriesId;
  final String siteName;
  final String deviceModel;
  final String audioSource;
  final Map<String, String> effects;
  final int sampleRate;
  final List<LaneMetadata> lanes;
  final double micHeight;
  final double sourceHeight;
  final double temperatureC;
  final double speedOfSound;
  final double speedLimitKmh;

  /// Channels were swapped according to the channel check (Task_05).
  final bool swapChannels;
  final int startedAtUtcMs;
  final CalibrationMetadata? calibration;
  final Map<String, dynamic> config;
  final bool simulated;
  final bool saveRawAudio;

  /// Audio input: `intern` or the name of an external (USB) device.
  final String inputDevice;

  /// Events are cut into a clip collection of the series while recording.
  final bool collectClips;

  /// Recording parts of a continued series; empty for one continuous
  /// recording from [startedAtUtcMs].
  final List<RecordingSegment> segments;

  /// The temperature is fetched again while recording (GPS + weather
  /// service).
  final bool temperatureAutoUpdate;

  /// Temperature readings over the recording, starting with the start
  /// value; empty if the temperature never changed.
  final List<TemperatureReading> temperatureLog;

  SeriesMetadata withTemperatureLog(List<TemperatureReading> log) =>
      SeriesMetadata.fromJson({
        ...toJson(),
        'temperatureLog': [for (final r in log) r.toJson()],
      });

  SeriesMetadata withSegments(List<RecordingSegment> segments) =>
      SeriesMetadata.fromJson({
        ...toJson(),
        'segments': [for (final s in segments) s.toJson()],
      });

  Map<String, dynamic> toJson() => {
    'seriesId': seriesId,
    'siteName': siteName,
    'deviceModel': deviceModel,
    'audioSource': audioSource,
    'effects': effects,
    'sampleRate': sampleRate,
    'lanes': [for (final l in lanes) l.toJson()],
    'micHeightM': micHeight,
    'sourceHeightM': sourceHeight,
    'temperatureC': temperatureC,
    'speedOfSound': speedOfSound,
    'speedLimitKmh': speedLimitKmh,
    'channelMapping': channelMappingText,
    'swapChannels': swapChannels,
    'startedAtUtcMs': startedAtUtcMs,
    'calibration': calibration?.toJson(),
    'config': config,
    'simulated': simulated,
    'saveRawAudio': saveRawAudio,
    'inputDevice': inputDevice,
    'collectClips': collectClips,
    if (segments.isNotEmpty) 'segments': [for (final s in segments) s.toJson()],
    'temperatureAutoUpdate': temperatureAutoUpdate,
    if (temperatureLog.isNotEmpty)
      'temperatureLog': [for (final r in temperatureLog) r.toJson()],
  };
}

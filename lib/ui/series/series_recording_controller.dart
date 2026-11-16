import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/stereo_recorder.dart';
import '../../audio/wav.dart';
import '../../core/series/series_metadata.dart';
import '../../core/signal/level.dart';
import '../../core/signal/pcm.dart';
import '../../core/sim/traffic.dart';
import '../providers.dart';

/// What the user chose on the start screen.
class SeriesStartRequest {
  const SeriesStartRequest({
    required this.siteId,
    required this.temperatureC,
    this.simulate = false,
    this.saveRawAudio = true,
  });

  final int siteId;
  final double temperatureC;
  final bool simulate;
  final bool saveRawAudio;
}

class SeriesRecordingState {
  const SeriesRecordingState({
    this.running = false,
    this.starting = false,
    this.seriesId,
    this.elapsedS = 0,
    this.left = ChannelLevel.silence,
    this.right = ChannelLevel.silence,
    this.leftClipSeen = false,
    this.rightClipSeen = false,
    this.info,
    this.error,
  });

  final bool running;
  final bool starting;
  final int? seriesId;

  /// Recorded signal duration in s (from the sample count).
  final double elapsedS;
  final ChannelLevel left;
  final ChannelLevel right;
  final bool leftClipSeen;
  final bool rightClipSeen;
  final RecordingInfo? info;
  final String? error;

  SeriesRecordingState copyWith({
    bool? running,
    bool? starting,
    double? elapsedS,
    ChannelLevel? left,
    ChannelLevel? right,
    bool? leftClipSeen,
    bool? rightClipSeen,
  }) => SeriesRecordingState(
    running: running ?? this.running,
    starting: starting ?? this.starting,
    seriesId: seriesId,
    elapsedS: elapsedS ?? this.elapsedS,
    left: left ?? this.left,
    right: right ?? this.right,
    leftClipSeen: leftClipSeen ?? this.leftClipSeen,
    rightClipSeen: rightClipSeen ?? this.rightClipSeen,
    info: info,
    error: error,
  );
}

/// Receives every decoded block of a running series (live evaluation).
typedef BlockListener = void Function(StereoBlock block);

final seriesRecordingProvider =
    NotifierProvider<SeriesRecordingController, SeriesRecordingState>(
      SeriesRecordingController.new,
    );

/// Records a measurement series: streams PCM into `audio.wav` (not in
/// memory), writes `metadata.json` and the database row.
///
/// Decision (Task_04): no foreground service. The recording runs while the
/// app process lives; the screen stays on the recording page. Background
/// behaviour is checked on a real device in Task_20.
class SeriesRecordingController extends Notifier<SeriesRecordingState> {
  StreamSubscription<Uint8List>? _subscription;
  StereoRecorder? _recorder;
  WavFileWriter? _writer;
  Future<void> _pendingWrites = Future.value();
  int _frames = 0;
  final List<BlockListener> _listeners = [];

  @override
  SeriesRecordingState build() {
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      _subscription = null;
      unawaited(_recorder?.stop());
    });
    return const SeriesRecordingState();
  }

  /// The recorder of the running series (e.g. for simulation ground truth).
  StereoRecorder? get recorder => _recorder;

  void addBlockListener(BlockListener listener) => _listeners.add(listener);

  void removeBlockListener(BlockListener listener) =>
      _listeners.remove(listener);

  Future<void> start(SeriesStartRequest request) async {
    if (state.running || state.starting) return;
    state = const SeriesRecordingState(starting: true);
    try {
      final repo = ref.read(repositoryProvider);
      final storage = await ref.read(seriesStorageProvider.future);
      final config = ref.read(configProvider);
      final site = await repo.site(request.siteId);
      if (site == null) throw StateError('Standort nicht gefunden.');
      final slant = [
        for (final lane in site.spec.lanes)
          site.spec.slantDistance(lane, sourceHeight: config.sourceHeightM),
      ];
      final recorder = ref.read(recorderFactoryProvider)(
        simulate: request.simulate,
        lanes: [
          for (var i = 0; i < slant.length; i++)
            TrafficLane(
              slantDistance: slant[i],
              direction: site.spec.lanes[i].direction,
            ),
        ],
      );
      final capabilities = await recorder.capabilities();
      final deviceId = await repo.ensureDevice(capabilities.deviceModel);
      final calibration = await repo.latestCalibration(deviceId);
      final startedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
      final id = await repo.createSeries(
        siteId: request.siteId,
        deviceId: deviceId,
        calibrationId: calibration?.id,
        temperatureC: request.temperatureC,
        startedAtUtcMs: startedAt,
        directory: '',
        sourceHeight: config.sourceHeightM,
        configJson: jsonEncode(config.toJson()),
        saveRawAudio: request.saveRawAudio,
        simulated: request.simulate,
      );
      final dir = await storage.create(id);
      await repo.setSeriesDirectory(id, dir.path);
      _frames = 0;
      _writer = request.saveRawAudio
          ? await WavFileWriter.open(
              storage.wavFile(id),
              channels: 2,
              sampleRate: config.sampleRate,
            )
          : null;
      _recorder = recorder;
      _subscription = recorder.pcmBlocks.listen(_onPcm);
      final info = await recorder.start(sampleRate: config.sampleRate);
      final series = (await repo.series(id))!;
      await storage.writeMetadata(
        SeriesMetadata(
          seriesId: id,
          siteName: site.spec.name,
          deviceModel: capabilities.deviceModel,
          audioSource: info.audioSource.platformName,
          effects: {for (final e in info.effects.entries) e.key: e.value.name},
          sampleRate: info.sampleRate,
          lanes: [
            for (var i = 0; i < slant.length; i++)
              LaneMetadata(
                horizontalDistance: site.spec.lanes[i].horizontalDistance,
                direction: site.spec.lanes[i].direction,
                slantDistance: slant[i],
              ),
          ],
          micHeight: site.spec.micHeight,
          sourceHeight: config.sourceHeightM,
          temperatureC: request.temperatureC,
          speedOfSound: series.speedOfSound,
          speedLimitKmh: site.spec.speedLimitKmh,
          swapChannels: calibration?.swapChannels ?? false,
          startedAtUtcMs: startedAt,
          calibration: calibration == null
              ? null
              : CalibrationMetadata(
                  micSpacing: calibration.micSpacingM,
                  channelOffset: calibration.channelOffsetS,
                  calibratedAtUtcMs: calibration.createdAtUtcMs,
                  temperatureC: calibration.temperatureC,
                ),
          config: config.toJson(),
          simulated: request.simulate,
          saveRawAudio: request.saveRawAudio,
        ),
      );
      if (!ref.mounted) return;
      state = SeriesRecordingState(running: true, seriesId: id, info: info);
    } on MicrophonePermissionDeniedException {
      await _abort(
        'Mikrofon-Berechtigung fehlt. Bitte in den Einstellungen '
        'erlauben.',
      );
    } on PlatformException catch (e) {
      await _abort('Aufnahme fehlgeschlagen: ${e.message}');
    } catch (e) {
      await _abort('Aufnahme fehlgeschlagen: $e');
    }
  }

  Future<void> _abort(String message) async {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _recorder = null;
    final writer = _writer;
    _writer = null;
    await writer?.close();
    if (ref.mounted) state = SeriesRecordingState(error: message);
  }

  Future<void> stop() async {
    if (!state.running) return;
    final id = state.seriesId!;
    await _recorder?.stop();
    unawaited(_subscription?.cancel());
    _subscription = null;
    final writer = _writer;
    _writer = null;
    await _pendingWrites;
    await writer?.close();
    await ref
        .read(repositoryProvider)
        .finishSeries(
          id,
          endedAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        );
    if (!ref.mounted) return;
    state = state.copyWith(running: false);
    ref.invalidate(seriesListProvider);
  }

  void _onPcm(Uint8List bytes) {
    final config = ref.read(configProvider);
    final block = deinterleavePcm16Bytes(bytes);
    final writer = _writer;
    if (writer != null) {
      _pendingWrites = _pendingWrites.then((_) => writer.addPcm16Bytes(bytes));
    }
    _frames += block.length;
    for (final l in List.of(_listeners)) {
      l(block);
    }
    final left = measureLevel(block.left, clipThreshold: config.clipThreshold);
    final right = measureLevel(
      block.right,
      clipThreshold: config.clipThreshold,
    );
    state = state.copyWith(
      elapsedS: _frames / config.sampleRate,
      left: left,
      right: right,
      leftClipSeen: state.leftClipSeen || left.clipping,
      rightClipSeen: state.rightClipSeen || right.clipping,
    );
  }
}

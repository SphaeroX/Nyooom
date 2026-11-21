import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/capture.dart';
import '../../core/calibration/device_checks.dart';
import '../../core/model/acoustics.dart';
import '../../core/signal/pcm.dart';
import '../../data/database.dart';
import '../providers.dart';

/// Recording length per step. The clap steps leave time for three claps
/// after the user has walked to the clap position.
const Map<CalibrationStep, Duration> calibrationStepDuration = {
  CalibrationStep.clapsRight: Duration(seconds: 5),
  CalibrationStep.clapsLeft: Duration(seconds: 5),
  CalibrationStep.constantSignal: Duration(seconds: 10),
};

/// Lead time before a recording starts, so the user can walk the 3 m to the
/// clap position (or start the loudspeaker) after tapping the button.
class CalibrationCountdown {
  const CalibrationCountdown({
    this.seconds = 5,
    this.tick = const Duration(seconds: 1),
  });

  final int seconds;

  /// Length of one countdown second (shorter in tests).
  final Duration tick;
}

final calibrationCountdownProvider = Provider<CalibrationCountdown>(
  (_) => const CalibrationCountdown(),
);

class CalibrationState {
  const CalibrationState({
    this.temperatureC = 15,
    this.busy,
    this.countdown,
    this.right,
    this.left,
    this.stereo,
    this.mapping,
    this.processing,
    this.clipping,
    this.result,
    this.error,
    this.savedId,
  });

  final double temperatureC;

  /// Step currently counting down or being recorded.
  final CalibrationStep? busy;

  /// Seconds left before the recording of [busy] starts; null while it
  /// records.
  final int? countdown;
  final AxisMeasurement? right;
  final AxisMeasurement? left;
  final CheckResult? stereo;
  final ChannelMappingResult? mapping;
  final CheckResult? processing;
  final ClipCheckResult? clipping;
  final CalibrationResult? result;
  final String? error;
  final int? savedId;
}

final calibrationProvider =
    NotifierProvider<CalibrationController, CalibrationState>(
      CalibrationController.new,
    );

/// Latest calibration per device model and input (`intern` or e.g. the
/// name of a USB interface), for status displays.
final latestCalibrationProvider =
    FutureProvider.family<CalibrationRow?, ({String model, String input})>((
      ref,
      key,
    ) async {
      final repo = ref.watch(repositoryProvider);
      return repo.latestCalibration(
        await repo.ensureDevice(key.model, inputDevice: key.input),
      );
    });

/// Guided suitability check (technik.pdf 4.4) and calibration of b and Δ0
/// (technik.pdf 7.1).
class CalibrationController extends Notifier<CalibrationState> {
  CalibrationCapture? _capture;
  final List<StereoBlock> _recordings = [];
  int _countdownRun = 0;

  @override
  CalibrationState build() => const CalibrationState();

  void begin(CalibrationCapture capture, double temperatureC) {
    _capture = capture;
    _recordings.clear();
    state = CalibrationState(temperatureC: temperatureC);
  }

  /// Counts down [CalibrationCountdown.seconds], then records [step].
  Future<void> recordAfterCountdown(CalibrationStep step) async {
    if (_capture == null) throw StateError('begin() first');
    final run = ++_countdownRun;
    final countdown = ref.read(calibrationCountdownProvider);
    for (var left = countdown.seconds; left > 0; left--) {
      state = _copy(busy: step, countdown: left);
      await Future<void>.delayed(countdown.tick);
      if (!ref.mounted || run != _countdownRun) return;
    }
    await record(step);
  }

  /// Aborts a running countdown; nothing is recorded.
  void cancelCountdown() {
    if (state.countdown == null) return;
    _countdownRun++;
    state = _copy(busy: null);
  }

  /// Whether [step] has a usable result: claps were detected on that side
  /// (and, once both sides exist, the stereo check passed), or the constant
  /// signal showed no processing.
  bool stepPassed(CalibrationStep step) => switch (step) {
    CalibrationStep.clapsRight => (state.right?.count ?? 0) > 0,
    CalibrationStep.clapsLeft =>
      (state.left?.count ?? 0) > 0 && (state.stereo?.passed ?? false),
    CalibrationStep.constantSignal => state.processing?.passed ?? false,
  };

  Future<void> record(CalibrationStep step) async {
    final capture = _capture;
    if (capture == null) throw StateError('begin() first');
    state = _copy(busy: step, error: null);
    try {
      final signal = await capture.capture(
        step,
        calibrationStepDuration[step]!,
      );
      if (!ref.mounted) return;
      _recordings.add(signal);
      final config = ref.read(configProvider);
      final c = speedOfSound(state.temperatureC);
      // External microphones may be placed further apart than a phone's.
      final maxSpacing = capture.inputName == 'intern'
          ? DeviceCheckLimits.defaultMaxMicSpacing
          : DeviceCheckLimits.externalMaxMicSpacing;
      var right = state.right, left = state.left;
      var processing = state.processing;
      switch (step) {
        case CalibrationStep.clapsRight:
          right = measureAxis(
            signal,
            config: config,
            speedOfSound: c,
            maxMicSpacing: maxSpacing,
          );
        case CalibrationStep.clapsLeft:
          left = measureAxis(
            signal,
            config: config,
            speedOfSound: c,
            maxMicSpacing: maxSpacing,
          );
        case CalibrationStep.constantSignal:
          processing = checkNoProcessing(signal, sampleRate: config.sampleRate);
      }
      final clipping = checkClipping(
        _recordings,
        clipThreshold: config.clipThreshold,
      );
      CheckResult? stereo;
      ChannelMappingResult? mapping;
      CalibrationResult? result;
      if (right != null) mapping = checkChannelMapping(right: right);
      if (right != null && left != null) {
        stereo = checkStereo(right: right, left: left, speedOfSound: c);
        if (stereo.passed) {
          result = calibrate(
            rightDelay: right.delay,
            leftDelay: left.delay,
            speedOfSound: c,
            swapChannels: mapping!.swapChannels,
          );
        }
      }
      state = CalibrationState(
        temperatureC: state.temperatureC,
        right: right,
        left: left,
        stereo: stereo,
        mapping: mapping,
        processing: processing,
        clipping: clipping,
        result: result,
      );
    } catch (e) {
      if (ref.mounted) {
        state = _copy(busy: null, error: 'Aufnahme fehlgeschlagen: $e');
      }
    }
  }

  /// Stores the calibration for the device; returns its id.
  Future<int> save() async {
    final result = state.result;
    final capture = _capture;
    if (result == null || capture == null) {
      throw StateError('No complete calibration');
    }
    final repo = ref.read(repositoryProvider);
    final deviceId = await repo.ensureDevice(
      capture.deviceModel,
      inputDevice: capture.inputName,
    );
    final checks = {
      'stereo': state.stereo?.toJson(),
      'processing': state.processing?.toJson(),
      'clipping': state.clipping?.toJson(),
      'channelMapping': state.mapping?.toJson(),
      'deltaRightS': state.right?.delay,
      'deltaLeftS': state.left?.delay,
    };
    final id = await repo.addCalibration(
      CalibrationsCompanion.insert(
        deviceId: deviceId,
        micSpacingM: result.micSpacing,
        channelOffsetS: result.channelOffset,
        temperatureC: state.temperatureC,
        swapChannels: Value(result.swapChannels),
        createdAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
        checksJson: Value(jsonEncode(checks)),
      ),
    );
    ref.invalidate(latestCalibrationProvider);
    if (ref.mounted) {
      state = CalibrationState(
        temperatureC: state.temperatureC,
        right: state.right,
        left: state.left,
        stereo: state.stereo,
        mapping: state.mapping,
        processing: state.processing,
        clipping: state.clipping,
        result: state.result,
        savedId: id,
      );
    }
    return id;
  }

  CalibrationState _copy({
    CalibrationStep? busy,
    int? countdown,
    String? error,
  }) => CalibrationState(
    temperatureC: state.temperatureC,
    busy: busy,
    countdown: countdown,
    right: state.right,
    left: state.left,
    stereo: state.stereo,
    mapping: state.mapping,
    processing: state.processing,
    clipping: state.clipping,
    result: state.result,
    error: error,
  );
}

import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio/capture.dart';
import '../../core/calibration/device_checks.dart';
import '../../core/model/acoustics.dart';
import '../../core/signal/pcm.dart';
import '../../data/database.dart';
import '../providers.dart';

/// Recording length per step.
const Map<CalibrationStep, Duration> calibrationStepDuration = {
  CalibrationStep.clapsRight: Duration(seconds: 3),
  CalibrationStep.clapsLeft: Duration(seconds: 3),
  CalibrationStep.constantSignal: Duration(seconds: 10),
};

class CalibrationState {
  const CalibrationState({
    this.temperatureC = 15,
    this.busy,
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

  /// Step currently being recorded.
  final CalibrationStep? busy;
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

/// Latest calibration per device model (for status displays).
final latestCalibrationProvider =
    FutureProvider.family<CalibrationRow?, String>((ref, model) async {
      final repo = ref.watch(repositoryProvider);
      return repo.latestCalibration(await repo.ensureDevice(model));
    });

/// Guided suitability check (technik.pdf 4.4) and calibration of b and Δ0
/// (technik.pdf 7.1).
class CalibrationController extends Notifier<CalibrationState> {
  CalibrationCapture? _capture;
  final List<StereoBlock> _recordings = [];

  @override
  CalibrationState build() => const CalibrationState();

  void begin(CalibrationCapture capture, double temperatureC) {
    _capture = capture;
    _recordings.clear();
    state = CalibrationState(temperatureC: temperatureC);
  }

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
      var right = state.right, left = state.left;
      var processing = state.processing;
      switch (step) {
        case CalibrationStep.clapsRight:
          right = measureAxis(signal, config: config, speedOfSound: c);
        case CalibrationStep.clapsLeft:
          left = measureAxis(signal, config: config, speedOfSound: c);
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

  CalibrationState _copy({CalibrationStep? busy, String? error}) =>
      CalibrationState(
        temperatureC: state.temperatureC,
        busy: busy,
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

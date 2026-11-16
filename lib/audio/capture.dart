import 'dart:async';
import 'dart:typed_data';

import '../core/signal/pcm.dart';
import '../core/sim/calibration_signals.dart';
import 'stereo_recorder.dart';

/// Steps of the calibration assistant that need a recording.
enum CalibrationStep {
  /// Claps beyond the right microphone (x > 0).
  clapsRight,

  /// Claps beyond the left microphone (x < 0).
  clapsLeft,

  /// 10 s constant noise from a loudspeaker.
  constantSignal,
}

/// Records the signal of one calibration step.
abstract class CalibrationCapture {
  String get deviceModel;
  String get inputName;
  Future<StereoBlock> capture(CalibrationStep step, Duration duration);
}

/// Collects [duration] of audio from [recorder].
Future<StereoBlock> recordFor(
  StereoRecorder recorder,
  Duration duration, {
  required int sampleRate,
  int? inputDeviceId,
}) async {
  final bytes = BytesBuilder(copy: false);
  final needed = (duration.inMicroseconds * sampleRate / 1e6).round() * 4;
  final done = Completer<void>();
  final sub = recorder.pcmBlocks.listen((b) {
    bytes.add(b);
    if (bytes.length >= needed && !done.isCompleted) done.complete();
  });
  try {
    await recorder.start(sampleRate: sampleRate, inputDeviceId: inputDeviceId);
    await done.future;
  } finally {
    await recorder.stop();
    await sub.cancel();
  }
  final all = bytes.toBytes();
  return deinterleavePcm16Bytes(
    Uint8List.sublistView(all, 0, needed > all.length ? all.length : needed),
  );
}

/// Real recording through the platform recorder.
class RecorderCalibrationCapture implements CalibrationCapture {
  RecorderCalibrationCapture({
    required this.recorder,
    required this.deviceModel,
    required this.sampleRate,
    this.inputDeviceId,
    this.inputName = 'intern',
  });

  final StereoRecorder recorder;
  final int sampleRate;
  final int? inputDeviceId;
  @override
  final String deviceModel;
  @override
  final String inputName;

  @override
  Future<StereoBlock> capture(CalibrationStep step, Duration duration) =>
      recordFor(
        recorder,
        duration,
        sampleRate: sampleRate,
        inputDeviceId: inputDeviceId,
      );
}

/// Synthetic calibration signals of a simulated phone (no device needed).
class SimulatedCalibrationCapture implements CalibrationCapture {
  SimulatedCalibrationCapture({
    this.micSpacing = 0.15,
    this.channelOffset = 4e-6,
    this.speedOfSound = 343,
  });

  final double micSpacing;
  final double channelOffset;
  final double speedOfSound;

  @override
  String get deviceModel => 'Simulation';
  @override
  String get inputName => 'intern';

  @override
  Future<StereoBlock> capture(CalibrationStep step, Duration duration) async {
    final seconds = duration.inMilliseconds / 1000;
    return switch (step) {
      CalibrationStep.clapsRight => axialBursts(
        micSpacing: micSpacing,
        speedOfSound: speedOfSound,
        side: 1,
        channelOffset: channelOffset,
        durationS: seconds,
      ),
      CalibrationStep.clapsLeft => axialBursts(
        micSpacing: micSpacing,
        speedOfSound: speedOfSound,
        side: -1,
        channelOffset: channelOffset,
        durationS: seconds,
        seed: 5,
      ),
      CalibrationStep.constantSignal => constantNoise(durationS: seconds),
    };
  }
}

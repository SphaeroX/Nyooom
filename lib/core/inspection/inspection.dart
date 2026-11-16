import 'dart:math' as math;
import 'dart:typed_data';

import '../config/nyooom_config.dart';
import '../dsp/gcc_phat.dart';
import '../dsp/spectrogram.dart';
import '../signal/pcm.dart';
import 'heatmap.dart';

/// Everything the visual inspection shows for one excerpt
/// (technik.pdf 10, step 2).
class InspectionData {
  const InspectionData({
    required this.startS,
    required this.durationS,
    required this.levelTimes,
    required this.levelDb,
    required this.correlogram,
    required this.correlogramImage,
    required this.spectrogram,
    required this.spectrogramImage,
  });

  /// Start of the excerpt within the recording in s; all times below are
  /// relative to it.
  final double startS;
  final double durationS;
  final Float64List levelTimes;
  final Float64List levelDb;
  final Correlogram correlogram;
  final RgbaImage correlogramImage;
  final Spectrogram spectrogram;
  final RgbaImage spectrogramImage;
}

/// Level step of the level track in s.
const double inspectionLevelStepS = 0.05;

/// Dynamic range shown in the spectrogram image in dB.
const double spectrogramRangeDb = 60;

/// Computes level track, correlogram and spectrogram of [signal]
/// (an excerpt starting at [startS]).
InspectionData computeInspection(
  StereoBlock signal, {
  required double startS,
  required NyooomConfig config,
  required double micSpacing,
  required double speedOfSound,
}) {
  final fs = config.sampleRate;
  final step = (inspectionLevelStepS * fs).round();
  final levelCount = signal.length ~/ step;
  final levelTimes = Float64List(levelCount);
  final levelDb = Float64List(levelCount);
  for (var k = 0; k < levelCount; k++) {
    var acc = 0.0;
    for (var i = k * step; i < (k + 1) * step; i++) {
      final s = 0.5 * (signal.left[i] + signal.right[i]);
      acc += s * s;
    }
    levelTimes[k] = (k + 0.5) * step / fs;
    levelDb[k] = 10 * math.log(acc / step + 1e-20) / math.ln10;
  }

  final correlogram = GccPhat(
    config: config,
    micSpacing: micSpacing,
    speedOfSound: speedOfSound,
  ).correlogram(signal);
  final correlogramImage = heatmapRgba(
    correlogram.values,
    rows: correlogram.rowCount,
    columns: correlogram.lagCount,
    min: 0,
    max: 1,
  );

  final sum = Float64List(signal.length);
  for (var i = 0; i < sum.length; i++) {
    sum[i] = 0.5 * (signal.left[i] + signal.right[i]);
  }
  final spectrogram = Spectrogram.compute(sum, config: config);
  var maxDb = -double.infinity;
  for (final v in spectrogram.powerDb) {
    if (v > maxDb) maxDb = v;
  }
  final spectrogramImage = heatmapRgba(
    spectrogram.powerDb,
    rows: spectrogram.rowCount,
    columns: spectrogram.binCount,
    min: maxDb - spectrogramRangeDb,
    max: maxDb,
  );

  return InspectionData(
    startS: startS,
    durationS: signal.length / fs,
    levelTimes: levelTimes,
    levelDb: levelDb,
    correlogram: correlogram,
    correlogramImage: correlogramImage,
    spectrogram: spectrogram,
    spectrogramImage: spectrogramImage,
  );
}

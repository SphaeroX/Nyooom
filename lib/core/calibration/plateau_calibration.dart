import '../config/nyooom_config.dart';
import '../dsp/gcc_phat.dart';
import '../pipeline/analysis_setup.dart';
import '../pipeline/event_evaluator.dart';

/// Effective microphone spacing and channel offset read from one pass.
class PlateauEstimate {
  const PlateauEstimate({
    required this.micSpacing,
    required this.channelOffset,
    required this.blocksBefore,
    required this.blocksAfter,
  });

  /// Effective b in m: the spacing projected onto the direction of the
  /// road, which is what the model Δ = b/c·u needs.
  final double micSpacing;

  /// Δ0 in s.
  final double channelOffset;

  /// Blocks used on the side with u < 0 and with u > 0.
  final int blocksBefore;
  final int blocksAfter;
}

/// b and Δ0 from the two plateaus of the TDOA curve of a pass.
///
/// Far before and after the pass the vehicle stands almost in line with
/// the microphones, |u| → 1, and the delay settles at Δ0 ± b/c. With the
/// model value u of each block (from the fitted curve, [directionCosine]
/// over absolute time) the medians of both sides give
/// b/c = (Δ₊ − Δ₋)/(u₊ − u₋) and Δ0 = Δ₊ − b/c·u₊.
///
/// Only blocks with |u| ≥ [NyooomConfig.plateauMinDirectionCosine] and a
/// correlation maximum of at least [NyooomConfig.trackMinStrength] count;
/// null if one side has fewer than [NyooomConfig.fitMinPoints] of them
/// (slow or distant vehicle, window too short).
///
/// The fit that supplies u was made with the assumed b; a wrong b shifts
/// its κ and with it u at the plateau by about 1 %. A second round with
/// the estimate removes that.
PlateauEstimate? estimatePlateaus(
  Correlogram correlogram, {
  required double timeOffsetS,
  required double Function(double t) directionCosine,
  required double speedOfSound,
  required NyooomConfig config,
}) {
  final before = <double>[], after = <double>[];
  var uBefore = 0.0, uAfter = 0.0;
  for (var i = 0; i < correlogram.rowCount; i++) {
    if (correlogram.peakWeights[i] < config.trackMinStrength) continue;
    final u = directionCosine(timeOffsetS + correlogram.times[i]);
    if (u.abs() < config.plateauMinDirectionCosine) continue;
    if (u < 0) {
      before.add(correlogram.peakDelays[i]);
      uBefore += u;
    } else {
      after.add(correlogram.peakDelays[i]);
      uAfter += u;
    }
  }
  if (before.length < config.fitMinPoints ||
      after.length < config.fitMinPoints) {
    return null;
  }
  uBefore /= before.length;
  uAfter /= after.length;
  final dBefore = _median(before), dAfter = _median(after);
  final maxTdoa = (dAfter - dBefore) / (uAfter - uBefore);
  if (maxTdoa <= 0) return null;
  return PlateauEstimate(
    micSpacing: maxTdoa * speedOfSound,
    channelOffset: dAfter - maxTdoa * uAfter,
    blocksBefore: before.length,
    blocksAfter: after.length,
  );
}

/// [estimatePlateaus] for a track of the evaluation; null without a valid
/// fit.
PlateauEstimate? estimateTrackPlateaus(
  EventAnalysis track, {
  required AnalysisSetup setup,
  required NyooomConfig config,
}) {
  final fit = track.fit, fitter = track.fitter;
  final correlogram = track.correlogram;
  if (fit == null || fitter == null || correlogram == null) return null;
  if (fit.reason != null) return null;
  return estimatePlateaus(
    correlogram,
    timeOffsetS: track.windowStartS,
    directionCosine: (t) =>
        (fitter.tdoaAt(t, kappa: fit.kappa, t0: fit.t0) - setup.channelOffset) /
        setup.maxTdoa,
    speedOfSound: setup.speedOfSound,
    config: config,
  );
}

/// b and Δ0 learned from the passes of a series, as stored with it.
class LearnedSpacing {
  const LearnedSpacing({
    required this.micSpacing,
    required this.channelOffset,
    required this.passCount,
  });

  /// Effective b in m and Δ0 in s.
  final double micSpacing;
  final double channelOffset;

  /// Passes the medians were taken over.
  final int passCount;
}

/// Verdict on the plateau estimates of a series.
class SpacingLearning {
  const SpacingLearning({
    required this.calibratedSpacing,
    required this.calibratedOffset,
    required this.estimate,
    required this.passCount,
    required this.active,
    required this.warning,
  });

  /// b and Δ0 the series was recorded with (calibration or defaults).
  final double calibratedSpacing;
  final double calibratedOffset;

  /// Median over the passes, null without any estimate.
  final PlateauEstimate? estimate;
  final int passCount;

  /// Enough passes and a plausible value: [learned] replaces the
  /// calibration.
  final bool active;

  /// Enough passes, but too far from the calibration to be the device.
  final bool warning;

  /// Relative deviation learned/calibrated − 1.
  double? get deviation =>
      estimate == null ? null : estimate!.micSpacing / calibratedSpacing - 1;

  LearnedSpacing? get learned => active
      ? LearnedSpacing(
          micSpacing: estimate!.micSpacing,
          channelOffset: estimate!.channelOffset,
          passCount: passCount,
        )
      : null;

  /// [setup] with the learned values if they are [active].
  AnalysisSetup applyTo(AnalysisSetup setup) => active
      ? setup.withCalibration(
          micSpacing: estimate!.micSpacing,
          channelOffset: estimate!.channelOffset,
        )
      : setup;
}

/// Decides whether the plateau [estimates] of a series replace its
/// calibration ([micSpacing], [channelOffset]): at least
/// [NyooomConfig.plateauMinCount] passes, and the median spacing within
/// [NyooomConfig.plateauMaxDeviation] of the calibrated one.
SpacingLearning judgeSpacing(
  List<PlateauEstimate> estimates, {
  required double micSpacing,
  required double channelOffset,
  required NyooomConfig config,
}) {
  final median = medianPlateauEstimate(estimates);
  final enough = estimates.length >= config.plateauMinCount;
  final plausible =
      median != null &&
      (median.micSpacing / micSpacing - 1).abs() <= config.plateauMaxDeviation;
  return SpacingLearning(
    calibratedSpacing: micSpacing,
    calibratedOffset: channelOffset,
    estimate: median,
    passCount: estimates.length,
    active: enough && plausible,
    warning: enough && !plausible,
  );
}

/// Median spacing and median offset over the passes of a recording.
PlateauEstimate? medianPlateauEstimate(List<PlateauEstimate> estimates) {
  if (estimates.isEmpty) return null;
  return PlateauEstimate(
    micSpacing: _median([for (final e in estimates) e.micSpacing]),
    channelOffset: _median([for (final e in estimates) e.channelOffset]),
    blocksBefore: estimates.fold(0, (sum, e) => sum + e.blocksBefore),
    blocksAfter: estimates.fold(0, (sum, e) => sum + e.blocksAfter),
  );
}

double _median(List<double> values) {
  final sorted = List.of(values)..sort();
  final n = sorted.length;
  return n.isOdd ? sorted[n ~/ 2] : 0.5 * (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]);
}

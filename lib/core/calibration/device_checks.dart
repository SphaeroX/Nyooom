import 'dart:math' as math;
import 'dart:typed_data';

import '../config/nyooom_config.dart';
import '../dsp/fft.dart';
import '../dsp/gcc_phat.dart';
import '../signal/pcm.dart';

/// Thresholds of the suitability checks (technik.pdf 4.4). They are not part
/// of the 9.2 table; chosen for the prototype and documented in Task_05.
class DeviceCheckLimits {
  DeviceCheckLimits._();

  /// A clap must rise this much above the median frame energy.
  static const transientRiseDb = 15.0;
  static const transientFrameS = 0.005;
  static const transientHoldOffS = 0.3;

  /// Search range for the TDOA while b is still unknown (internal mics).
  static const defaultMaxMicSpacing = 0.3;

  /// Below this spacing the two maxima count as "both at zero" (mono).
  static const minMicSpacing = 0.05;

  /// Check 2: level spread over 100-ms frames and spectral change.
  static const levelFrameS = 0.1;
  static const levelSettleS = 0.5;
  static const levelToleranceDb = 1.5;
  static const spectrumToleranceDb = 2.0;
  static const spectrumSegmentS = 3.0;
}

/// Result of one check.
class CheckResult {
  const CheckResult({required this.passed, required this.message});
  final bool passed;
  final String message;

  Map<String, dynamic> toJson() => {'passed': passed, 'message': message};
}

/// TDOA of the claps in one recording.
class AxisMeasurement {
  const AxisMeasurement({
    required this.delay,
    required this.weight,
    required this.count,
  });

  /// Median TDOA (left minus right arrival) in s; NaN without claps.
  final double delay;
  final double weight;

  /// Number of claps found.
  final int count;
}

class ChannelMappingResult extends CheckResult {
  const ChannelMappingResult({
    required super.passed,
    required super.message,
    required this.swapChannels,
  });

  /// True if the left channel belongs to the microphone at +x.
  final bool swapChannels;
}

class ClipCheckResult extends CheckResult {
  const ClipCheckResult({
    required super.passed,
    required super.message,
    required this.peak,
  });

  /// Largest absolute sample as fraction of full scale.
  final double peak;
}

/// Result of the calibration of b and Δ0 (technik.pdf 7.1).
class CalibrationResult {
  const CalibrationResult({
    required this.micSpacing,
    required this.channelOffset,
    required this.maxTdoa,
    required this.swapChannels,
  });

  final double micSpacing;
  final double channelOffset;

  /// b/c in s.
  final double maxTdoa;
  final bool swapChannels;
}

/// Onsets (sample indices) of claps or other transients.
List<int> findTransients(StereoBlock signal, {required int sampleRate}) {
  final frame = (DeviceCheckLimits.transientFrameS * sampleRate).round();
  final frames = signal.length ~/ frame;
  if (frames == 0) return const [];
  final energy = Float64List(frames);
  for (var f = 0; f < frames; f++) {
    var acc = 0.0;
    for (var i = f * frame; i < (f + 1) * frame; i++) {
      final s = 0.5 * (signal.left[i] + signal.right[i]);
      acc += s * s;
    }
    energy[f] = acc / frame;
  }
  final sorted = Float64List.fromList(energy)..sort();
  final floor = math.max(sorted[frames ~/ 2], 1e-20);
  final threshold =
      floor * math.pow(10, DeviceCheckLimits.transientRiseDb / 10);
  final holdOff = (DeviceCheckLimits.transientHoldOffS * sampleRate / frame)
      .round();
  final onsets = <int>[];
  var f = 1;
  while (f < frames) {
    if (energy[f] > threshold && energy[f - 1] <= threshold) {
      onsets.add(f * frame);
      f += holdOff;
    } else {
      f++;
    }
  }
  return onsets;
}

/// Median GCC-PHAT TDOA over all claps of [signal] (technik.pdf 7.1 step 3).
AxisMeasurement measureAxis(
  StereoBlock signal, {
  required NyooomConfig config,
  required double speedOfSound,
  double maxMicSpacing = DeviceCheckLimits.defaultMaxMicSpacing,
}) {
  final gcc = GccPhat(
    config: config,
    micSpacing: maxMicSpacing,
    speedOfSound: speedOfSound,
  );
  final pre = (0.005 * config.sampleRate).round();
  final delays = <double>[], weights = <double>[];
  for (final onset in findTransients(signal, sampleRate: config.sampleRate)) {
    final from = math.max(0, onset - pre);
    final to = from + config.gccBlockLength;
    if (to > signal.length) continue;
    final estimate = gcc.singleTdoa(signal, from: from, to: to);
    delays.add(estimate.delay);
    weights.add(estimate.weight);
  }
  if (delays.isEmpty) {
    return const AxisMeasurement(delay: double.nan, weight: 0, count: 0);
  }
  return AxisMeasurement(
    delay: _median(delays),
    weight: _median(weights),
    count: delays.length,
  );
}

double _median(List<double> values) {
  final s = List.of(values)..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m] : 0.5 * (s[m - 1] + s[m]);
}

/// Check 1: true stereo, two separate maxima near ±b/c (technik.pdf 4.4).
CheckResult checkStereo({
  required AxisMeasurement right,
  required AxisMeasurement left,
  required double speedOfSound,
}) {
  if (right.count == 0 || left.count == 0) {
    return const CheckResult(
      passed: false,
      message: 'Kein Klatschen erkannt. Bitte lauter und näher wiederholen.',
    );
  }
  final halfSpan = (right.delay - left.delay).abs() / 2;
  final spacing = halfSpan * speedOfSound;
  if (spacing < DeviceCheckLimits.minMicSpacing) {
    return const CheckResult(
      passed: false,
      message:
          'Beide Maxima liegen bei null: Das Gerät liefert ein dupliziertes '
          'Monosignal. Ein externes Stereomikrofon verwenden.',
    );
  }
  return CheckResult(
    passed: true,
    message:
        'Zwei getrennte Maxima bei ${_us(right.delay)} und ${_us(left.delay)} '
        '(entspricht ${(spacing * 100).toStringAsFixed(1)} cm).',
  );
}

/// Check 4: which channel belongs to which microphone (technik.pdf 4.4).
ChannelMappingResult checkChannelMapping({required AxisMeasurement right}) {
  final swap = right.delay < 0;
  return ChannelMappingResult(
    passed: right.count > 0,
    swapChannels: swap,
    message: swap
        ? 'Kanäle sind vertauscht (linker Kanal = rechtes Mikrofon); die App '
              'tauscht sie bei der Auswertung.'
        : 'Kanalzuordnung wie erwartet (linker Kanal = linkes Mikrofon).',
  );
}

/// Check 2: no level control or spectral processing (technik.pdf 4.4).
CheckResult checkNoProcessing(StereoBlock signal, {required int sampleRate}) {
  final frame = (DeviceCheckLimits.levelFrameS * sampleRate).round();
  final skip = (DeviceCheckLimits.levelSettleS * sampleRate).round();
  var minDb = double.infinity, maxDb = -double.infinity;
  for (var start = skip; start + frame <= signal.length; start += frame) {
    var acc = 0.0;
    for (var i = start; i < start + frame; i++) {
      acc +=
          signal.left[i] * signal.left[i] + signal.right[i] * signal.right[i];
    }
    final db = 10 * math.log(acc / (2 * frame) + 1e-30) / math.ln10;
    minDb = math.min(minDb, db);
    maxDb = math.max(maxDb, db);
  }
  final spread = maxDb - minDb;
  if (spread > DeviceCheckLimits.levelToleranceDb) {
    return CheckResult(
      passed: false,
      message:
          'Pegel regelt nach (Schwankung ${spread.toStringAsFixed(1)} dB). '
          'Vermutlich ist eine automatische Verstärkungsregelung aktiv.',
    );
  }
  final segment = (DeviceCheckLimits.spectrumSegmentS * sampleRate).round();
  if (signal.length >= 2 * segment) {
    final a = _meanSpectrumDb(signal.left, 0, segment);
    final b = _meanSpectrumDb(
      signal.left,
      signal.length - segment,
      signal.length,
    );
    final n = 2048;
    final lo = (300 / sampleRate * n).ceil();
    final hi = (8000 / sampleRate * n).floor();
    var diff = 0.0;
    for (var k = lo; k <= hi; k++) {
      diff += (a[k] - b[k]).abs();
    }
    diff /= hi - lo + 1;
    if (diff > DeviceCheckLimits.spectrumToleranceDb) {
      return CheckResult(
        passed: false,
        message:
            'Spektrum verändert sich (${diff.toStringAsFixed(1)} dB). '
            'Vermutlich ist eine Rauschunterdrückung aktiv.',
      );
    }
  }
  return CheckResult(
    passed: true,
    message: 'Pegel stabil (Schwankung ${spread.toStringAsFixed(1)} dB).',
  );
}

Float64List _meanSpectrumDb(Float64List x, int from, int to) {
  const n = 2048;
  final fft = Fft.of(n);
  final w = hannWindow(n);
  final power = Float64List(n ~/ 2 + 1);
  var count = 0;
  for (var s = from; s + n <= to; s += n ~/ 2) {
    final re = Float64List(n), im = Float64List(n);
    for (var i = 0; i < n; i++) {
      re[i] = x[s + i] * w[i];
    }
    fft.transform(re, im);
    for (var k = 0; k <= n ~/ 2; k++) {
      power[k] += re[k] * re[k] + im[k] * im[k];
    }
    count++;
  }
  return Float64List.fromList([
    for (final p in power) 10 * math.log(p / count + 1e-30) / math.ln10,
  ]);
}

/// Check 3: no sample above the clip threshold (technik.pdf 4.4).
ClipCheckResult checkClipping(
  List<StereoBlock> recordings, {
  required double clipThreshold,
}) {
  var peak = 0.0;
  for (final r in recordings) {
    for (var i = 0; i < r.length; i++) {
      peak = math.max(peak, math.max(r.left[i].abs(), r.right[i].abs()));
    }
  }
  final ok = peak <= clipThreshold;
  return ClipCheckResult(
    passed: ok,
    peak: peak,
    message: ok
        ? 'Spitzenwert ${(peak * 100).toStringAsFixed(0)} % der '
              'Vollaussteuerung.'
        : 'Übersteuerung: Spitzenwert ${(peak * 100).toStringAsFixed(0)} % '
              '(Grenze ${(clipThreshold * 100).round()} %).',
  );
}

/// b and Δ0 from the claps on both sides (technik.pdf 7.1):
/// b/c = (Δ+ − Δ−)/2, Δ0 = (Δ+ + Δ−)/2, b = c·b/c. With [swapChannels]
/// the delays are first converted to the swapped channel order.
CalibrationResult calibrate({
  required double rightDelay,
  required double leftDelay,
  required double speedOfSound,
  bool swapChannels = false,
}) {
  final plus = swapChannels ? -rightDelay : rightDelay;
  final minus = swapChannels ? -leftDelay : leftDelay;
  final maxTdoa = (plus - minus) / 2;
  return CalibrationResult(
    micSpacing: speedOfSound * maxTdoa,
    channelOffset: (plus + minus) / 2,
    maxTdoa: maxTdoa,
    swapChannels: swapChannels,
  );
}

String _us(double seconds) => '${(seconds * 1e6).toStringAsFixed(0)} µs';

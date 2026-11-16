import 'package:nyooom/core/calibration/device_checks.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/sim/calibration_signals.dart';
import 'package:test/test.dart';

void main() {
  const config = NyooomConfig();
  const c = 343.0;
  const b = 0.148;
  const offset = 7e-6;

  AxisMeasurement measure(int side, {bool swap = false, bool mono = false}) =>
      measureAxis(
        axialBursts(
          micSpacing: b,
          speedOfSound: c,
          side: side,
          channelOffset: offset,
          swapChannels: swap,
          mono: mono,
        ),
        config: config,
        speedOfSound: c,
      );

  test('finds every clap as a transient', () {
    final signal = axialBursts(micSpacing: b, speedOfSound: c, side: 1);
    final transients = findTransients(signal, sampleRate: 48000);
    expect(transients, hasLength(3));
    for (var i = 0; i < 3; i++) {
      expect(transients[i] / 48000, closeTo(0.5 + i * 0.8, 0.01));
    }
  });

  test('calibration gives b within 1 % and the offset within 2 us', () {
    final right = measure(1), left = measure(-1);
    final result = calibrate(
      rightDelay: right.delay,
      leftDelay: left.delay,
      speedOfSound: c,
    );
    expect(result.micSpacing, closeTo(b, 0.01 * b));
    expect(result.channelOffset, closeTo(offset, 2e-6));
    expect(result.swapChannels, isFalse);
  });

  test('check 1 passes for true stereo', () {
    final check = checkStereo(
      right: measure(1),
      left: measure(-1),
      speedOfSound: c,
    );
    expect(check.passed, isTrue);
  });

  test('check 1 fails for a duplicated mono signal', () {
    final check = checkStereo(
      right: measure(1, mono: true),
      left: measure(-1, mono: true),
      speedOfSound: c,
    );
    expect(check.passed, isFalse);
    expect(check.message, contains('Monosignal'));
  });

  test('check 4 detects swapped channels and calibration corrects it', () {
    final right = measure(1, swap: true), left = measure(-1, swap: true);
    final mapping = checkChannelMapping(right: right);
    expect(mapping.swapChannels, isTrue);
    expect(checkChannelMapping(right: measure(1)).swapChannels, isFalse);
    final result = calibrate(
      rightDelay: right.delay,
      leftDelay: left.delay,
      speedOfSound: c,
      swapChannels: mapping.swapChannels,
    );
    expect(result.micSpacing, closeTo(b, 0.01 * b));
    // After swapping back the channel order is the physical one again, so
    // the offset of the (physical) left channel is recovered unchanged.
    expect(result.channelOffset, closeTo(offset, 2e-6));
  });

  test('check 2 passes for a constant signal and fails with AGC', () {
    expect(
      checkNoProcessing(constantNoise(), sampleRate: 48000).passed,
      isTrue,
    );
    final agc = checkNoProcessing(
      constantNoise(agcDropDb: 8),
      sampleRate: 48000,
    );
    expect(agc.passed, isFalse);
    expect(agc.message, contains('Pegel'));
  });

  test('check 3 reports clipping above 90 %', () {
    final quiet = checkClipping([
      constantNoise(),
    ], clipThreshold: config.clipThreshold);
    expect(quiet.passed, isTrue);
    final loud = checkClipping([
      constantNoise(rms: 0.5),
    ], clipThreshold: config.clipThreshold);
    expect(loud.passed, isFalse);
    expect(loud.peak, greaterThan(0.9));
  });
}

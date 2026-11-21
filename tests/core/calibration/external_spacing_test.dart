import 'package:nyooom/core/calibration/device_checks.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/sim/calibration_signals.dart';
import 'package:test/test.dart';

/// Two separate microphones (e.g. wireless lavaliers on a bar) can be placed
/// further apart than the phone's 10 to 20 cm.
void main() {
  const config = NyooomConfig();
  const c = 343.0;
  const b = 0.6;

  AxisMeasurement measure(int side, {double? maxSpacing}) => measureAxis(
    axialBursts(micSpacing: b, speedOfSound: c, side: side),
    config: config,
    speedOfSound: c,
    maxMicSpacing: maxSpacing ?? DeviceCheckLimits.defaultMaxMicSpacing,
  );

  test('the search range for external inputs covers wide spacings', () {
    expect(DeviceCheckLimits.externalMaxMicSpacing, greaterThanOrEqualTo(b));
  });

  test('with the external range b = 60 cm is calibrated within 1 %', () {
    final right = measure(
      1,
      maxSpacing: DeviceCheckLimits.externalMaxMicSpacing,
    );
    final left = measure(
      -1,
      maxSpacing: DeviceCheckLimits.externalMaxMicSpacing,
    );
    final result = calibrate(
      rightDelay: right.delay,
      leftDelay: left.delay,
      speedOfSound: c,
    );
    expect(result.micSpacing, closeTo(b, 0.01 * b));
  });

  test('the phone range would miss it', () {
    final right = measure(1), left = measure(-1);
    final result = calibrate(
      rightDelay: right.delay,
      leftDelay: left.delay,
      speedOfSound: c,
    );
    expect((result.micSpacing - b).abs(), greaterThan(0.05));
  });

  test('recommended spacing depends on the input', () {
    expect(spacingHint(0.15, external: false), isNull);
    expect(spacingHint(0.30, external: false), isNotNull);
    expect(spacingHint(0.30, external: true), isNull);
    expect(spacingHint(0.90, external: true), contains('Fernfeld'));
    expect(spacingHint(0.03, external: true), isNotNull);
  });
}

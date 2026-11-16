import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/dsp/spectrogram.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

void main() {
  const config = NyooomConfig();

  test('a 1 kHz sine lies in the right row to better than 1 Hz', () {
    final x = Float64List.fromList(
      List.generate(
        48000,
        (n) => 0.3 * math.sin(2 * math.pi * 1000 * n / 48000),
      ),
    );
    final s = Spectrogram.compute(x, config: config);
    expect(s.binHz, closeTo(48000 / 16384, 1e-9));
    expect(s.lowHz, greaterThanOrEqualTo(config.toneBandLowHz - s.binHz));
    expect(s.highHz, lessThanOrEqualTo(config.toneBandHighHz + s.binHz));
    for (var r = 0; r < s.rowCount; r++) {
      expect(s.peakFrequency(r, 900, 1100), closeTo(1000, 1));
    }
  });

  test('frames advance by the hop and are centred', () {
    final s = Spectrogram.compute(Float64List(48000), config: config);
    expect(s.times[1] - s.times[0], closeTo(512 / 48000, 1e-12));
    expect(s.times[0], closeTo(2048 / 48000, 1e-12));
  });

  test('a passing tone goes from f_an to f_ab', () {
    final pass = VehiclePass(
      speed: fromKmh(50),
      distance: 4,
      t0: 2,
      noiseRms: 0,
      tones: const [ToneSpec(1000, 0.2)],
    );
    final rec = PassBySimulator(Scenarios.setup(backgroundRms: 0.0005))
        .render(4, [pass]);
    final sum = Float64List(rec.signal.length);
    for (var i = 0; i < sum.length; i++) {
      sum[i] = 0.5 * (rec.signal.left[i] + rec.signal.right[i]);
    }
    final s = Spectrogram.compute(sum, config: config);
    final model = rec.truths.single.model;
    final first = s.peakFrequency(0, 950, 1100);
    final last = s.peakFrequency(s.rowCount - 1, 900, 1050);
    expect(first, closeTo(model.dopplerFrequency(1000, s.times.first), 1));
    expect(last, closeTo(model.dopplerFrequency(1000, s.times.last), 1));
    expect(first - last, greaterThan(70)); // 8.4 % jump
  });
}

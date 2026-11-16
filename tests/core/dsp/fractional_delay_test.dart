import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/dsp/fractional_delay.dart';
import 'package:test/test.dart';

void main() {
  test('windowed sinc reproduces a band-limited sine between samples', () {
    const fs = 48000.0;
    const f = 0.2 * fs; // highest content the simulator produces
    final x = Float64List.fromList(
      List.generate(512, (n) => math.sin(2 * math.pi * f * n / fs + 0.3)),
    );
    for (final p in [100.0, 100.25, 200.5, 300.731, 255.999]) {
      final expected = math.sin(2 * math.pi * f * p / fs + 0.3);
      expect(fractionalSample(x, p), closeTo(expected, 1e-3));
    }
  });

  test('integer positions return the sample itself', () {
    final x = Float64List.fromList(List.generate(64, (n) => n * 0.5));
    expect(fractionalSample(x, 30), closeTo(15, 1e-12));
  });

  test('positions outside the signal read as zero', () {
    final x = Float64List.fromList(List.filled(64, 1.0));
    expect(fractionalSample(x, -40), 0);
    expect(fractionalSample(x, 200), 0);
  });
}

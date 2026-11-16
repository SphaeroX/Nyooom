import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/dsp/biquad.dart';
import 'package:test/test.dart';

const fs = 48000.0;

double gainOf(Biquad filter, double frequency) {
  final x = Float64List.fromList(
    List.generate(48000, (n) => math.sin(2 * math.pi * frequency * n / fs)),
  );
  final y = filter.processBlock(x);
  double rms(Float64List s, int from) {
    var acc = 0.0;
    for (var i = from; i < s.length; i++) {
      acc += s[i] * s[i];
    }
    return math.sqrt(acc / (s.length - from));
  }

  // Skip the first half second of transient.
  return rms(y, 24000) / rms(x, 24000);
}

void main() {
  test('high-pass at 100 Hz damps 50 Hz and keeps 1 kHz', () {
    expect(gainOf(Biquad.highPass(fs, 100), 50), lessThan(0.3));
    expect(gainOf(Biquad.highPass(fs, 100), 1000), closeTo(1, 0.01));
  });

  test('low-pass keeps the pass band and damps the stop band', () {
    expect(gainOf(Biquad.lowPass(fs, 4000), 500), closeTo(1, 0.01));
    expect(gainOf(Biquad.lowPass(fs, 4000), 16000), lessThan(0.1));
  });

  test('band-pass 500 to 4000 Hz passes its centre', () {
    final chain = BiquadChain.bandPass(fs, 500, 4000);
    expect(chain.gainAt(1414), closeTo(1, 0.05));
    expect(chain.gainAt(100), lessThan(0.1));
    expect(chain.gainAt(15000), lessThan(0.15));
  });

  test('a chain processes blocks continuously', () {
    final x = Float64List.fromList(
      List.generate(4000, (n) => math.sin(n * 0.05)),
    );
    final whole = BiquadChain.bandPass(fs, 500, 4000).processBlock(x);
    final split = BiquadChain.bandPass(fs, 500, 4000);
    final a = split.processBlock(Float64List.sublistView(x, 0, 1234));
    final b = split.processBlock(Float64List.sublistView(x, 1234));
    expect([...a, ...b], whole);
  });
}

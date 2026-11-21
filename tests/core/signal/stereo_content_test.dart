import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/signal/stereo_content.dart';
import 'package:test/test.dart';

const sampleRate = 48000;

Float64List noise(int seed, double rms, {int n = sampleRate}) {
  final rnd = math.Random(seed);
  final x = Float64List(n);
  for (var i = 0; i < n; i++) {
    // Uniform noise in [-a, a] has rms a/sqrt(3).
    x[i] = (rnd.nextDouble() * 2 - 1) * rms * math.sqrt(3);
  }
  return x;
}

StereoBlock block(Float64List left, Float64List right) =>
    StereoBlock(left, right);

void main() {
  test('identical channels are a duplicated mono signal', () {
    final x = noise(1, 0.05);
    expect(
      analyseStereoContent(block(x, Float64List.fromList(x))).kind,
      StereoContentKind.identical,
    );
  });

  test('a scaled copy is still mono (dual mono)', () {
    final x = noise(2, 0.05);
    final y = Float64List.fromList([for (final s in x) 0.5 * s]);
    expect(analyseStereoContent(block(x, y)).kind, StereoContentKind.identical);
  });

  test('two independent microphones are distinct channels', () {
    final common = noise(3, 0.03);
    final l = noise(4, 0.02), r = noise(5, 0.02);
    for (var i = 0; i < l.length; i++) {
      l[i] += common[i];
      // The shared source reaches the right microphone 20 samples later.
      r[i] += i >= 20 ? common[i - 20] : 0;
    }
    final result = analyseStereoContent(block(l, r));
    expect(result.kind, StereoContentKind.distinct);
    expect(result.correlation, lessThan(0.99));
  });

  test('one silent channel is reported (second transmitter off)', () {
    final x = noise(6, 0.05);
    final silent = Float64List(x.length);
    expect(
      analyseStereoContent(block(x, silent)).kind,
      StereoContentKind.rightSilent,
    );
    expect(
      analyseStereoContent(block(silent, x)).kind,
      StereoContentKind.leftSilent,
    );
  });

  test('without signal no verdict is given', () {
    final quiet = noise(7, 1e-5);
    expect(
      analyseStereoContent(block(quiet, noise(8, 1e-5))).kind,
      StereoContentKind.tooQuiet,
    );
  });
}

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/signal/level.dart';
import 'package:test/test.dart';

Float64List sine({
  required double amplitude,
  double frequency = 1000,
  int sampleRate = 48000,
  int length = 48000,
}) {
  return Float64List.fromList(
    List.generate(
      length,
      (n) => amplitude * math.sin(2 * math.pi * frequency * n / sampleRate),
    ),
  );
}

void main() {
  const clipThreshold = 0.9; // technik.pdf 4.4, check 3

  group('measureLevel', () {
    test(
      'sine with amplitude 0.5 gives about -9 dBFS RMS and -6 dBFS peak',
      () {
        final level = measureLevel(
          sine(amplitude: 0.5),
          clipThreshold: clipThreshold,
        );
        // RMS of a sine is A/sqrt(2): 20*log10(0.5/sqrt(2)) = -9.03 dBFS.
        expect(level.rmsDbfs, closeTo(-9.03, 0.01));
        // 1 kHz at 48 kHz hits the crest exactly: 20*log10(0.5) = -6.02 dBFS.
        expect(level.peakDbfs, closeTo(-6.02, 0.01));
        expect(level.clipping, isFalse);
      },
    );

    test('silence gives the defined minimum', () {
      final level = measureLevel(
        Float64List(1024),
        clipThreshold: clipThreshold,
      );
      expect(level.rmsDbfs, silenceDbfs);
      expect(level.peakDbfs, silenceDbfs);
      expect(level.clipping, isFalse);
    });

    test('an empty block counts as silence', () {
      final level = measureLevel(Float64List(0), clipThreshold: clipThreshold);
      expect(level.rmsDbfs, silenceDbfs);
      expect(level.peakDbfs, silenceDbfs);
    });

    test('values never drop below the defined minimum', () {
      final level = measureLevel(
        Float64List.fromList([1e-12, -1e-12]),
        clipThreshold: clipThreshold,
      );
      expect(level.rmsDbfs, silenceDbfs);
      expect(level.peakDbfs, silenceDbfs);
    });

    test('clipping is flagged above 90 % of full scale', () {
      final level = measureLevel(
        sine(amplitude: 0.95),
        clipThreshold: clipThreshold,
      );
      expect(level.clipping, isTrue);
    });

    test('negative peaks are detected as clipping too', () {
      final samples = Float64List.fromList([0.1, -0.91, 0.2]);
      expect(
        measureLevel(samples, clipThreshold: clipThreshold).clipping,
        isTrue,
      );
    });

    test('exactly 90 % is not yet clipping', () {
      final samples = Float64List.fromList([0.9, -0.9]);
      expect(
        measureLevel(samples, clipThreshold: clipThreshold).clipping,
        isFalse,
      );
    });
  });
}

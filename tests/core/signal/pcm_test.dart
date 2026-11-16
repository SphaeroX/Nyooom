import 'dart:typed_data';

import 'package:nyooom/core/signal/pcm.dart';
import 'package:test/test.dart';

void main() {
  group('deinterleavePcm16', () {
    test('splits interleaved 16-bit samples into normalized channels', () {
      final interleaved = Int16List.fromList([
        0,
        16384,
        -32768,
        32767,
        8192,
        -8192,
      ]);
      final block = deinterleavePcm16(interleaved);
      expect(block.length, 3);
      expect(block.left, [0.0, -1.0, 0.25]);
      expect(block.right[0], 0.5);
      expect(block.right[1], closeTo(32767 / 32768, 1e-12));
      expect(block.right[2], -0.25);
    });

    test('rejects an odd number of samples', () {
      expect(
        () => deinterleavePcm16(Int16List.fromList([1, 2, 3])),
        throwsArgumentError,
      );
    });
  });

  group('deinterleavePcm16Bytes', () {
    test('reads little-endian bytes as produced by AudioRecord', () {
      // L = 0x4000 (16384), R = 0xC000 (-16384)
      final bytes = Uint8List.fromList([0x00, 0x40, 0x00, 0xC0]);
      final block = deinterleavePcm16Bytes(bytes);
      expect(block.left, [0.5]);
      expect(block.right, [-0.5]);
    });

    test('rejects byte counts that are not whole stereo frames', () {
      expect(() => deinterleavePcm16Bytes(Uint8List(6)), throwsArgumentError);
    });
  });

  group('deinterleaveFloat32', () {
    test('splits interleaved float samples', () {
      final interleaved = Float32List.fromList([0.5, -0.5, 0.25, -0.25]);
      final block = deinterleaveFloat32(interleaved);
      expect(block.left, [0.5, 0.25]);
      expect(block.right, [-0.5, -0.25]);
    });

    test('rejects an odd number of samples', () {
      expect(() => deinterleaveFloat32(Float32List(3)), throwsArgumentError);
    });
  });

  group('interleavePcm16', () {
    test('is the inverse of deinterleavePcm16', () {
      final original = Int16List.fromList([
        0,
        16384,
        -32768,
        32767,
        8192,
        -8192,
      ]);
      expect(interleavePcm16(deinterleavePcm16(original)), original);
    });

    test('clamps values outside full scale', () {
      final block = StereoBlock(
        Float64List.fromList([2.0]),
        Float64List.fromList([-2.0]),
      );
      expect(interleavePcm16(block), [32767, -32768]);
    });
  });

  test('StereoBlock rejects channels of different length', () {
    expect(
      () => StereoBlock(Float64List(2), Float64List(3)),
      throwsArgumentError,
    );
  });
}

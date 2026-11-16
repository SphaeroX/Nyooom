import 'dart:typed_data';

/// Two time-aligned audio channels, normalized to full scale [-1, 1].
class StereoBlock {
  StereoBlock(this.left, this.right) {
    if (left.length != right.length) {
      throw ArgumentError(
        'Channels differ in length: ${left.length} vs ${right.length}',
      );
    }
  }

  final Float64List left;
  final Float64List right;

  /// Number of frames (samples per channel).
  int get length => left.length;

  /// The same block with left and right exchanged (channel check, Task_05).
  StereoBlock get swapped => StereoBlock(right, left);
}

const double _pcm16FullScale = 32768.0;

void _checkStereo(int sampleCount) {
  if (sampleCount.isOdd) {
    throw ArgumentError(
      'Interleaved stereo needs an even sample count, '
      'got $sampleCount',
    );
  }
}

/// Splits interleaved 16-bit stereo (L, R, L, R, ...) into two channels.
StereoBlock deinterleavePcm16(Int16List interleaved) {
  _checkStereo(interleaved.length);
  final frames = interleaved.length ~/ 2;
  final left = Float64List(frames);
  final right = Float64List(frames);
  for (var i = 0; i < frames; i++) {
    left[i] = interleaved[2 * i] / _pcm16FullScale;
    right[i] = interleaved[2 * i + 1] / _pcm16FullScale;
  }
  return StereoBlock(left, right);
}

/// Like [deinterleavePcm16], reading little-endian bytes as delivered by
/// Android's `AudioRecord` with `ENCODING_PCM_16BIT`.
StereoBlock deinterleavePcm16Bytes(Uint8List bytes) {
  if (bytes.length % 4 != 0) {
    throw ArgumentError(
      'Byte count ${bytes.length} is not a whole number of '
      '16-bit stereo frames',
    );
  }
  final data = ByteData.sublistView(bytes);
  final frames = bytes.length ~/ 4;
  final left = Float64List(frames);
  final right = Float64List(frames);
  for (var i = 0; i < frames; i++) {
    left[i] = data.getInt16(4 * i, Endian.little) / _pcm16FullScale;
    right[i] = data.getInt16(4 * i + 2, Endian.little) / _pcm16FullScale;
  }
  return StereoBlock(left, right);
}

/// Splits interleaved float stereo into two channels.
StereoBlock deinterleaveFloat32(Float32List interleaved) {
  _checkStereo(interleaved.length);
  final frames = interleaved.length ~/ 2;
  final left = Float64List(frames);
  final right = Float64List(frames);
  for (var i = 0; i < frames; i++) {
    left[i] = interleaved[2 * i];
    right[i] = interleaved[2 * i + 1];
  }
  return StereoBlock(left, right);
}

/// Interleaves [block] into 16-bit samples, clamping to full scale.
Int16List interleavePcm16(StereoBlock block) {
  final out = Int16List(block.length * 2);
  for (var i = 0; i < block.length; i++) {
    out[2 * i] = _toPcm16(block.left[i]);
    out[2 * i + 1] = _toPcm16(block.right[i]);
  }
  return out;
}

int _toPcm16(double value) =>
    (value * _pcm16FullScale).round().clamp(-32768, 32767);

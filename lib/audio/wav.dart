import 'dart:io';
import 'dart:typed_data';

const int _headerLength = 44;

/// Decoded content of a 16-bit PCM WAV file.
class WavData {
  const WavData({
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.samples,
  });

  final int channels;
  final int sampleRate;
  final int bitsPerSample;

  /// Interleaved samples (L, R, L, R, ... for stereo).
  final Int16List samples;

  int get frameCount => samples.length ~/ channels;
}

Uint8List _header({
  required int channels,
  required int sampleRate,
  required int dataLength,
}) {
  const bitsPerSample = 16;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final bytes = Uint8List(_headerLength);
  final h = ByteData.sublistView(bytes);
  void ascii(int offset, String s) => bytes.setAll(offset, s.codeUnits);
  ascii(0, 'RIFF');
  h.setUint32(4, 36 + dataLength, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  h.setUint32(16, 16, Endian.little);
  h.setUint16(20, 1, Endian.little); // PCM
  h.setUint16(22, channels, Endian.little);
  h.setUint32(24, sampleRate, Endian.little);
  h.setUint32(28, sampleRate * blockAlign, Endian.little);
  h.setUint16(32, blockAlign, Endian.little);
  h.setUint16(34, bitsPerSample, Endian.little);
  ascii(36, 'data');
  h.setUint32(40, dataLength, Endian.little);
  return bytes;
}

/// Encodes interleaved 16-bit samples as a complete WAV file.
Uint8List encodeWavPcm16(
  Int16List interleaved, {
  required int channels,
  required int sampleRate,
}) {
  final dataLength = interleaved.length * 2;
  final out = Uint8List(_headerLength + dataLength);
  out.setAll(
    0,
    _header(channels: channels, sampleRate: sampleRate, dataLength: dataLength),
  );
  final data = ByteData.sublistView(out, _headerLength);
  for (var i = 0; i < interleaved.length; i++) {
    data.setInt16(2 * i, interleaved[i], Endian.little);
  }
  return out;
}

/// Decodes a 16-bit PCM WAV file, skipping chunks other than `fmt ` and
/// `data`.
WavData decodeWav(Uint8List bytes) {
  String tag(int offset) =>
      String.fromCharCodes(bytes.sublist(offset, offset + 4));
  if (bytes.length < 12 || tag(0) != 'RIFF' || tag(8) != 'WAVE') {
    throw const FormatException('Not a RIFF/WAVE file');
  }
  final view = ByteData.sublistView(bytes);
  int? channels;
  int? sampleRate;
  int? bitsPerSample;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = tag(offset);
    final size = view.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ') {
      final format = view.getUint16(body, Endian.little);
      channels = view.getUint16(body + 2, Endian.little);
      sampleRate = view.getUint32(body + 4, Endian.little);
      bitsPerSample = view.getUint16(body + 14, Endian.little);
      if (format != 1 || bitsPerSample != 16) {
        throw FormatException(
          'Only 16-bit PCM is supported (format $format, $bitsPerSample bit)',
        );
      }
    } else if (id == 'data') {
      if (channels == null || sampleRate == null) {
        throw const FormatException('data chunk before fmt chunk');
      }
      final length = (size).clamp(0, bytes.length - body);
      final samples = Int16List(length ~/ 2);
      for (var i = 0; i < samples.length; i++) {
        samples[i] = view.getInt16(body + 2 * i, Endian.little);
      }
      return WavData(
        channels: channels,
        sampleRate: sampleRate,
        bitsPerSample: bitsPerSample!,
        samples: samples,
      );
    }
    offset = body + size + (size.isOdd ? 1 : 0);
  }
  throw const FormatException('No data chunk found');
}

/// Streams 16-bit PCM blocks into a WAV file; the header is completed on
/// [close].
class WavFileWriter {
  WavFileWriter._(this._file, this.channels, this.sampleRate);

  final RandomAccessFile _file;
  final int channels;
  final int sampleRate;
  int _dataLength = 0;

  static Future<WavFileWriter> open(
    File file, {
    required int channels,
    required int sampleRate,
  }) async {
    final raf = await file.open(mode: FileMode.write);
    await raf.writeFrom(
      _header(channels: channels, sampleRate: sampleRate, dataLength: 0),
    );
    return WavFileWriter._(raf, channels, sampleRate);
  }

  int get _frameBytes => channels * 2;

  int get frameCount => _dataLength ~/ _frameBytes;

  /// Appends interleaved little-endian 16-bit samples.
  Future<void> addPcm16Bytes(Uint8List bytes) async {
    if (bytes.length % _frameBytes != 0) {
      throw ArgumentError(
        'Byte count ${bytes.length} is not a whole number '
        'of $channels-channel frames',
      );
    }
    await _file.writeFrom(bytes);
    _dataLength += bytes.length;
  }

  Future<void> close() async {
    await _file.setPosition(0);
    await _file.writeFrom(
      _header(
        channels: channels,
        sampleRate: sampleRate,
        dataLength: _dataLength,
      ),
    );
    await _file.close();
  }
}

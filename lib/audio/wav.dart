import 'dart:io';
import 'dart:typed_data';

import '../core/signal/pcm.dart';

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
/// Header information of a 16-bit PCM WAV file.
class WavInfo {
  const WavInfo({
    required this.channels,
    required this.sampleRate,
    required this.dataOffset,
    required this.dataLength,
  });

  final int channels;
  final int sampleRate;

  /// Byte offset of the first sample.
  final int dataOffset;
  final int dataLength;

  int get frameCount => dataLength ~/ (channels * 2);
  double get durationS => frameCount / sampleRate;
}

/// Reads only the header chunks of [file].
Future<WavInfo> readWavInfo(File file) async {
  final raf = await file.open();
  try {
    final length = await raf.length();
    final head = await raf.read(12);
    if (head.length < 12 ||
        String.fromCharCodes(head.sublist(0, 4)) != 'RIFF' ||
        String.fromCharCodes(head.sublist(8, 12)) != 'WAVE') {
      throw const FormatException('Not a RIFF/WAVE file');
    }
    int? channels, sampleRate;
    var offset = 12;
    while (offset + 8 <= length) {
      await raf.setPosition(offset);
      final chunk = await raf.read(8);
      final id = String.fromCharCodes(chunk.sublist(0, 4));
      final size = ByteData.sublistView(chunk).getUint32(4, Endian.little);
      if (id == 'fmt ') {
        final fmt = ByteData.sublistView(await raf.read(16));
        if (fmt.getUint16(0, Endian.little) != 1 ||
            fmt.getUint16(14, Endian.little) != 16) {
          throw const FormatException('Only 16-bit PCM is supported');
        }
        channels = fmt.getUint16(2, Endian.little);
        sampleRate = fmt.getUint32(4, Endian.little);
      } else if (id == 'data') {
        if (channels == null || sampleRate == null) {
          throw const FormatException('data chunk before fmt chunk');
        }
        final available = length - offset - 8;
        return WavInfo(
          channels: channels,
          sampleRate: sampleRate,
          dataOffset: offset + 8,
          dataLength: size < available ? size : available,
        );
      }
      offset += 8 + size + (size.isOdd ? 1 : 0);
    }
    throw const FormatException('No data chunk found');
  } finally {
    await raf.close();
  }
}

/// Reads [durationS] seconds from [startS] of a stereo WAV file (clipped to
/// the file), without loading the rest.
Future<StereoBlock> readWavStereoRange(
  File file, {
  required double startS,
  required double durationS,
}) async {
  final info = await readWavInfo(file);
  if (info.channels != 2) throw const FormatException('Stereo WAV expected');
  final first = (startS * info.sampleRate).round().clamp(0, info.frameCount);
  final count = ((durationS * info.sampleRate).round()).clamp(
    0,
    info.frameCount - first,
  );
  final raf = await file.open();
  try {
    await raf.setPosition(info.dataOffset + first * 4);
    final bytes = await raf.read(count * 4);
    return deinterleavePcm16Bytes(bytes);
  } finally {
    await raf.close();
  }
}

class WavFileWriter {
  WavFileWriter._(
    this._file,
    this.channels,
    this.sampleRate, [
    this._dataLength = 0,
  ]);

  final RandomAccessFile _file;
  final int channels;
  final int sampleRate;
  int _dataLength;

  /// Continues a WAV written by [WavFileWriter] (a stopped measurement
  /// series). Everything after the header counts as data, so a file whose
  /// header was never finalised (app killed while recording) is kept too.
  static Future<WavFileWriter> append(File file) async {
    final info = await readWavInfo(file);
    if (info.dataOffset != 44) {
      throw const FormatException(
        'Only WAV files of this app can be continued',
      );
    }
    final frameBytes = info.channels * 2;
    final raf = await file.open(mode: FileMode.append);
    final available = await raf.length() - info.dataOffset;
    final length = available - available % frameBytes;
    await raf.truncate(info.dataOffset + length);
    await raf.setPosition(info.dataOffset + length);
    return WavFileWriter._(raf, info.channels, info.sampleRate, length);
  }

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

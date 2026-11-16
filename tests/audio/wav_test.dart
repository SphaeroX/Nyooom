import 'dart:io';
import 'dart:typed_data';

import 'package:nyooom/audio/wav.dart';
import 'package:test/test.dart';

String _ascii(Uint8List bytes, int offset) =>
    String.fromCharCodes(bytes.sublist(offset, offset + 4));

void main() {
  final samples = Int16List.fromList([
    0,
    1,
    -1,
    32767,
    -32768,
    1234,
    4321,
    -4321,
  ]);

  group('encodeWavPcm16', () {
    test('writes a canonical 44-byte PCM header', () {
      final bytes = encodeWavPcm16(samples, channels: 2, sampleRate: 48000);
      final header = ByteData.sublistView(bytes);
      expect(bytes.length, 44 + samples.length * 2);
      expect(_ascii(bytes, 0), 'RIFF');
      expect(header.getUint32(4, Endian.little), bytes.length - 8);
      expect(_ascii(bytes, 8), 'WAVE');
      expect(_ascii(bytes, 12), 'fmt ');
      expect(header.getUint32(16, Endian.little), 16);
      expect(header.getUint16(20, Endian.little), 1); // PCM
      expect(header.getUint16(22, Endian.little), 2); // channels
      expect(header.getUint32(24, Endian.little), 48000); // sample rate
      expect(header.getUint32(28, Endian.little), 48000 * 2 * 2); // byte rate
      expect(header.getUint16(32, Endian.little), 4); // block align
      expect(header.getUint16(34, Endian.little), 16); // bits per sample
      expect(_ascii(bytes, 36), 'data');
      expect(header.getUint32(40, Endian.little), samples.length * 2);
    });
  });

  group('decodeWav', () {
    test('reads back exactly what was written', () {
      final wav = decodeWav(
        encodeWavPcm16(samples, channels: 2, sampleRate: 48000),
      );
      expect(wav.channels, 2);
      expect(wav.sampleRate, 48000);
      expect(wav.bitsPerSample, 16);
      expect(wav.frameCount, samples.length ~/ 2);
      expect(wav.samples, samples);
    });

    test('skips unknown chunks before the data chunk', () {
      final plain = encodeWavPcm16(samples, channels: 2, sampleRate: 48000);
      final listChunk = [...'LIST'.codeUnits, 4, 0, 0, 0, 1, 2, 3, 4];
      final withExtra = Uint8List.fromList([
        ...plain.sublist(0, 36),
        ...listChunk,
        ...plain.sublist(36),
      ]);
      ByteData.sublistView(withExtra)
          .setUint32(4, withExtra.length - 8, Endian.little);
      expect(decodeWav(withExtra).samples, samples);
    });

    test('rejects data that is not a RIFF/WAVE file', () {
      expect(() => decodeWav(Uint8List(44)), throwsFormatException);
    });

    test('rejects formats other than 16-bit PCM', () {
      final bytes = encodeWavPcm16(samples, channels: 2, sampleRate: 48000);
      ByteData.sublistView(bytes).setUint16(34, 24, Endian.little);
      expect(() => decodeWav(bytes), throwsFormatException);
    });
  });

  group('WavFileWriter', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('nyooom_wav_test');
    });

    tearDown(() async {
      await dir.delete(recursive: true);
    });

    test('streams PCM blocks into a valid stereo WAV file', () async {
      final file = File('${dir.path}/rec.wav');
      final writer = await WavFileWriter.open(
        file,
        channels: 2,
        sampleRate: 48000,
      );
      final bytes = samples.buffer.asUint8List();
      await writer.addPcm16Bytes(bytes.sublist(0, 8));
      await writer.addPcm16Bytes(bytes.sublist(8));
      expect(writer.frameCount, samples.length ~/ 2);
      await writer.close();

      final wav = decodeWav(await file.readAsBytes());
      expect(wav.channels, 2);
      expect(wav.sampleRate, 48000);
      expect(wav.bitsPerSample, 16);
      expect(wav.samples, samples);
    });

    test('rejects blocks that are not whole frames', () async {
      final writer = await WavFileWriter.open(
        File('${dir.path}/bad.wav'),
        channels: 2,
        sampleRate: 48000,
      );
      expect(() => writer.addPcm16Bytes(Uint8List(3)), throwsArgumentError);
      await writer.close();
    });
  });
}

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/wav.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('wav_range'));
  tearDown(() => dir.delete(recursive: true));

  test(
    'reads header info and an excerpt without loading the whole file',
    () async {
      final frames = 48000 * 2;
      final samples = Int16List(frames * 2);
      for (var i = 0; i < frames; i++) {
        samples[2 * i] = i % 30000;
        samples[2 * i + 1] = -(i % 20000);
      }
      final file = File('${dir.path}/a.wav');
      await file.writeAsBytes(
        encodeWavPcm16(samples, channels: 2, sampleRate: 48000),
      );
      final info = await readWavInfo(file);
      expect(info.channels, 2);
      expect(info.sampleRate, 48000);
      expect(info.frameCount, frames);
      expect(info.durationS, 2);

      final block = await readWavStereoRange(
        file,
        startS: 0.5,
        durationS: 0.25,
      );
      expect(block.length, 12000);
      expect(block.left[0], 24000 / 32768);
      expect(block.right[0], -(24000 % 20000) / 32768);

      final tail = await readWavStereoRange(file, startS: 1.9, durationS: 1);
      expect(tail.length, 4800); // clipped at the end of the file
    },
  );
}

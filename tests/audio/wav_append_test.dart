import 'dart:io';
import 'dart:typed_data';

import 'package:nyooom/audio/wav.dart';
import 'package:test/test.dart';

void main() {
  test('a closed WAV can be continued', () async {
    final dir = await Directory.systemTemp.createTemp('nyooom_wav_append');
    final file = File('${dir.path}/a.wav');
    final first = Uint8List.fromList([1, 0, 2, 0, 3, 0, 4, 0]);
    final second = Uint8List.fromList([5, 0, 6, 0]);
    var writer = await WavFileWriter.open(file, channels: 2, sampleRate: 48000);
    await writer.addPcm16Bytes(first);
    await writer.close();

    writer = await WavFileWriter.append(file);
    expect(writer.frameCount, 2);
    expect(writer.channels, 2);
    expect(writer.sampleRate, 48000);
    await writer.addPcm16Bytes(second);
    expect(writer.frameCount, 3);
    await writer.close();

    final wav = decodeWav(await file.readAsBytes());
    expect(wav.samples.buffer.asUint8List(), [...first, ...second]);
    await dir.delete(recursive: true);
  });
}

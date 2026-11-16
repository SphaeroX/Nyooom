import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/simulated_stereo_recorder.dart';
import 'package:nyooom/audio/stereo_recorder.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/passby_simulator.dart';
import 'package:nyooom/core/sim/traffic.dart';

void main() {
  const lanes = [TrafficLane(slantDistance: 4.1, direction: 1)];

  test('reports a simulated device and source', () async {
    final rec = SimulatedStereoRecorder(lanes: lanes, realTime: false);
    expect((await rec.capabilities()).deviceModel, 'Simulation');
    final info = await rec.start(sampleRate: 48000);
    expect(info.audioSource, AudioSourceKind.simulated);
    expect(info.channels, 2);
    await rec.stop();
  });

  test(
    'streams the rendered traffic as continuous 16-bit PCM blocks',
    () async {
      final rec = SimulatedStereoRecorder(
        lanes: lanes,
        seed: 3,
        realTime: false,
        chunkS: 0.5,
      );
      final bytes = BytesBuilder();
      final sub = rec.pcmBlocks.listen(bytes.add);
      await rec.start(sampleRate: 48000);
      while (bytes.length < 48000 * 4 * 1.2) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      await rec.stop();
      await sub.cancel();

      final got = deinterleavePcm16Bytes(
        Uint8List.sublistView(bytes.toBytes(), 0, 48000 * 4),
      );
      final expected = PassBySimulator(rec.setup)
          .render(1, rec.traffic.passesAffecting(0, 1));
      for (var i = 0; i < 48000; i += 7) {
        expect(got.left[i], closeTo(expected.signal.left[i], 2 / 32768));
        expect(got.right[i], closeTo(expected.signal.right[i], 2 / 32768));
      }
    },
  );
}

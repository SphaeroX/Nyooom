import 'dart:typed_data';

import 'package:nyooom/core/collect/clip_collector.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/events/event_detector.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

SimulatedRecording render(double durationS, List<VehiclePass> passes) =>
    PassBySimulator(Scenarios.setup(backgroundRms: 0.002))
        .render(durationS, passes);

/// Feeds [signal] in blocks of [blockFrames] like the live recorder.
List<CollectedClip> collect(StereoBlock signal, {int blockFrames = 4800}) {
  final collector = ClipCollector(config: config);
  final clips = <CollectedClip>[];
  for (var i = 0; i < signal.length; i += blockFrames) {
    final end = i + blockFrames > signal.length
        ? signal.length
        : i + blockFrames;
    clips.addAll(
      collector.add(
        StereoBlock(
          Float64List.sublistView(signal.left, i, end),
          Float64List.sublistView(signal.right, i, end),
        ),
      ),
    );
  }
  clips.addAll(collector.finish());
  return clips;
}

void main() {
  test('one clip per detected pass, cut around the level maximum', () {
    final rec = render(40, [
      Scenarios.combustion(speedKmh: 40, distance: 4.1, t0: 10),
      Scenarios.electric(speedKmh: 30, distance: 4.1, t0: 28),
    ]);
    final events = detectEvents(rec.signal, config: config);
    final clips = collect(rec.signal);

    expect(clips, hasLength(events.length));
    expect(clips, hasLength(2));
    for (var i = 0; i < clips.length; i++) {
      final clip = clips[i];
      expect(clip.event.peakTimeS, closeTo(events[i].peakTimeS, 1e-9));
      expect(clip.startS, closeTo(events[i].windowStartS, 1e-3));
      final expectedFrames =
          ((events[i].windowEndS - events[i].windowStartS) * config.sampleRate)
              .round();
      expect(clip.signal.length, closeTo(expectedFrames, 1));
      final first = (clip.startS * config.sampleRate).round();
      for (final k in [0, clip.signal.length ~/ 2, clip.signal.length - 1]) {
        expect(clip.signal.left[k], rec.signal.left[first + k]);
        expect(clip.signal.right[k], rec.signal.right[first + k]);
      }
    }
  });

  test('silence gives no clip', () {
    final rec = render(20, const []);
    expect(collect(rec.signal), isEmpty);
  });

  test('block size does not change the clips', () {
    final rec = render(30, [
      Scenarios.combustion(speedKmh: 50, distance: 4.1, t0: 12),
    ]);
    final a = collect(rec.signal, blockFrames: 1024);
    final b = collect(rec.signal, blockFrames: 48000);
    expect(a, hasLength(1));
    expect(b, hasLength(1));
    expect(a.single.startS, closeTo(b.single.startS, 1e-9));
    expect(a.single.signal.length, b.single.signal.length);
  });

  test('only the last few windows of audio are kept', () {
    final collector = ClipCollector(config: config);
    final second = StereoBlock(
      Float64List(config.sampleRate),
      Float64List(config.sampleRate),
    );
    for (var i = 0; i < 120; i++) {
      collector.add(second);
    }
    expect(collector.bufferedS, lessThanOrEqualTo(collector.keptS + 1));
  });
}

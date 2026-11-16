import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/events/event_detector.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

VehiclePass withSpan(VehiclePass p) => VehiclePass(
  kind: p.kind,
  speed: p.speed,
  distance: p.distance,
  t0: p.t0,
  noiseRms: p.noiseRms,
  tones: p.tones,
  noiseSeed: p.t0.round(),
  audibleSpanS: 9,
);

SimulatedRecording render(double durationS, List<VehiclePass> passes) =>
    PassBySimulator(Scenarios.setup(backgroundRms: 0.002))
        .render(durationS, [for (final p in passes) withSpan(p)]);

void main() {
  test('three passes 10 s apart give exactly three events near t0', () {
    final rec = render(32, [
      Scenarios.combustion(speedKmh: 30, distance: 5, t0: 6),
      Scenarios.electric(speedKmh: 45, distance: 4, t0: 16, direction: -1),
      Scenarios.combustion(speedKmh: 50, distance: 7, t0: 26),
    ]);
    final events = detectEvents(rec.signal, config: config);
    expect(events, hasLength(3));
    for (var i = 0; i < 3; i++) {
      expect(events[i].peakTimeS, closeTo(rec.truths[i].receptionT0, 0.2));
      expect(events[i].overlap, isFalse);
      expect(events[i].levelAboveFloorDb, greaterThan(10));
      expect(events[i].durationS, greaterThan(0.2));
      expect(events[i].windowStartS, closeTo(events[i].peakTimeS - 4, 1e-9));
      expect(events[i].windowEndS, closeTo(events[i].peakTimeS + 4, 1e-9));
    }
  });

  test('two vehicles 1 s apart with similar level are one overlap event', () {
    final rec = render(16, [
      Scenarios.combustion(speedKmh: 50, distance: 4, t0: 7.5),
      Scenarios.combustion(speedKmh: 50, distance: 4, t0: 8.5, direction: -1),
    ]);
    final events = detectEvents(rec.signal, config: config);
    expect(events, hasLength(1));
    expect(events.single.overlap, isTrue);
  });

  test('a quiet vehicle less than 10 dB above the floor gives no event', () {
    final rec = render(14, [
      Scenarios.electric(speedKmh: 30, distance: 8, t0: 7, noiseRms: 0.0035),
    ]);
    expect(detectEvents(rec.signal, config: config), isEmpty);
  });

  test('streaming in random blocks gives the same events as the file mode', () {
    final rec = render(24, [
      Scenarios.combustion(speedKmh: 30, distance: 5, t0: 6),
      Scenarios.electric(speedKmh: 40, distance: 4, t0: 16),
    ]);
    final whole = detectEvents(rec.signal, config: config);
    final detector = EventDetector(config: config);
    final random = math.Random(4);
    final streamed = <PassEvent>[];
    var i = 0;
    while (i < rec.signal.length) {
      final n = math.min(rec.signal.length - i, 100 + random.nextInt(9000));
      streamed.addAll(
        detector.add(
          StereoBlock(
            Float64List.sublistView(rec.signal.left, i, i + n),
            Float64List.sublistView(rec.signal.right, i, i + n),
          ),
        ),
      );
      i += n;
    }
    streamed.addAll(detector.finish());
    expect(streamed.map((e) => e.peakTimeS), whole.map((e) => e.peakTimeS));
    expect(
      streamed.map((e) => e.levelAboveFloorDb),
      whole.map((e) => e.levelAboveFloorDb),
    );
  });

  test('an event near the end is reported with a truncated window', () {
    final rec = render(10, [
      Scenarios.combustion(speedKmh: 40, distance: 5, t0: 8.5),
    ]);
    final events = detectEvents(rec.signal, config: config);
    expect(events, hasLength(1));
    expect(events.single.truncated, isTrue);
    expect(events.single.windowEndS, closeTo(10, 0.06));
  });

  test('an event near the start keeps its window inside the recording', () {
    final rec = render(10, [
      Scenarios.combustion(speedKmh: 40, distance: 5, t0: 1.5),
    ]);
    final events = detectEvents(rec.signal, config: config);
    expect(events, hasLength(1));
    expect(events.single.windowStartS, 0);
    expect(events.single.truncated, isTrue);
  });
}

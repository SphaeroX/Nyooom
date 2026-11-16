import 'dart:math' as math;
import 'dart:typed_data';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/events/event_detector.dart';
import 'package:nyooom/core/signal/pcm.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

const config = NyooomConfig();

VehiclePass withSpan(VehiclePass p, int seed) => VehiclePass(
  kind: p.kind,
  speed: p.speed,
  distance: p.distance,
  t0: p.t0,
  noiseRms: p.noiseRms,
  tones: p.tones,
  noiseSeed: seed,
  audibleSpanS: 9,
);

SimulatedRecording render(double durationS, List<VehiclePass> passes) =>
    PassBySimulator(Scenarios.setup(backgroundRms: 0.002)).render(durationS, [
      for (var i = 0; i < passes.length; i++) withSpan(passes[i], i + 1),
    ]);

List<PassEvent> detectAll(StereoBlock signal) {
  final detector = EventDetector(config: config, secondaryEvents: true);
  return [...detector.add(signal), ...detector.finish()];
}

void main() {
  test('two vehicles 2 s apart give two events in secondary mode', () {
    final rec = render(20, [
      Scenarios.combustion(speedKmh: 30, distance: 4.1, t0: 8),
      Scenarios.electric(speedKmh: 32, distance: 4.1, t0: 10),
    ]);
    // The literal rule of technik.pdf 5.1 keeps one (dominant) event.
    expect(detectEvents(rec.signal, config: config), hasLength(1));

    final events = detectAll(rec.signal);
    expect(events, hasLength(2));
    events.sort((a, b) => a.peakTimeS.compareTo(b.peakTimeS));
    for (var i = 0; i < 2; i++) {
      expect(events[i].peakTimeS, closeTo(rec.truths[i].receptionT0, 0.25));
      expect(events[i].overlap, isTrue);
      expect(events[i].neighbourPeakTimesS, hasLength(1));
      expect(
        events[i].neighbourPeakTimesS.single,
        closeTo(events[1 - i].peakTimeS, 1e-9),
      );
    }
    // Exactly one of the two is the dominant maximum of its window.
    expect(events.where((e) => e.secondary), hasLength(1));
  });

  test('a platoon of four vehicles gives four events', () {
    final rec = render(26, [
      for (var i = 0; i < 4; i++)
        Scenarios.electric(
          speedKmh: 40,
          distance: 4.1,
          t0: 8 + 2.5 * i,
          noiseRms: [0.1, 0.09, 0.12, 0.08][i],
        ),
    ]);
    final events = detectAll(rec.signal)
      ..sort((a, b) => a.peakTimeS.compareTo(b.peakTimeS));
    expect(events, hasLength(4));
    for (var i = 0; i < 4; i++) {
      expect(events[i].peakTimeS, closeTo(rec.truths[i].receptionT0, 0.25));
    }
  });

  test('single vehicles give the same events in both modes', () {
    final rec = render(24, [
      Scenarios.combustion(speedKmh: 30, distance: 5, t0: 6),
      Scenarios.electric(speedKmh: 45, distance: 4, t0: 17, direction: -1),
    ]);
    final literal = detectEvents(rec.signal, config: config);
    final extended = detectAll(rec.signal);
    expect(extended, hasLength(2));
    expect(extended.map((e) => e.peakTimeS), literal.map((e) => e.peakTimeS));
    expect(extended.every((e) => !e.secondary && !e.overlap), isTrue);
    expect(extended.every((e) => e.neighbourPeakTimesS.isEmpty), isTrue);
  });

  test('streaming in random blocks equals the file mode (secondary)', () {
    final rec = render(22, [
      Scenarios.combustion(speedKmh: 50, distance: 4.1, t0: 7),
      Scenarios.combustion(speedKmh: 45, distance: 4.1, t0: 9.5),
      Scenarios.electric(speedKmh: 40, distance: 7.3, t0: 12.5, direction: -1),
    ]);
    final whole = detectAll(rec.signal);
    final detector = EventDetector(config: config, secondaryEvents: true);
    final random = math.Random(5);
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
    expect(whole, hasLength(3));
    expect(streamed.map((e) => e.peakTimeS), whole.map((e) => e.peakTimeS));
    expect(streamed.map((e) => e.secondary), whole.map((e) => e.secondary));
  });
}

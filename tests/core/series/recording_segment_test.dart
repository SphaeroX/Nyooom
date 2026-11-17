import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/core/series/recording_segment.dart';
import 'package:test/test.dart';

void main() {
  const segments = [
    RecordingSegment(offsetS: 0, startedAtUtcMs: 1000),
    RecordingSegment(offsetS: 10, startedAtUtcMs: 100000),
  ];

  AnalysisSetup setup({List<RecordingSegment>? segments}) => AnalysisSetup(
    micSpacing: 0.15,
    channelOffset: 0,
    swapChannels: false,
    speedOfSound: 343,
    speedLimitKmh: 50,
    startedAtUtcMs: 1000,
    lanes: const [LaneGeometry(index: 0, direction: 1, slantDistance: 4)],
    segments: segments,
  );

  test('without segments the time follows the start', () {
    expect(setup().utcMsAt(5), 6000);
  });

  test('after a pause the time follows the resumed segment', () {
    final s = setup(segments: segments);
    expect(s.utcMsAt(5), 6000);
    expect(s.utcMsAt(9.999), 10999);
    expect(s.utcMsAt(12), 102000);
  });

  test('recorded duration leaves out the pause', () {
    expect(recordedDurationS(segments, endedAtUtcMs: 105000), 15);
    expect(recordedDurationS(segments, endedAtUtcMs: null), isNull);
  });

  test('segments survive JSON', () {
    final json = segmentsToJson(segments);
    final back = segmentsFromJson(json);
    expect(back, segments);
    expect(segmentsFromJson(null), isEmpty);
  });
}

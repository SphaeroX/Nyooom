import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/ui/series/series_recording_controller.dart';
import 'package:nyooom/ui/series/series_screens.dart';

class _StoppedController extends SeriesRecordingController {
  int? resumed;

  @override
  SeriesRecordingState build() =>
      const SeriesRecordingState(seriesId: 5, elapsedS: 12);

  @override
  Future<void> start(SeriesStartRequest request) async {}

  @override
  Future<void> resume(int seriesId) async {
    resumed = seriesId;
    state = const SeriesRecordingState(running: true, seriesId: 5);
  }
}

void main() {
  testWidgets('a stopped series offers to continue recording', (tester) async {
    final controller = _StoppedController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesRecordingProvider.overrideWith(() => controller),
          recordingExtrasProvider.overrideWithValue(null),
        ],
        child: const MaterialApp(
          home: SeriesRecordingScreen(
            request: SeriesStartRequest(siteId: 1, temperatureC: 15),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Fertig'), findsOneWidget);
    await tester.tap(find.byKey(const Key('resume-series')));
    await tester.pump();
    expect(controller.resumed, 5);
    expect(find.byKey(const Key('stop-series')), findsOneWidget);
  });
}

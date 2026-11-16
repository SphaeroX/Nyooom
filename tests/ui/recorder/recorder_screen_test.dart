import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/audio/stereo_recorder.dart';
import 'package:nyooom/ui/recorder/recorder_controller.dart';
import 'package:nyooom/ui/recorder/recorder_screen.dart';

import '../../helpers/fake_stereo_recorder.dart';

Widget app(FakeStereoRecorder recorder) => ProviderScope(
  overrides: [
    stereoRecorderProvider.overrideWithValue(recorder),
    recordingsDirectoryProvider.overrideWith(
      (ref) async => Directory.systemTemp,
    ),
  ],
  child: const MaterialApp(home: RecorderScreen()),
);

void main() {
  testWidgets('shows source, effects and two independent levels', (
    tester,
  ) async {
    final recorder = FakeStereoRecorder();
    await tester.pumpWidget(app(recorder));
    await tester.pump();
    expect(find.textContaining('Fake Phone'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.textContaining('UNPROCESSED'), findsOneWidget);
    expect(find.textContaining('AGC: aus'), findsOneWidget);

    recorder.emit(sinePcm16(leftAmplitude: 0.5, rightAmplitude: 0.05));
    await tester.pump();
    expect(find.textContaining('-9.0 dBFS'), findsOneWidget);
    expect(find.textContaining('-29.0 dBFS'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
  });

  testWidgets('warns about clipping', (tester) async {
    final recorder = FakeStereoRecorder();
    await tester.pumpWidget(app(recorder));
    await tester.tap(find.text('Start'));
    await tester.pump();
    recorder.emit(sinePcm16(leftAmplitude: 0.95, rightAmplitude: 0.1));
    await tester.pump();
    expect(find.textContaining('Übersteuerung'), findsOneWidget);
  });

  testWidgets('shows a hint when the permission is missing', (tester) async {
    final recorder = FakeStereoRecorder(
      startError: const MicrophonePermissionDeniedException('denied'),
    );
    await tester.pumpWidget(app(recorder));
    await tester.tap(find.text('Start'));
    await tester.pump();
    expect(find.textContaining('Berechtigung'), findsOneWidget);
  });
}

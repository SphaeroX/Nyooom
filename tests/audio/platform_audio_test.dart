import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/clip_player.dart';
import 'package:nyooom/audio/desktop_stereo_recorder.dart';
import 'package:nyooom/audio/platform_audio.dart';
import 'package:nyooom/audio/stereo_recorder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Android records through the Kotlin plugin', () {
    final r = stereoRecorderFor(android: true);
    expect(r, isA<StereoRecorder>());
    expect(r, isNot(isA<DesktopStereoRecorder>()));
  });

  test('the PC records through the desktop recorder', () {
    expect(stereoRecorderFor(android: false), isA<DesktopStereoRecorder>());
  });

  test('Android plays clips through the Kotlin plugin, the PC not', () {
    expect(clipPlayerFor(android: true), isA<PlatformClipPlayer>());
    expect(clipPlayerFor(android: false), isA<AudioplayersClipPlayer>());
  });
}

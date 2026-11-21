import 'clip_player.dart';
import 'desktop_stereo_recorder.dart';
import 'stereo_recorder.dart';

/// Recorder of the platform: the Kotlin plugin on Android, the `record`
/// package elsewhere (Windows).
StereoRecorder stereoRecorderFor({required bool android}) =>
    android ? StereoRecorder() : DesktopStereoRecorder();

/// Clip playback of the platform: the Kotlin plugin on Android,
/// `audioplayers` elsewhere.
ClipPlayer clipPlayerFor({required bool android}) =>
    android ? PlatformClipPlayer() : AudioplayersClipPlayer();

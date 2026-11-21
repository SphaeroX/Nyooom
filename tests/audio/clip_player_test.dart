import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/clip_player.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(PlatformClipPlayer.channelName);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late List<MethodCall> calls;

  setUp(() {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('plays a file through the audio plugin', () async {
    await PlatformClipPlayer().play('/data/clip_001.wav');
    expect(calls.single.method, 'playFile');
    expect(calls.single.arguments, {'path': '/data/clip_001.wav'});
  });

  test('stops playback', () async {
    await PlatformClipPlayer().stop();
    expect(calls.single.method, 'stopPlayback');
  });

  test('the platform reports the end of playback', () async {
    final player = PlatformClipPlayer();
    final done = player.completions.first;
    await messenger.handlePlatformMessage(
      PlatformClipPlayer.channelName,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall(PlatformClipPlayer.completedMethod),
      ),
      (_) {},
    );
    await done;
  });
}

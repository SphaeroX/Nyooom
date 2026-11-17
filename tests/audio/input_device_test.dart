import 'package:nyooom/audio/stereo_recorder.dart';
import 'package:test/test.dart';

void main() {
  test('recording info reports the preferred (USB) device', () {
    final info = RecordingInfo.fromMap({
      'audioSource': 'UNPROCESSED',
      'sampleRate': 48000,
      'channels': 2,
      'effects': <String, String>{},
      'preferredDevice': 'USB Stereo Mic',
    });
    expect(info.preferredDevice, 'USB Stereo Mic');
    expect(
      RecordingInfo.fromMap({'preferredDevice': ''}).preferredDevice,
      isNull,
    );
  });

  test('input devices read their channel counts', () {
    final d = InputDevice.fromMap({
      'id': 7,
      'name': 'USB Stereo Mic',
      'type': 11,
      'isExternal': true,
      'channelCounts': [1, 2],
    });
    expect(d.channelCounts, [1, 2]);
    expect(d.supportsStereo, isTrue);
  });
}

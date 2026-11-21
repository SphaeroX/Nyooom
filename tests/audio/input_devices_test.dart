import 'package:flutter_test/flutter_test.dart';
import 'package:nyooom/audio/input_devices.dart';
import 'package:nyooom/audio/stereo_recorder.dart';

// Android AudioDeviceInfo.TYPE_* values.
const builtinMic = 15;
const usbDevice = 11;
const usbHeadset = 22;
const telephony = 18;
const remoteSubmix = 25;
const bluetoothSco = 7;

InputDevice device(
  int id,
  String name,
  int type, {
  bool external = false,
  List<int> channelCounts = const [],
}) => InputDevice(
  id: id,
  name: name,
  type: type,
  isExternal: external,
  channelCounts: channelCounts,
);

void main() {
  group('selectableInputDevices', () {
    test('hides the built-in microphones and system sources', () {
      final list = selectableInputDevices([
        device(1, 'Pixel', builtinMic),
        device(2, 'Pixel', builtinMic),
        device(3, 'Telefon', telephony),
        device(4, 'Submix', remoteSubmix),
        device(9, 'USB Audio', usbDevice, external: true),
      ]);
      expect(list.map((d) => d.id), [9]);
    });

    test('lists external devices first, then by name', () {
      final list = selectableInputDevices([
        device(5, 'Kopfhörer', bluetoothSco),
        device(9, 'Zoom H1', usbDevice, external: true),
        device(7, 'Behringer', usbHeadset, external: true),
      ]);
      expect(list.map((d) => d.id), [7, 9, 5]);
    });
  });

  group('InputDevice', () {
    test('names the connection type', () {
      expect(device(1, 'a', usbDevice).typeLabel, 'USB');
      expect(device(1, 'a', usbHeadset).typeLabel, 'USB-Headset');
      expect(device(1, 'a', bluetoothSco).typeLabel, 'Bluetooth');
      expect(device(1, 'a', 99).typeLabel, 'Typ 99');
    });

    test('stereo support follows the channel counts, unknown when empty', () {
      expect(device(1, 'a', usbDevice, channelCounts: [1, 2]).stereo, isTrue);
      expect(device(1, 'a', usbDevice, channelCounts: [1]).stereo, isFalse);
      expect(device(1, 'a', usbDevice).stereo, isNull);
    });
  });

  group('calibrationInputName', () {
    test('internal microphones without a selection', () {
      expect(calibrationInputName(null), 'intern');
    });

    test('the product name of a selected device', () {
      expect(
        calibrationInputName(device(9, 'USB Audio', usbDevice)),
        'USB Audio',
      );
    });
  });

  group('reconcileSelection', () {
    test('keeps a device that is still connected', () {
      final usb = device(9, 'USB Audio', usbDevice);
      expect(reconcileSelection(usb, [usb])!.id, 9);
    });

    test('follows a device that came back with a new id', () {
      final before = device(9, 'USB Audio', usbDevice);
      final after = device(14, 'USB Audio', usbDevice);
      expect(reconcileSelection(before, [after])!.id, 14);
    });

    test('falls back to the internal microphones when unplugged', () {
      final usb = device(9, 'USB Audio', usbDevice);
      expect(reconcileSelection(usb, const []), isNull);
      expect(reconcileSelection(null, [usb]), isNull);
    });
  });

  test('describes what Android reports for the device', () {
    const d = InputDevice(
      id: 9,
      name: 'USB Audio',
      type: usbDevice,
      isExternal: true,
      channelCounts: [1],
      sampleRates: [44100, 48000],
    );
    expect(d.reportedFormat, 'Android meldet: 1 Kanal, 44100/48000 Hz');
    const unknown = InputDevice(
      id: 1,
      name: 'x',
      type: usbDevice,
      isExternal: true,
    );
    expect(unknown.reportedFormat, 'Android meldet: Kanäle unbekannt');
  });
}

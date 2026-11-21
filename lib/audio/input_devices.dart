import 'stereo_recorder.dart';

/// Device types that are no microphone input the user could set up
/// (call audio, internal mixes, tuners).
const _systemSources = {
  AndroidInputType.telephony,
  AndroidInputType.remoteSubmix,
  AndroidInputType.echoReference,
  AndroidInputType.fmTuner,
  AndroidInputType.tvTuner,
};

/// Inputs offered besides the internal microphones: external first, then by
/// name. The built-in microphones are covered by the default choice, so
/// Android keeps its stereo pairing of them.
List<InputDevice> selectableInputDevices(List<InputDevice> devices) {
  final list = [
    for (final d in devices)
      if (d.type != AndroidInputType.builtinMic &&
          !_systemSources.contains(d.type))
        d,
  ];
  list.sort((a, b) {
    if (a.isExternal != b.isExternal) return a.isExternal ? -1 : 1;
    return a.name.compareTo(b.name);
  });
  return list;
}

/// Name under which calibrations of [device] are stored
/// (`Devices.inputDevice`); `intern` for the internal microphones.
String calibrationInputName(InputDevice? device) =>
    device == null ? 'intern' : device.name;

/// The connected device matching the user's [choice]. Android assigns a new
/// id after replugging, so name and type identify the device; null (internal
/// microphones) when it is not connected.
InputDevice? reconcileSelection(
  InputDevice? choice,
  List<InputDevice> devices,
) {
  if (choice == null) return null;
  for (final d in devices) {
    if (d.id == choice.id && d.name == choice.name) return d;
  }
  for (final d in devices) {
    if (d.name == choice.name && d.type == choice.type) return d;
  }
  return null;
}

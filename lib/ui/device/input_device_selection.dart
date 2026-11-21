import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'dart:io';

import '../../audio/input_devices.dart';
import '../../audio/stereo_recorder.dart';
import '../../data/input_choice_store.dart';
import '../providers.dart';

/// Inputs besides the internal microphones (e.g. USB interfaces). Reloads
/// when a device is plugged in or out.
final inputDevicesProvider = FutureProvider<List<InputDevice>>((ref) async {
  final recorder = ref.watch(stereoRecorderProvider);
  final sub = recorder.deviceChanges.listen((_) => ref.invalidateSelf());
  ref.onDispose(() => unawaited(sub.cancel()));
  return selectableInputDevices(await recorder.inputDevices());
});

/// Where the app-wide input choice is kept between app starts. `main`
/// overrides it with [fileInputChoiceStore]; the default keeps it in memory.
final inputChoiceStoreProvider = Provider<InputChoiceStore>(
  (ref) => MemoryInputChoiceStore(),
);

/// The choice as a file in the app documents directory.
InputChoiceStore fileInputChoiceStore(Ref ref) =>
    FileInputChoiceStore(() async {
      final dir = await ref.read(appDirectoryProvider.future);
      return File('${dir.path}${Platform.pathSeparator}input_device.json');
    });

/// The input the user chose in the "Gerät" tab; null means the internal
/// microphones. Applies app-wide (level test, calibration, measurement
/// series) and is restored at app start.
final inputDeviceChoiceProvider =
    NotifierProvider<InputDeviceChoice, InputDevice?>(InputDeviceChoice.new);

class InputDeviceChoice extends Notifier<InputDevice?> {
  bool _chosen = false;
  late Future<void> _ready;

  /// Completes once the stored choice has been read.
  Future<void> get ready => _ready;

  @override
  InputDevice? build() {
    _chosen = false;
    _ready = _restore();
    return null;
  }

  Future<void> _restore() async {
    InputChoice? saved;
    try {
      saved = await ref.read(inputChoiceStoreProvider).load();
    } on Object {
      return;
    }
    if (saved == null || _chosen || !ref.mounted) return;
    state = InputDevice(
      id: saved.id,
      name: saved.name,
      type: saved.type,
      isExternal: saved.isExternal,
    );
  }

  void choose(InputDevice? device) {
    _chosen = true;
    state = device;
    final store = ref.read(inputChoiceStoreProvider);
    unawaited(
      store
          .save(
            device == null
                ? null
                : (
                    id: device.id,
                    name: device.name,
                    type: device.type,
                    isExternal: device.isExternal,
                  ),
          )
          .catchError((Object _) {}),
    );
  }
}

/// The connected device for the current choice; null (internal microphones)
/// while the chosen device is unplugged.
final activeInputDeviceProvider = Provider<InputDevice?>((ref) {
  final choice = ref.watch(inputDeviceChoiceProvider);
  final devices = ref.watch(inputDevicesProvider).value;
  if (devices == null) return choice;
  return reconcileSelection(choice, devices);
});

/// [activeInputDeviceProvider] once the device list is loaded; the internal
/// microphones when the list cannot be read.
Future<InputDevice?> readActiveInputDevice(Ref ref) async {
  await ref.read(inputDeviceChoiceProvider.notifier).ready;
  try {
    await ref.read(inputDevicesProvider.future);
  } catch (_) {
    return null;
  }
  return ref.read(activeInputDeviceProvider);
}

/// Dropdown for the app-wide input device, only in the "Gerät" tab.
class InputDeviceSelector extends ConsumerWidget {
  const InputDeviceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(inputDevicesProvider);
    final choice = ref.watch(inputDeviceChoiceProvider);
    final active = ref.watch(activeInputDeviceProvider);
    final list = devices.value ?? const <InputDevice>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              // New field state when the active device changes (replugged,
              // unplugged), so the shown value follows.
              child: KeyedSubtree(
                key: ValueKey(active?.id),
                child: DropdownButtonFormField<int?>(
                  key: const Key('input-device'),
                  initialValue: active?.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Eingabegerät'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Interne Mikrofone (Standard)'),
                    ),
                    for (final d in list)
                      DropdownMenuItem(
                        value: d.id,
                        child: Text(d.label, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (id) {
                    InputDevice? device;
                    for (final d in list) {
                      if (d.id == id) device = d;
                    }
                    ref.read(inputDeviceChoiceProvider.notifier).choose(device);
                  },
                ),
              ),
            ),
            IconButton(
              tooltip: 'Geräteliste aktualisieren',
              onPressed: () => ref.invalidate(inputDevicesProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const _DeviceStatus(showFormat: true),
        if (devices.hasValue && list.isEmpty && choice == null)
          const Text(
            'Kein externes Gerät erkannt. Ein USB-Interface wird nach dem '
            'Anschließen automatisch angezeigt.',
          ),
      ],
    );
  }
}

/// Names the app-wide input device on screens that record; it is changed
/// only in the "Gerät" tab.
class InputDeviceHint extends ConsumerWidget {
  const InputDeviceHint({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeInputDeviceProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.mic_none, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Eingabegerät: '
                  '${active?.label ?? 'Interne Mikrofone'} '
                  '(ändern im Tab „Gerät“)',
                  key: const Key('input-device-hint'),
                ),
              ),
            ],
          ),
          const _DeviceStatus(showFormat: false),
        ],
      ),
    );
  }
}

/// Warnings about the chosen device: list not readable, unplugged, mono.
class _DeviceStatus extends ConsumerWidget {
  const _DeviceStatus({required this.showFormat});

  /// Also show what Android reports about a stereo device.
  final bool showFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(inputDevicesProvider);
    final choice = ref.watch(inputDeviceChoiceProvider);
    final active = ref.watch(activeInputDeviceProvider);
    final error = Theme.of(context).colorScheme.error;
    if (devices.hasError) {
      return Text(
        'Geräteliste nicht abfragbar: ${devices.error}',
        style: TextStyle(color: error),
      );
    }
    if (choice != null && active == null) {
      return Text(
        '${choice.name} ist nicht verbunden. Aufgenommen wird mit den '
        'internen Mikrofonen, bis das Gerät wieder angeschlossen ist.',
        style: TextStyle(color: error),
      );
    }
    if (active?.stereo == false) {
      return Text(
        '${active!.reportedFormat}. Das ist nur die Angabe des Geräts; '
        'ob wirklich zwei getrennte Kanäle ankommen, zeigt die '
        'Stereo-Prüfung im Pegeltest. Funkempfänger mit zwei Sendern '
        'liefern oft nur im Stereo-Modus (Schalter oder App des '
        'Empfängers) getrennte Kanäle.',
        key: const Key('input-device-mono-hint'),
        style: TextStyle(color: error),
      );
    }
    if (showFormat && active != null) return Text(active.reportedFormat);
    return const SizedBox.shrink();
  }
}

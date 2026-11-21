import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nyooom/audio/stereo_recorder.dart';
import 'package:nyooom/data/database.dart';
import 'package:nyooom/data/input_choice_store.dart';
import 'package:nyooom/ui/calibration/calibration_screen.dart';
import 'package:nyooom/ui/device/input_device_selection.dart';
import 'package:nyooom/ui/providers.dart';
import 'package:nyooom/ui/recorder/recorder_controller.dart';
import 'package:nyooom/ui/recorder/recorder_screen.dart';
import 'package:nyooom/ui/series/series_screens.dart';

import '../../helpers/fake_stereo_recorder.dart';

Future<void> flush() => Future<void>.delayed(Duration.zero);

const builtin = InputDevice(
  id: 1,
  name: 'Fake Phone',
  type: 15,
  isExternal: false,
);
const usb = InputDevice(
  id: 9,
  name: 'USB Audio',
  type: 11,
  isExternal: true,
  channelCounts: [1, 2],
);

void main() {
  late FakeStereoRecorder recorder;
  late ProviderContainer container;
  late MemoryInputChoiceStore store;

  setUp(() {
    recorder = FakeStereoRecorder()..devices = [builtin, usb];
    store = MemoryInputChoiceStore();
    container = ProviderContainer(
      overrides: [
        stereoRecorderProvider.overrideWithValue(recorder),
        inputChoiceStoreProvider.overrideWithValue(store),
      ],
    );
  });

  tearDown(() => container.dispose());

  test('lists the selectable devices (USB, not the built-in mics)', () async {
    final devices = await container.read(inputDevicesProvider.future);
    expect(devices.map((d) => d.id), [9]);
  });

  test('without a choice the internal microphones are used', () async {
    await container.read(inputDevicesProvider.future);
    expect(container.read(activeInputDeviceProvider), isNull);
  });

  test('a chosen USB device is active everywhere', () async {
    await container.read(inputDevicesProvider.future);
    container.read(inputDeviceChoiceProvider.notifier).choose(usb);
    expect(container.read(activeInputDeviceProvider)?.id, 9);
  });

  test('unplugging falls back to internal, plugging in restores it', () async {
    final sub = container.listen(activeInputDeviceProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(inputDevicesProvider.future);
    container.read(inputDeviceChoiceProvider.notifier).choose(usb);

    recorder.devices = [builtin];
    recorder.emitDeviceChange();
    await flush();
    await container.read(inputDevicesProvider.future);
    expect(container.read(activeInputDeviceProvider), isNull);

    recorder.devices = [
      builtin,
      const InputDevice(id: 14, name: 'USB Audio', type: 11, isExternal: true),
    ];
    recorder.emitDeviceChange();
    await flush();
    await container.read(inputDevicesProvider.future);
    expect(container.read(activeInputDeviceProvider)?.id, 14);
  });

  testWidgets('the selector offers the USB device and stores the choice', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: InputDeviceSelector())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('input-device')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USB Audio (USB)').last);
    await tester.pumpAndSettle();
    expect(container.read(inputDeviceChoiceProvider)?.id, 9);
  });

  test('without the app wiring the choice stays in memory', () {
    final plain = ProviderContainer();
    addTearDown(plain.dispose);
    expect(plain.read(inputChoiceStoreProvider), isA<MemoryInputChoiceStore>());
  });

  test('the choice is stored for the next app start', () async {
    await container.read(inputDevicesProvider.future);
    container.read(inputDeviceChoiceProvider.notifier).choose(usb);
    await flush();
    expect(store.saved?.name, 'USB Audio');

    final next = ProviderContainer(
      overrides: [
        stereoRecorderProvider.overrideWithValue(recorder),
        inputChoiceStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(next.dispose);
    final sub = next.listen(activeInputDeviceProvider, (_, _) {});
    addTearDown(sub.close);
    await next.read(inputDeviceChoiceProvider.notifier).ready;
    await next.read(inputDevicesProvider.future);
    expect(next.read(activeInputDeviceProvider)?.id, 9);
  });

  test(
    'a choice made while loading is not overwritten by the stored one',
    () async {
      store.saved = (id: 9, name: 'USB Audio', type: 11, isExternal: true);
      final notifier = container.read(inputDeviceChoiceProvider.notifier);
      notifier.choose(null);
      await notifier.ready;
      expect(container.read(inputDeviceChoiceProvider), isNull);
    },
  );

  test('recording waits for the stored choice', () async {
    store.saved = (id: 9, name: 'USB Audio', type: 11, isExternal: true);
    final fresh = ProviderContainer(
      overrides: [
        stereoRecorderProvider.overrideWithValue(recorder),
        inputChoiceStoreProvider.overrideWithValue(store),
        recordingsDirectoryProvider.overrideWith(
          (ref) async => Directory.systemTemp,
        ),
      ],
    );
    addTearDown(fresh.dispose);
    await fresh.read(recorderControllerProvider.notifier).start();
    expect(recorder.lastInputDeviceId, 9);
  });

  testWidgets('the calibration assistant only names the device', (
    tester,
  ) async {
    final db = NyooomDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          stereoRecorderProvider.overrideWithValue(recorder),
          inputChoiceStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: CalibrationScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InputDeviceSelector), findsNothing);
    expect(find.byType(InputDeviceHint), findsOneWidget);
    await tester.runAsync(db.close);
  });

  testWidgets('the level test only names the device', (tester) async {
    store.saved = (id: 9, name: 'USB Audio', type: 11, isExternal: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          stereoRecorderProvider.overrideWithValue(recorder),
          inputChoiceStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: RecorderScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InputDeviceSelector), findsNothing);
    expect(find.textContaining('USB Audio (USB)'), findsOneWidget);
  });

  testWidgets('a new series only names the device', (tester) async {
    final db = NyooomDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          stereoRecorderProvider.overrideWithValue(recorder),
          inputChoiceStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: SeriesStartScreen()),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.byType(InputDeviceSelector), findsNothing);
    expect(
      find.textContaining('Interne Mikrofone', skipOffstage: false),
      findsOneWidget,
    );
    await tester.runAsync(db.close);
  });

  testWidgets('the device tab offers the device selection', (tester) async {
    final db = NyooomDatabase(NativeDatabase.memory());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          stereoRecorderProvider.overrideWithValue(recorder),
          inputChoiceStoreProvider.overrideWithValue(store),
        ],
        child: const MaterialApp(home: DeviceScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InputDeviceSelector), findsOneWidget);
    await tester.runAsync(db.close);
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../audio/capture.dart';
import '../../audio/simulated_stereo_recorder.dart';
import '../../audio/stereo_recorder.dart';
import '../../core/calibration/device_checks.dart';
import '../../data/database.dart';
import '../providers.dart';
import '../recorder/recorder_screen.dart';
import '../series/series_screens.dart' show formatDate;
import '../sites/site_form.dart' show parseDecimal;
import 'calibration_controller.dart';

/// "Gerät" tab: calibration status, assistant and level test.
class DeviceScreen extends ConsumerWidget {
  const DeviceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final simulated = ref.watch(simulationDefaultProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Gerät')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Simulation als Standard'),
            subtitle: const Text(
              'Messreihen und Kalibrierung nutzen synthetische Signale statt '
              'der Mikrofone.',
            ),
            value: simulated,
            onChanged: (v) =>
                ref.read(simulationDefaultProvider.notifier).set(v),
          ),
          const SizedBox(height: 8),
          const CalibrationStatusCard(
            model: SimulatedStereoRecorder.deviceModel,
          ),
          if (!simulated) const _PlatformCalibrationStatus(),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CalibrationScreen(),
              ),
            ),
            icon: const Icon(Icons.tune),
            label: const Text('Eignungsprüfung und Kalibrierung'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const RecorderScreen()),
            ),
            icon: const Icon(Icons.graphic_eq),
            label: const Text('Pegeltest und Rohaufnahme'),
          ),
        ],
      ),
    );
  }
}

class _PlatformCalibrationStatus extends ConsumerWidget {
  const _PlatformCalibrationStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(capabilitiesProvider);
    return caps.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('Gerät nicht abfragbar: $e'),
      data: (c) => CalibrationStatusCard(model: c.deviceModel),
    );
  }
}

/// Shows the latest calibration of [model].
class CalibrationStatusCard extends ConsumerWidget {
  const CalibrationStatusCard({super.key, required this.model});

  final String model;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestCalibrationProvider(model));
    return Card(
      child: ListTile(
        leading: const Icon(Icons.straighten),
        title: Text('Kalibrierung $model'),
        subtitle: latest.when(
          loading: () => const Text('…'),
          error: (e, _) => Text('Fehler: $e'),
          data: (CalibrationRow? c) => Text(
            c == null
                ? 'Noch nicht kalibriert. Messreihen verwenden dann b aus der '
                      'Simulation bzw. 0,15 m.'
                : 'b = ${(c.micSpacingM * 100).toStringAsFixed(1)} cm, '
                      'Δ0 = ${(c.channelOffsetS * 1e6).toStringAsFixed(1)} µs'
                      '${c.swapChannels ? ', Kanäle getauscht' : ''} · '
                      '${formatDate(c.createdAtUtcMs)}',
          ),
        ),
      ),
    );
  }
}

/// Guided assistant for technik.pdf 4.4 and 7.1.
class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  final _temperature = TextEditingController(text: '15');
  bool? _simulate;
  InputDevice? _device;
  bool _started = false;

  @override
  void dispose() {
    _temperature.dispose();
    super.dispose();
  }

  Future<void> _begin() async {
    final bool simulate = _simulate ?? ref.read(simulationDefaultProvider);
    final temperature = parseDecimal(_temperature.text) ?? 15;
    CalibrationCapture capture;
    if (simulate) {
      capture = SimulatedCalibrationCapture();
    } else {
      final recorder = ref.read(stereoRecorderProvider);
      final caps = await recorder.capabilities();
      capture = RecorderCalibrationCapture(
        recorder: recorder,
        deviceModel: caps.deviceModel,
        sampleRate: ref.read(configProvider).sampleRate,
        inputDeviceId: _device?.id,
        inputName: _device == null || !_device!.isExternal
            ? 'intern'
            : _device!.name,
      );
    }
    ref.read(calibrationProvider.notifier).begin(capture, temperature);
    setState(() => _started = true);
  }

  @override
  Widget build(BuildContext context) {
    final bool simulate = _simulate ?? ref.watch(simulationDefaultProvider);
    final state = ref.watch(calibrationProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Eignung und Kalibrierung')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!_started) ...[
            SwitchListTile(
              title: const Text('Simuliertes Gerät'),
              value: simulate,
              onChanged: (v) => setState(() => _simulate = v),
            ),
            if (!simulate) _deviceSelection(),
            TextField(
              controller: _temperature,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Lufttemperatur (°C)',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Stelle das Smartphone wie bei einer Messung auf (Querformat, '
              'Stativ, Mikrofonachse parallel zur Fahrbahn).',
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _begin, child: const Text('Starten')),
          ] else ...[
            _StepCard(
              title: '1. Klatschen rechts',
              text:
                  'Mindestens 3 m entfernt genau in Verlängerung der '
                  'Mikrofonachse auf der rechten Seite (wohin Fahrzeuge der '
                  'Richtung → fahren) dreimal klatschen oder einen '
                  'Schlüsselbund schütteln.',
              step: CalibrationStep.clapsRight,
              done: state.right == null ? null : _axisText(state.right!),
            ),
            _StepCard(
              title: '2. Klatschen links',
              text: 'Dasselbe auf der linken Seite.',
              step: CalibrationStep.clapsLeft,
              done: state.left == null ? null : _axisText(state.left!),
            ),
            _StepCard(
              title: '3. Konstantes Signal',
              text:
                  'Aus einem Lautsprecher 10 s gleichmäßiges Rauschen oder '
                  'einen Ton abspielen. Der Pegel darf nicht nachregeln.',
              step: CalibrationStep.constantSignal,
              done: state.processing?.message,
            ),
            if (state.error != null)
              Text(
                state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 12),
            Text('Ergebnis', style: Theme.of(context).textTheme.titleMedium),
            _check('Prüfung 1: echtes Stereo', state.stereo),
            _check('Prüfung 2: keine Vorverarbeitung', state.processing),
            _check('Prüfung 3: keine Übersteuerung', state.clipping),
            _check('Prüfung 4: Kanalzuordnung', state.mapping),
            if (state.result != null) ...[
              const SizedBox(height: 8),
              Text(
                'b = ${(state.result!.micSpacing * 100).toStringAsFixed(2)} cm '
                '(b/c = ${(state.result!.maxTdoa * 1e6).toStringAsFixed(1)} µs), '
                'Δ0 = ${(state.result!.channelOffset * 1e6).toStringAsFixed(1)} µs',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (state.result!.micSpacing < 0.10 ||
                  state.result!.micSpacing > 0.20)
                const Text(
                  'Hinweis: b liegt außerhalb von 10 bis 20 cm. Aufstellung '
                  'und Klatschposition prüfen.',
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: state.savedId != null
                    ? null
                    : () async {
                        await ref.read(calibrationProvider.notifier).save();
                      },
                icon: const Icon(Icons.save),
                label: Text(
                  state.savedId != null
                      ? 'Gespeichert'
                      : 'Kalibrierung speichern',
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _deviceSelection() {
    return FutureBuilder<List<InputDevice>>(
      future: ref.read(stereoRecorderProvider).inputDevices(),
      builder: (context, snapshot) {
        final devices = snapshot.data ?? const <InputDevice>[];
        return DropdownButtonFormField<int?>(
          initialValue: _device?.id,
          decoration: const InputDecoration(labelText: 'Eingabegerät'),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('Standard (intern)'),
            ),
            for (final d in devices)
              DropdownMenuItem(
                value: d.id,
                child: Text('${d.name}${d.isExternal ? ' (extern)' : ''}'),
              ),
          ],
          onChanged: (id) => setState(() {
            _device = null;
            for (final d in devices) {
              if (d.id == id) _device = d;
            }
          }),
        );
      },
    );
  }

  String _axisText(AxisMeasurement m) => m.count == 0
      ? 'Kein Klatschen erkannt.'
      : '${m.count} Ereignisse, Δ = ${(m.delay * 1e6).toStringAsFixed(1)} µs';

  Widget _check(String label, CheckResult? result) => ListTile(
    dense: true,
    leading: Icon(
      result == null
          ? Icons.radio_button_unchecked
          : result.passed
          ? Icons.check_circle
          : Icons.cancel,
      color: result == null
          ? null
          : result.passed
          ? Colors.green
          : Theme.of(context).colorScheme.error,
    ),
    title: Text(label),
    subtitle: result == null ? null : Text(result.message),
  );
}

class _StepCard extends ConsumerWidget {
  const _StepCard({
    required this.title,
    required this.text,
    required this.step,
    required this.done,
  });

  final String title;
  final String text;
  final CalibrationStep step;
  final String? done;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(calibrationProvider.select((s) => s.busy));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            Text(text),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: busy != null
                      ? null
                      : () =>
                            ref.read(calibrationProvider.notifier).record(step),
                  child: Text(
                    busy == step
                        ? 'Nimmt auf …'
                        : 'Aufnehmen (${calibrationStepDuration[step]!.inSeconds} s)',
                  ),
                ),
                const SizedBox(width: 12),
                if (done != null) Expanded(child: Text(done!)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

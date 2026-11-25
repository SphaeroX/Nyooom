import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../audio/capture.dart';
import '../../audio/input_devices.dart';
import '../../audio/simulated_stereo_recorder.dart';
import '../../core/calibration/device_checks.dart';
import '../../data/database.dart';
import '../device/input_device_selection.dart';
import '../providers.dart';
import '../recorder/recorder_screen.dart';
import '../series/series_screens.dart' show formatDate;
import '../sites/site_form.dart' show parseDecimal;
import '../weather/outdoor_temperature_providers.dart';
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
          if (simulated)
            const CalibrationStatusCard(
              model: SimulatedStereoRecorder.deviceModel,
            )
          else ...[
            const InputDeviceSelector(),
            const SizedBox(height: 8),
            const _PlatformCalibrationStatus(),
          ],
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
    final input = calibrationInputName(ref.watch(activeInputDeviceProvider));
    return caps.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('Gerät nicht abfragbar: $e'),
      data: (c) => CalibrationStatusCard(model: c.deviceModel, input: input),
    );
  }
}

/// Shows the latest calibration of [model] with [input].
class CalibrationStatusCard extends ConsumerWidget {
  const CalibrationStatusCard({
    super.key,
    required this.model,
    this.input = 'intern',
  });

  final String model;

  /// `intern` or the name of the external input device.
  final String input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(
      latestCalibrationProvider((model: model, input: input)),
    );
    return Card(
      child: ListTile(
        leading: const Icon(Icons.straighten),
        title: Text(
          input == 'intern'
              ? 'Kalibrierung $model'
              : 'Kalibrierung $model · $input',
        ),
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

/// Step-by-step assistant for the suitability check (technik.pdf 4.4) and
/// the calibration of b and Δ0 (technik.pdf 7.1), written for laypeople.
///
/// Pages: 0 welcome and settings, 1 set up the phone, 2 claps right,
/// 3 claps left, 4 constant signal (optional), 5 result.
class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

const _pageCount = 6;

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  final _temperature = TextEditingController(text: '15');
  String? _temperatureNote;
  bool? _simulate;
  int _page = 0;

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
      final device = ref.read(activeInputDeviceProvider);
      capture = RecorderCalibrationCapture(
        recorder: recorder,
        deviceModel: caps.deviceModel,
        sampleRate: ref.read(configProvider).sampleRate,
        inputDeviceId: device?.id,
        inputName: calibrationInputName(device),
      );
    }
    if (!mounted) return;
    ref.read(calibrationProvider.notifier).begin(capture, temperature);
  }

  static CalibrationStep? _stepOf(int page) => switch (page) {
    2 => CalibrationStep.clapsRight,
    3 => CalibrationStep.clapsLeft,
    4 => CalibrationStep.constantSignal,
    _ => null,
  };

  Future<void> _next() async {
    if (_page == 0) await _begin();
    if (mounted) setState(() => _page++);
  }

  void _back() => setState(() => _page--);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calibrationProvider);
    final controller = ref.read(calibrationProvider.notifier);
    final step = _stepOf(_page);
    final busy = state.busy != null;
    if (busy && step != null && state.busy == step) {
      return Scaffold(
        body: SafeArea(
          child: _RecordingPanel(
            step: step,
            countdown: state.countdown,
            onCancel: controller.cancelCountdown,
          ),
        ),
      );
    }
    final canNext = switch (_page) {
      0 || 1 => true,
      2 || 3 || 4 => controller.stepPassed(step!),
      _ => false,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Kalibrierung')),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_page + 1) / _pageCount),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Schritt ${_page + 1} von $_pageCount',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                ..._pageContent(context, state),
              ],
            ),
          ),
          if (_page < _pageCount - 1)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_page == 4 && !canNext)
                      TextButton(
                        key: const Key('wizard-skip'),
                        onPressed: busy ? null : _next,
                        child: const Text('Überspringen'),
                      ),
                    Row(
                      children: [
                        if (_page > 0) ...[
                          Expanded(
                            child: OutlinedButton(
                              key: const Key('wizard-back'),
                              onPressed: busy ? null : _back,
                              child: const Text('Zurück'),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: FilledButton(
                            key: const Key('wizard-next'),
                            onPressed: canNext && !busy ? _next : null,
                            child: Text(_page == 0 ? 'Los geht’s' : 'Weiter'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _pageContent(BuildContext context, CalibrationState state) {
    final theme = Theme.of(context);
    Widget title(String t) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(t, style: theme.textTheme.headlineSmall),
    );
    switch (_page) {
      case 0:
        final bool simulate = _simulate ?? ref.watch(simulationDefaultProvider);
        return [
          title('Willkommen zur Kalibrierung'),
          const Text(
            'Die App muss einmal lernen, wie weit die beiden Mikrofone deines '
            'Handys auseinanderliegen und ob sie getrennt aufnehmen. Dafür '
            'klatschst du links und rechts neben dem Handy in die Hände. Das '
            'dauert etwa 3 Minuten.',
          ),
          const SizedBox(height: 16),
          Text('Du brauchst', style: theme.textTheme.titleMedium),
          const _Bullet(
            Icons.camera_outlined,
            'Ein Stativ oder eine Halterung für das Handy',
          ),
          const _Bullet(
            Icons.open_in_full,
            'Etwa 3 m freien Platz links und rechts vom Handy',
          ),
          const _Bullet(Icons.volume_off, 'Eine möglichst ruhige Umgebung'),
          const _Bullet(
            Icons.speaker,
            'Optional: einen Lautsprecher (z. B. ein zweites Handy) für den '
            'letzten Test',
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('wizard-temperature'),
            controller: _temperature,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              labelText: 'Lufttemperatur draußen (°C)',
              helperText: _temperatureNote ?? 'Ein ungefährer Wert reicht.',
              suffixIcon: GpsTemperatureButton(
                key: const Key('wizard-temperature-gps'),
                onTemperature: (t) => setState(() {
                  _temperature.text = t.temperatureC.toStringAsFixed(1);
                  _temperatureNote = 'Wetterdienst am Standort (Open-Meteo)';
                }),
                onError: (message) =>
                    setState(() => _temperatureNote = message),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (!simulate) const InputDeviceHint(),
          ExpansionTile(
            title: const Text('Erweiterte Einstellungen'),
            tilePadding: EdgeInsets.zero,
            children: [
              SwitchListTile(
                title: const Text('Simuliertes Gerät'),
                subtitle: const Text('Zum Ausprobieren ohne Mikrofone'),
                value: simulate,
                onChanged: (v) => setState(() => _simulate = v),
              ),
            ],
          ),
        ];
      case 1:
        return [
          title('Handy aufstellen'),
          const _SetupDiagram(),
          const SizedBox(height: 16),
          const _NumberedHint(
            1,
            'Stelle das Handy quer auf das Stativ, etwa auf Hüfthöhe – so wie '
            'später bei der Messung.',
          ),
          const _NumberedHint(
            2,
            'Das Display zeigt zu dir. Die beiden schmalen Enden des Handys '
            'zeigen nach links und rechts.',
          ),
          const _NumberedHint(
            3,
            'Entferne eine dicke Hülle und verdecke die Mikrofone nicht.',
          ),
          const _NumberedHint(
            4,
            'Sorge für Ruhe: Kein Radio, keine Gespräche in der Nähe.',
          ),
        ];
      case 2:
        return [
          title('Rechts klatschen'),
          const _ClapInstructions(side: 'rechts', end: 'rechte'),
          const SizedBox(height: 16),
          _StepStatus(step: CalibrationStep.clapsRight, state: state),
        ];
      case 3:
        return [
          title('Links klatschen'),
          const _ClapInstructions(side: 'links', end: 'linke'),
          const SizedBox(height: 16),
          _StepStatus(step: CalibrationStep.clapsLeft, state: state),
        ];
      case 4:
        return [
          title('Gleichmäßiges Geräusch (optional)'),
          const Text(
            'Dieser Test prüft, ob das Handy die Lautstärke heimlich '
            'nachregelt. Du brauchst dafür einen Lautsprecher, zum Beispiel '
            'ein zweites Handy.',
          ),
          const SizedBox(height: 12),
          const _NumberedHint(
            1,
            'Suche ein gleichmäßiges Rauschen (z. B. „White Noise“) oder einen '
            'Dauerton und stelle es auf mittlere Lautstärke.',
          ),
          const _NumberedHint(
            2,
            'Tippe auf „Aufnahme starten“. Du hast 5 Sekunden, um das '
            'Geräusch zu starten und den Lautsprecher etwa 1 m vor das Handy '
            'zu legen.',
          ),
          _NumberedHint(
            3,
            'Danach nimmt die App '
            '${calibrationStepDuration[CalibrationStep.constantSignal]!.inSeconds}'
            ' Sekunden auf. Lass das Geräusch einfach laufen.',
          ),
          const SizedBox(height: 4),
          const Text(
            'Kein Lautsprecher zur Hand? Dann tippe auf „Überspringen“.',
          ),
          const SizedBox(height: 16),
          _StepStatus(step: CalibrationStep.constantSignal, state: state),
        ];
      default:
        return [title('Ergebnis'), ..._resultContent(context, state)];
    }
  }

  List<Widget> _resultContent(BuildContext context, CalibrationState state) {
    final theme = Theme.of(context);
    final result = state.result;
    if (result == null) {
      return [
        const Text(
          'Die Kalibrierung ist noch nicht vollständig. Gehe zurück und '
          'wiederhole das Klatschen.',
        ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _back, child: const Text('Zurück')),
      ];
    }
    final spacingOk = result.micSpacing >= 0.10 && result.micSpacing <= 0.20;
    return [
      Card(
        color: theme.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Kalibrierung gelungen', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Abstand der Mikrofone: '
                '${(result.micSpacing * 100).toStringAsFixed(1)} cm',
                style: theme.textTheme.titleMedium,
              ),
              Text(
                'Technische Werte: b/c = '
                '${(result.maxTdoa * 1e6).toStringAsFixed(1)} µs, '
                'Δ0 = ${(result.channelOffset * 1e6).toStringAsFixed(1)} µs',
              ),
            ],
          ),
        ),
      ),
      if (!spacingOk)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Hinweis: Der Abstand ist ungewöhnlich (erwartet 10 bis 20 cm). '
            'Prüfe, ob du genau in Verlängerung des Handys geklatscht hast, '
            'und wiederhole sonst Schritt 3 und 4.',
          ),
        ),
      const SizedBox(height: 12),
      Text('Prüfungen', style: theme.textTheme.titleMedium),
      _check('Echtes Stereo (zwei getrennte Mikrofone)', state.stereo),
      _check('Keine Lautstärke-Nachregelung', state.processing),
      _check('Keine Übersteuerung', state.clipping),
      _check('Kanalzuordnung links/rechts', state.mapping),
      const SizedBox(height: 16),
      if (state.savedId == null)
        FilledButton.icon(
          key: const Key('wizard-save'),
          onPressed: () => ref.read(calibrationProvider.notifier).save(),
          icon: const Icon(Icons.save),
          label: const Text('Kalibrierung speichern'),
        )
      else ...[
        const Text(
          'Gespeichert. Messreihen mit diesem Handy nutzen jetzt '
          'diese Werte.',
        ),
        const SizedBox(height: 8),
        FilledButton(
          key: const Key('wizard-done'),
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Fertig'),
        ),
      ],
      const SizedBox(height: 8),
      OutlinedButton(
        key: const Key('wizard-back'),
        onPressed: _back,
        child: const Text('Zurück'),
      ),
    ];
  }

  Widget _check(String label, CheckResult? result) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      result == null
          ? Icons.remove_circle_outline
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
    subtitle: Text(result == null ? 'Übersprungen' : result.message),
  );
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _NumberedHint extends StatelessWidget {
  const _NumberedHint(this.number, this.text);

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 12, child: Text('$number')),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

/// Person – 3 m – phone – 3 m – person, seen from above.
class _SetupDiagram extends StatelessWidget {
  const _SetupDiagram();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    Widget gap() => Expanded(
      child: Column(
        children: [
          Text('ca. 3 m', style: style),
          const Divider(thickness: 2),
        ],
      ),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.sign_language, size: 32),
                gap(),
                const RotatedBox(
                  quarterTurns: 1,
                  child: Icon(Icons.smartphone, size: 40),
                ),
                gap(),
                const Icon(Icons.sign_language, size: 32),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text('Links klatschen', style: style)),
                Expanded(
                  child: Text(
                    'Handy (quer)',
                    style: style,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Rechts klatschen',
                    style: style,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ClapInstructions extends StatelessWidget {
  const _ClapInstructions({required this.side, required this.end});

  final String side;
  final String end;

  @override
  Widget build(BuildContext context) {
    final countdown = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(calibrationCountdownProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NumberedHint(
          1,
          'Tippe auf „Aufnahme starten“. Du hast dann '
          '${countdown.seconds} Sekunden Zeit.',
        ),
        _NumberedHint(
          2,
          'Geh in dieser Zeit etwa 3 m nach $side – genau in die '
          'Verlängerung des Handys, also dorthin, wohin das $end Ende '
          'des Handys zeigt.',
        ),
        const _NumberedHint(
          3,
          'Wenn der Bildschirm grün wird, läuft die Aufnahme: Klatsche '
          'dreimal kräftig in die Hände, mit etwa einer Sekunde Pause.',
        ),
        const _NumberedHint(
          4,
          'Bleib danach still stehen, bis die Aufnahme endet, und komm dann '
          'zurück zum Handy.',
        ),
      ],
    );
  }
}

/// Record button and the outcome of the last attempt of [step].
class _StepStatus extends ConsumerWidget {
  const _StepStatus({required this.step, required this.state});

  final CalibrationStep step;
  final CalibrationState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(calibrationProvider.notifier);
    final theme = Theme.of(context);
    final attempted = switch (step) {
      CalibrationStep.clapsRight => state.right != null,
      CalibrationStep.clapsLeft => state.left != null,
      CalibrationStep.constantSignal => state.processing != null,
    };
    final passed = controller.stepPassed(step);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (attempted && passed)
          Card(
            key: const Key('wizard-step-ok'),
            color: Colors.green.shade100,
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text(
                'Geklappt!',
                style: TextStyle(color: Colors.black),
              ),
              subtitle: Text(
                _successText(),
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ),
        if (attempted && !passed)
          Card(
            key: const Key('wizard-step-failed'),
            color: theme.colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.error, color: theme.colorScheme.error),
              title: const Text('Das hat leider nicht geklappt'),
              subtitle: Text(_failureText()),
            ),
          ),
        if (state.error != null)
          Text(state.error!, style: TextStyle(color: theme.colorScheme.error)),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('wizard-record'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: state.busy != null
              ? null
              : () => controller.recordAfterCountdown(step),
          icon: Icon(attempted ? Icons.replay : Icons.fiber_manual_record),
          label: Text(attempted ? 'Nochmal aufnehmen' : 'Aufnahme starten'),
        ),
      ],
    );
  }

  String _successText() => switch (step) {
    CalibrationStep.clapsRight =>
      '${state.right!.count} Klatscher erkannt. Weiter zur linken Seite.',
    CalibrationStep.clapsLeft =>
      '${state.left!.count} Klatscher erkannt. Beide Mikrofone nehmen '
          'getrennt auf.',
    CalibrationStep.constantSignal => 'Keine Nachregelung festgestellt.',
  };

  String _failureText() {
    switch (step) {
      case CalibrationStep.clapsRight:
        return 'Es wurde kein Klatschen erkannt. Klatsche lauter und erst, '
            'wenn der Bildschirm grün ist.';
      case CalibrationStep.clapsLeft:
        if ((state.left?.count ?? 0) == 0) {
          return 'Es wurde kein Klatschen erkannt. Klatsche lauter und erst, '
              'wenn der Bildschirm grün ist.';
        }
        return '${state.stereo?.message ?? ''}\nStelle dich genau in die '
            'Verlängerung des Handys. Hilft das nicht, wiederhole auch '
            'Schritt 3 (Zurück).';
      case CalibrationStep.constantSignal:
        return '${state.processing?.message ?? ''}\nDas Geräusch muss '
            'gleichmäßig laufen. Du kannst den Test auch überspringen.';
    }
  }
}

/// Full-screen countdown (orange) and recording (green) display, large
/// enough to read from 3 m.
class _RecordingPanel extends StatelessWidget {
  const _RecordingPanel({
    required this.step,
    required this.countdown,
    required this.onCancel,
  });

  final CalibrationStep step;
  final int? countdown;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final waiting = countdown != null;
    final background = waiting ? Colors.orange.shade700 : Colors.green.shade700;
    const white = TextStyle(color: Colors.white);
    final instruction = switch (step) {
      CalibrationStep.clapsRight => 'Geh jetzt ca. 3 m nach rechts',
      CalibrationStep.clapsLeft => 'Geh jetzt ca. 3 m nach links',
      CalibrationStep.constantSignal => 'Starte jetzt das Geräusch',
    };
    final action = switch (step) {
      CalibrationStep.clapsRight ||
      CalibrationStep.clapsLeft => 'JETZT 3× KLATSCHEN',
      CalibrationStep.constantSignal =>
        'Aufnahme läuft – Geräusch laufen lassen',
    };
    return Container(
      color: background,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (waiting) ...[
            Text(
              instruction,
              textAlign: TextAlign.center,
              style: white.copyWith(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FittedBox(
              child: Text(
                '$countdown',
                key: const Key('wizard-countdown'),
                style: white.copyWith(
                  fontSize: 200,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'Die Aufnahme beginnt gleich.',
              style: white.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              key: const Key('wizard-cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
              onPressed: onCancel,
              child: const Text('Abbrechen'),
            ),
          ] else ...[
            const Icon(Icons.mic, color: Colors.white, size: 120),
            const SizedBox(height: 16),
            Text(
              action,
              key: const Key('wizard-recording'),
              textAlign: TextAlign.center,
              style: white.copyWith(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const LinearProgressIndicator(
              color: Colors.white,
              backgroundColor: Colors.white24,
            ),
          ],
        ],
      ),
    );
  }
}

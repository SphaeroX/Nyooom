import 'package:material_ui/material_ui.dart';

import 'onboarding_screen.dart';

/// One step of the guide after installation.
class HelpStep {
  const HelpStep(this.icon, this.title, this.text);
  final IconData icon;
  final String title;
  final String text;
}

const helpSteps = [
  HelpStep(
    Icons.mic_none,
    'Mikrofon erlauben',
    'Beim ersten Messen fragt Android nach dem Mikrofon. Tippe auf '
        '„Zulassen“, sonst kann die App nichts hören.',
  ),
  HelpStep(
    Icons.tune,
    'Gerät prüfen und kalibrieren',
    'Tab „Gerät“ → „Eignungsprüfung und Kalibrierung“. Der Assistent führt '
        'dich durch: Handy aufstellen, rechts klatschen, links klatschen. '
        'Nur einmal pro Handy nötig, etwa 3 Minuten.',
  ),
  HelpStep(
    Icons.place_outlined,
    'Standort anlegen',
    'Tab „Standorte“ → neuer Standort. Miss für jede Fahrspur den Abstand '
        'vom Handy zur Spurmitte und trage Mikrofonhöhe und Tempolimit ein. '
        'Für einen ersten Versuch genügt der Schnelltest-Standort.',
  ),
  HelpStep(
    Icons.camera_outlined,
    'Handy aufstellen',
    'Quer auf ein Stativ, etwa 1 bis 1,5 m hoch, am Straßenrand. Die lange '
        'Kante zeigt parallel zur Fahrbahn, Hülle ab, Mikrofone frei. Bei Wind '
        'einen Windschutz verwenden.',
  ),
  HelpStep(
    Icons.fiber_manual_record,
    'Messreihe starten',
    'Tab „Messreihen“ → „Neue Messreihe“. Standort wählen, Lufttemperatur '
        'eintragen, „Aufnahme starten“. Handy liegen lassen, bis genug Autos '
        'vorbeigefahren sind, dann „Aufnahme beenden“.',
  ),
  HelpStep(
    Icons.speed,
    'Ergebnisse lesen',
    'Jede Vorbeifahrt zeigt Richtung, Geschwindigkeit und Klasse. A: sicher '
        'gemessen. B: brauchbar, etwas ungenauer. C: erkannt, aber ohne '
        'Geschwindigkeit (z. B. zwei Autos gleichzeitig).',
  ),
  HelpStep(
    Icons.bar_chart,
    'Statistik und Export',
    'In der Messreihe auf „Statistik“: Median, V85 (85 % fahren langsamer) '
        'und Anteil über dem Tempolimit, getrennt nach Richtung. Über die '
        'Export-Knöpfe als CSV oder JSON teilen.',
  ),
];

/// "Hilfe" tab: what the app does and how to use it step by step.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hilfe')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Was macht Nyooom?', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Nyooom hört mit den zwei Mikrofonen deines Handys zu, wie Autos '
            'vorbeifahren. Aus dem winzigen Zeitunterschied zwischen beiden '
            'Mikrofonen und der Tonänderung (Doppler-Effekt) berechnet die App '
            'die Geschwindigkeit. Viele Messungen ergeben eine Statistik für '
            'die Straße. Es werden keine einzelnen Verstöße nachgewiesen.',
          ),
          const SizedBox(height: 24),
          Text('Schritt für Schritt', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (var i = 0; i < helpSteps.length; i++)
            Card(
              child: ListTile(
                leading: Icon(helpSteps[i].icon),
                title: Text('${i + 1}. ${helpSteps[i].title}'),
                subtitle: Text(helpSteps[i].text),
              ),
            ),
          const SizedBox(height: 16),
          Text('Tipps', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            '• Ohne geeignetes Handy: Im Tab „Gerät“ die Simulation einschalten '
            'und alles mit künstlichem Verkehr ausprobieren.\n'
            '• Ruhige Straße mit Autos im Abstand von einigen Sekunden gibt die '
            'besten Werte.\n'
            '• Fällt die Eignungsprüfung durch, nimmt das Handy kein echtes '
            'Stereo auf; dann hilft ein externes USB-Stereomikrofon.',
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            key: const Key('help-show-onboarding'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) =>
                    OnboardingScreen(onDone: () => Navigator.of(context).pop()),
              ),
            ),
            icon: const Icon(Icons.slideshow),
            label: const Text('Einführung erneut ansehen'),
          ),
        ],
      ),
    );
  }
}

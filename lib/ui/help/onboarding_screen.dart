import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/onboarding_store.dart';
import '../providers.dart';

/// One page of the first-start introduction.
class OnboardingPage {
  const OnboardingPage(this.icon, this.title, this.text);
  final IconData icon;
  final String title;
  final String text;
}

/// Short walk through the workflow, shown once after installation and
/// again from the help tab.
const onboardingPages = [
  OnboardingPage(
    Icons.graphic_eq,
    'Willkommen bei Nyooom',
    'Nyooom misst, wie schnell Autos an dir vorbeifahren – nur mit den zwei '
        'Mikrofonen deines Handys. Daraus entsteht eine Statistik für die '
        'Straße: typische Geschwindigkeit und wie viele zu schnell fahren.',
  ),
  OnboardingPage(
    Icons.tune,
    '1. Gerät prüfen',
    'Einmalig im Tab „Gerät“: Der Assistent prüft, ob dein Handy echtes '
        'Stereo aufnimmt, und lernt den Abstand der Mikrofone. Du klatschst '
        'dafür links und rechts vom Handy. Dauer etwa 3 Minuten.',
  ),
  OnboardingPage(
    Icons.place_outlined,
    '2. Standort anlegen',
    'Im Tab „Standorte“ trägst du ein, wie weit jede Fahrspur vom Handy '
        'entfernt ist. Zum Ausprobieren reicht der Schnelltest-Standort.',
  ),
  OnboardingPage(
    Icons.fiber_manual_record,
    '3. Messen',
    'Handy quer aufs Stativ an den Straßenrand, die lange Kante parallel zur '
        'Fahrbahn, Mikrofone frei. Dann unter „Messreihen“ eine neue '
        'Messreihe starten und einfach laufen lassen.',
  ),
  OnboardingPage(
    Icons.bar_chart,
    '4. Ergebnis ansehen',
    'Jede Vorbeifahrt erscheint mit Geschwindigkeit und Klasse: A ist sicher, '
        'B brauchbar, C ohne Wert. Die Statistik zeigt Median, V85 und den '
        'Anteil über dem Tempolimit; Export als CSV oder JSON.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  /// Called on „Überspringen“ and after the last page.
  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == onboardingPages.length - 1;

  void _next() {
    if (_isLast) {
      widget.onDone();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('onboarding-skip'),
                onPressed: widget.onDone,
                child: const Text('Überspringen'),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  for (final p in onboardingPages)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            p.icon,
                            size: 96,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            p.title,
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            p.text,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < onboardingPages.length; i++)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('onboarding-next'),
                  onPressed: _next,
                  child: Text(_isLast ? 'Los geht’s' : 'Weiter'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final onboardingStoreProvider = FutureProvider<OnboardingStore>(
  (ref) async => OnboardingStore(await ref.watch(appDirectoryProvider.future)),
);

/// Whether the introduction was finished (or skipped) once.
final onboardingDoneProvider = AsyncNotifierProvider<OnboardingDone, bool>(
  OnboardingDone.new,
);

class OnboardingDone extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      (await ref.watch(onboardingStoreProvider.future)).isDone();

  Future<void> complete() async {
    state = const AsyncData(true);
    await (await ref.read(onboardingStoreProvider.future)).markDone();
  }
}

/// Shows the introduction on the first start, otherwise [child].
class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(onboardingDoneProvider);
    return switch (done) {
      AsyncData(value: false) => OnboardingScreen(
        onDone: () => ref.read(onboardingDoneProvider.notifier).complete(),
      ),
      AsyncData() || AsyncError() => child,
      _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
    };
  }
}

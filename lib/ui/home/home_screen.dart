import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../calibration/calibration_screen.dart';
import '../reference/reference_screens.dart';
import '../series/series_screens.dart';
import '../sites/site_screens.dart';

/// A top-level destination of the app.
class HomeTab {
  const HomeTab(this.label, this.icon, this.builder);
  final String label;
  final IconData icon;
  final WidgetBuilder builder;
}

/// Tabs of the home screen; later tasks add entries here.
final homeTabsProvider = Provider<List<HomeTab>>(
  (ref) => [
    HomeTab('Messreihen', Icons.list_alt, (_) => const SeriesListScreen()),
    HomeTab('Standorte', Icons.place_outlined, (_) => const SiteListScreen()),
    HomeTab('Referenz', Icons.gps_fixed, (_) => const ReferenceListScreen()),
    HomeTab('Gerät', Icons.mic_none, (_) => const DeviceScreen()),
  ],
);

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(homeTabsProvider);
    final index = _index.clamp(0, tabs.length - 1);
    return Scaffold(
      body: tabs[index].builder(context),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          for (final t in tabs)
            NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}

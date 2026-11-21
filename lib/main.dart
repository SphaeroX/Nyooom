import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'ui/help/onboarding_screen.dart';
import 'ui/device/input_device_selection.dart';
import 'ui/home/home_screen.dart';

void main() {
  runApp(
    ProviderScope(
      overrides: [inputChoiceStoreProvider.overrideWith(fileInputChoiceStore)],
      child: const NyooomApp(),
    ),
  );
}

class NyooomApp extends StatelessWidget {
  const NyooomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nyooom',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const OnboardingGate(child: HomeScreen()),
    );
  }
}

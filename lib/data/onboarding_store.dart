import 'dart:io';

/// Remembers whether the first-start introduction was finished, as a marker
/// file in the app documents directory (no extra dependency, no migration).
class OnboardingStore {
  OnboardingStore(this.directory);

  final Directory directory;

  File get _marker => File('${directory.path}/onboarding_done');

  Future<bool> isDone() => _marker.exists();

  Future<void> markDone() async {
    await directory.create(recursive: true);
    await _marker.writeAsString('1');
  }
}

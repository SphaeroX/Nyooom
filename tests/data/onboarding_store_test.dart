import 'dart:io';

import 'package:nyooom/data/onboarding_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('onboarding'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('ist beim ersten Start nicht erledigt', () async {
    expect(await OnboardingStore(dir).isDone(), isFalse);
  });

  test('merkt sich das Ende der Einführung dauerhaft', () async {
    await OnboardingStore(dir).markDone();
    expect(await OnboardingStore(dir).isDone(), isTrue);
  });
}

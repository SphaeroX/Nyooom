import 'dart:io';

import 'package:nyooom/data/input_choice_store.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late FileInputChoiceStore store;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('nyooom_choice');
    store = FileInputChoiceStore(() async => File('${dir.path}/input.json'));
  });

  tearDown(() => dir.delete(recursive: true));

  test('nothing stored means the internal microphones', () async {
    expect(await store.load(), isNull);
  });

  test('a stored choice survives a new store instance', () async {
    await store.save((id: 9, name: 'USB Audio', type: 11, isExternal: true));
    final again = FileInputChoiceStore(
      () async => File('${dir.path}/input.json'),
    );
    expect(await again.load(), (
      id: 9,
      name: 'USB Audio',
      type: 11,
      isExternal: true,
    ));
  });

  test('choosing the internal microphones clears the stored choice', () async {
    await store.save((id: 9, name: 'USB Audio', type: 11, isExternal: true));
    await store.save(null);
    expect(await store.load(), isNull);
  });

  test('an unreadable file counts as no choice', () async {
    await File('${dir.path}/input.json').writeAsString('{kaputt');
    expect(await store.load(), isNull);
  });
}

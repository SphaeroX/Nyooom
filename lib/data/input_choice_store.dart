import 'dart:convert';
import 'dart:io';

/// The input device the user chose app-wide (`InputDevice` without the
/// reported formats).
typedef InputChoice = ({int id, String name, int type, bool isExternal});

/// Keeps the app-wide input device choice across app starts; null means the
/// internal microphones.
abstract interface class InputChoiceStore {
  Future<InputChoice?> load();
  Future<void> save(InputChoice? choice);
}

/// [InputChoiceStore] in a small JSON file.
class FileInputChoiceStore implements InputChoiceStore {
  FileInputChoiceStore(this._file);

  final Future<File> Function() _file;

  @override
  Future<InputChoice?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    try {
      final json = jsonDecode(await file.readAsString()) as Map;
      return (
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
        type: (json['type'] as num).toInt(),
        isExternal: json['isExternal'] == true,
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(InputChoice? choice) async {
    final file = await _file();
    if (choice == null) {
      if (await file.exists()) await file.delete();
      return;
    }
    await file.writeAsString(
      jsonEncode({
        'id': choice.id,
        'name': choice.name,
        'type': choice.type,
        'isExternal': choice.isExternal,
      }),
    );
  }
}

/// [InputChoiceStore] that keeps the choice only while the app runs; the
/// default until the app wires in [FileInputChoiceStore] (tests stay off the
/// file system).
class MemoryInputChoiceStore implements InputChoiceStore {
  MemoryInputChoiceStore([this.saved]);

  InputChoice? saved;

  @override
  Future<InputChoice?> load() async => saved;

  @override
  Future<void> save(InputChoice? choice) async => saved = choice;
}

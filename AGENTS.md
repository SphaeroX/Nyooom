# Nyooom

Android-App (Flutter/Dart, Kotlin-Plugin für die Aufnahme), die Fahrzeuggeschwindigkeiten akustisch aus einer Stereo-Smartphone-Aufnahme schätzt. Das Messverfahren steht in `technik.pdf`; die gesamte Signalverarbeitung ist reines Dart in `lib/core/`.

## Oberste Regeln

1. **Test-Driven Development ist Pflicht.** Immer zuerst einen fehlschlagenden Test mit `flutter_test`/`package:test` in `tests/` schreiben, dann den minimalen Code, dann refaktorieren (Red, Green, Refactor). Kein Produktivcode ohne vorher fehlschlagenden Test. Bugfixes beginnen mit einem Test, der den Fehler reproduziert.
   - Bestehende Tests nie ändern, löschen oder abschwächen (auch keine Toleranzen lockern), um Grün zu erreichen. Schlägt ein Test fehl, wird die Implementierung korrigiert. Ist der Test selbst falsch, begründen und Freigabe einholen.
   - Reparaturbudget: höchstens 3 Versuche pro fehlschlagendem Test, danach anhalten und berichten (welche Tests, was versucht, Vermutung zur Ursache).
   - Führe zuerst die Tests aus, die zur Änderung gehören (Zuordnung in `docs/testing.md`); die komplette Suite bei gemeinsam genutztem Code und vor Abschluss eines Roadmap-Tasks.
2. **Dokumentation aktuell halten.** Ändert sich Tech-Stack, Architektur, Konventionen, Code-Style oder Testing, aktualisiere sofort im selben Arbeitsschritt die passende Datei in `docs/`. Eine Aufgabe ist erst erledigt, wenn `docs/` stimmt.
3. **Flutter nur über FVM.** Alle Befehle als `fvm flutter …` bzw. `fvm dart …` (Version in `.fvmrc`, 3.50.0). Nie das globale `flutter` verwenden, dort ist eine andere Version aktiv. Pakete nur mit `fvm flutter pub add`.
4. **Roadmap-Tasks** werden nach `Roadmap/AGENTS.md` abgearbeitet; aktuelle Task-Dateien liegen in `Roadmap/Tasks/`.

## Befehle

```bash
fvm flutter pub get                                       # Abhängigkeiten
fvm flutter test tests/                                   # alle Tests
fvm flutter test tests/<pfad>/<name>_test.dart            # einzelne Datei
fvm flutter analyze                                       # Lint
fvm dart format lib tests                                 # Format
fvm flutter build apk --debug                             # Build
```

Tests liegen in `tests/` (nicht `test/`), den Pfad deshalb immer angeben.

## Dokumentation (bei Bedarf laden)

Lies nur die Dateien, die für deine aktuelle Aufgabe relevant sind:

- [docs/architecture.md](docs/architecture.md) – Lies das vor Strukturänderungen, neuen Komponenten, neuen Abhängigkeiten oder Änderungen am Kotlin-Plugin. Tech-Stack, Schichten, Umgebung.
- [docs/testing.md](docs/testing.md) – Lies das, bevor du Tests schreibst, Fixtures anlegst oder die Test-Konfiguration änderst. Teststruktur, Befehle, Fertig-Kriterien.
- [docs/code-style.md](docs/code-style.md) – Lies das vor dem Schreiben oder Formatieren von Code. Einheiten, Benennung physikalischer Größen, Formatierung.
- [docs/conventions.md](docs/conventions.md) – Lies das bei Benennung, Dateiorganisation, drift-Migrationen oder Commits.
- [docs/project-brief.md](docs/project-brief.md) – Lies das, wenn Ziel, Umfang oder Nicht-Ziele unklar sind.
- [docs/method-notes.md](docs/method-notes.md) – Lies das, bevor du an Ereigniserkennung, Laufzeitanpassung, Doppler, Fusion oder Zählung etwas änderst. Prüfung des Konzepts, Spurtrennung bei mehreren Fahrzeugen, bekannte Grenzen, Aufstellung am Fenster.
- `technik.pdf` – Lies den betreffenden Abschnitt, bevor du Formeln, Parameter oder Auswerteschritte umsetzt.

## Grenzen

- `lib/core/` importiert nie `package:flutter`, drift oder Plattformcode.
- Zahlenwerte aus `technik.pdf` 9.2 nie als Literale im Code, sondern aus dem Konfigurationsobjekt.
- Keine neue Programmiersprache (C++/FFI, Python) und keine schweren Abhängigkeiten ohne Rückfrage.
- Große Rohaufnahmen nie committen; nur kurze Ausschnitte als Fixtures in `tests/fixtures/`.
- Gerätespezifisches Verhalten (Mikrofone, Audioquelle) nie aus Annahmen ableiten, sondern auf einem echten Gerät prüfen und das Ergebnis im Roadmap-Task festhalten.

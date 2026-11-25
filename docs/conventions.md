# Namenskonventionen und Best Practices

> Wann lesen: bei Benennung, Dateiorganisation, Commits und beim Anlegen neuer Komponenten.

## Namenskonventionen

- Dateien und Ordner: `snake_case` (`gcc_phat.dart`, `measurement_series_repository.dart`).
- Klassen/Enums/Typen: `UpperCamelCase`; Funktionen, Variablen, Provider: `lowerCamelCase`; Provider enden auf `Provider` (`recorderProvider`).
- Kotlin: Paket `de.nyooom.app`, Plugin-Klassen mit Präfix `Nyooom` (`NyooomAudioPlugin`); Channel-Namen `de.nyooom/audio` und `de.nyooom/audio_stream`.
- Tests: siehe `docs/testing.md` (Spiegelung von `lib/`, Endung `_test.dart`).
- Datensatzfelder für Persistenz und Export heißen wie in `technik.pdf` 9.1 (`zeit`, `richtung`, `klasse`, `v`, `sigma_v`, …); im Dart-Modell in `lowerCamelCase` (`sigmaV`), die Abbildung liegt an einer Stelle. Die CSV hängt hinter den 9.1-Feldern `audio_pos_s` (Sekunden) und `audio_pos` (`h:mm:ss.s`) an: die Position von t0 in der WAV der Messreihe (`offsetS`, bei fortgesetzten Reihen ohne Pausen), damit sich eine Vorbeifahrt im Rohaudio wiederfinden lässt.

## Struktur und Organisation

- Neue Fachlogik gehört nach `lib/core/<bereich>/` (z. B. `dsp`, `model`, `pipeline`, `stats`, `config`), nie in Widgets oder Repositories.
- Plattformzugriffe nur in `lib/audio/` bzw. Plugins; `lib/core/` kennt keine Plattform.
- Neue Persistenz: drift-Tabelle plus Repository in `lib/data/`; Schemaänderungen immer mit Migration und erhöhter `schemaVersion`.
- Rechenintensive Auswertung in Isolates (`Isolate.run` bzw. langlebiger Worker für den Live-Betrieb).

## Best Practices (projektspezifisch)

- Jede Messung ist reproduzierbar: Datensätze speichern die verwendete Konfiguration und Kalibrierung (bzw. Verweise darauf).
- Fachliche Abstufungen (Klasse B/C) immer mit maschinenlesbarem Grund, nicht nur als Text.
- Rohaudio wird nur in der Entwicklungsphase gespeichert und ist abschaltbar (`technik.pdf` 1).
- Keine neuen Abhängigkeiten ohne kurze Begründung im Commit; größere Bibliotheken (z. B. neue Sprache, natives DSP) nur nach Rückfrage.

## Git

- Commit-Nachrichten: Conventional Commits auf Englisch (`feat:`, `fix:`, `test:`, `docs:`, `chore:`, `refactor:`), optional mit Scope (`feat(dsp): add gcc-phat`).
- Branch: Arbeit direkt auf `main` oder kurzlebige Feature-Branches `task-NN-kurzname`.

---
Pflege: Bei neuen Konventionen oder Komponenten diese Datei sofort aktualisieren.

# Tech-Stack und Architektur

> Wann lesen: vor Strukturänderungen, neuen Komponenten, neuen Abhängigkeiten oder Änderungen am Kotlin-Plugin.

## Tech-Stack

- **Sprache/Runtime:** Dart 3.14 mit Flutter 3.50.0 (stable), gepinnt über FVM in `.fvmrc`.
- **Plattform:** Android (minSdk 24, wegen `AudioSource.UNPROCESSED`). iOS ist kein Ziel, die Architektur darf es aber nicht verbauen: Plattformcode bleibt hinter einer Dart-Schnittstelle.
- **Aufnahme:** eigenes Kotlin-Plugin (MethodChannel und EventChannel) mit `AudioRecord`, 48 kHz Stereo, Rohquelle `UNPROCESSED` (Rückfall `VOICE_RECOGNITION`), AGC/NS/AEC aus. Grund: Flutter-Audio-Pakete garantieren kein unbearbeitetes, abtastsynchrones Stereo (`technik.pdf` 4.2/4.3).
- **Signalverarbeitung:** reines Dart (FFT, GCC-PHAT, Modellanpassung, Doppler, Fusion, Statistik). Grund: eine Sprache, ohne Gerät testbar, plattformunabhängig. Rechenintensives läuft in Isolates.
- **State-Management:** Riverpod. Grund: gut testbar ohne Widget-Baum, passt zu Streams (Aufnahme, Live-Ergebnisse).
- **Datenhaltung:** drift (SQLite) für Geräte, Kalibrierungen, Standorte, Messreihen, Vorbeifahrten und Referenzfahrten. Rohaudio als Stereo-WAV plus `metadata.json` im App-Dokumentordner.
- **Fachliche Referenz:** `technik.pdf` im Projekt-Root. Formeln, Parameter und Abschnittsnummern im Code und in den Tests beziehen sich darauf.

## Architektur

Schichten mit einer festen Abhängigkeitsrichtung: `ui` → `data`/`audio` → `core`.

- `lib/core/`: reine Dart-Fachlogik (Signalmodell, DSP, Auswertung, Statistik, Konfiguration). **Kein Import von `package:flutter`, drift oder Plattformcode.** So bleibt sie mit `package:test` schnell testbar.
- `lib/audio/`: Dart-Schnittstelle zum Kotlin-Plugin (Recorder-Stream, Gerätefähigkeiten), WAV-Lesen und -Schreiben.
- `lib/data/`: drift-Datenbank, Repositories, Dateiablage der Messreihen.
- `lib/ui/`: Screens, Widgets, Riverpod-Provider.
- `android/`: Flutter-Host und Kotlin-Plugin-Code.

Alle Parameter aus `technik.pdf` 9.2 liegen in **einem** Konfigurationsobjekt (JSON-serialisierbar), nicht als Literale im Code.

## Umgebung

- Flutter immer über FVM aufrufen: `fvm flutter …`, `fvm dart …`. Nie das global installierte Flutter verwenden (dort ist eine andere Version aktiv).
- `fvm` liegt unter `%LOCALAPPDATA%\Pub\Cache\bin`; dieser Ordner muss im PATH sein.
- `.fvm/` wird nicht versioniert. Der Symlink `.fvm/versions/3.50.0` für die IDE braucht unter Windows den Entwicklermodus; `fvm flutter` funktioniert auch ohne ihn.
- Abhängigkeiten nur über `fvm flutter pub add`, keine anderen Paketmanager.
- Keine externen Dienste, keine Secrets, deshalb keine `.env`.

## Erster Implementierungsschritt

Das Flutter-Projekt ist noch nicht generiert. Das passiert in `Roadmap/Tasks/Task_01.md`:

```bash
fvm flutter create --org de.nyooom --project-name nyooom --platforms android,ios .
```

Danach `applicationId` und `namespace` in `android/app/build.gradle(.kts)` auf `de.nyooom.app` setzen (der Befehl erzeugt `de.nyooom.nyooom`), den erzeugten Ordner `test/` entfernen (Tests liegen in `tests/`), `flutter_lints` beibehalten und in `pubspec.yaml` die SDK-Constraint auf `^3.14.0` setzen.

## Offene Entscheidungen

- Zielgerätemodell (Roadmap Task_01/05).
- Ob reines Dart für die Live-Auswertung schnell genug ist (Roadmap Task_12). Eine neue Sprache (C++/FFI) nur nach Rückfrage.

---
Pflege: Bei Änderungen an Stack oder Architektur diese Datei sofort aktualisieren.

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

Alle Parameter aus `technik.pdf` 9.2 liegen in **einem** Konfigurationsobjekt (JSON-serialisierbar), nicht als Literale im Code. Die ausgelieferte Datei `assets/nyooom_config.json` wird mit `fvm dart run tool/write_default_config.dart` aus den Defaults erzeugt; ein Test hält beide gleich.

**Kanal- und Vorzeichenkonvention:** linker Kanal = Mikrofon bei x = −b/2, rechter Kanal = Mikrofon bei x = +b/2. Δ ist Ankunft links minus Ankunft rechts, also Δ = +b/c·u + Δ0; positive Geschwindigkeit bedeutet Fahrt in +x-Richtung (von links nach rechts).

## Umgebung

- Flutter immer über FVM aufrufen: `fvm flutter …`, `fvm dart …`. Nie das global installierte Flutter verwenden (dort ist eine andere Version aktiv).
- `fvm` liegt unter `%LOCALAPPDATA%\Pub\Cache\bin`; dieser Ordner muss im PATH sein.
- `.fvm/` wird nicht versioniert. Der Symlink `.fvm/versions/3.50.0` für die IDE braucht unter Windows den Entwicklermodus; `fvm flutter` funktioniert auch ohne ihn.
- Abhängigkeiten nur über `fvm flutter pub add`, keine anderen Paketmanager.
- Keine externen Dienste, keine Secrets, deshalb keine `.env`.

## Projektstruktur (Stand Task_03)

```
lib/
  main.dart                         App-Einstieg (ProviderScope, MaterialApp)
  core/config/nyooom_config.dart    Konfigurationsobjekt mit allen 9.2-Parametern (JSON); Kopie in assets/nyooom_config.json
  core/model/acoustics.dart         c(T), Schrägabstand, km/h-Umrechnung
  core/model/passby_model.dart      PassByModel: u, r, t = te + r/c, Δ(t), Doppler (technik.pdf 3.1–3.4)
  core/dsp/fft.dart                 radix-2-FFT, Hann-Fenster, Blockzerlegung
  core/dsp/gcc_phat.dart            GCC-PHAT, Correlogram, singleTdoa (technik.pdf 5.2)
  core/dsp/biquad.dart              IIR-Filter (Butterworth Hoch-/Tiefpass, Bandpass-Kette)
  core/dsp/fractional_delay.dart    Kaiser-gefensterter Sinc-Interpolator für Bruchteil-Verzögerungen
  core/sim/passby_simulator.dart    Generator synthetischer Vorbeifahrten mit GroundTruth
  core/sim/scenarios.dart           Fixture-Fabrik: Verbrenner, Elektroauto, Standard-Setups
  core/signal/pcm.dart              StereoBlock, De-/Interleaving (PCM16, Float32)
  core/signal/level.dart            RMS/Peak in dBFS, Clipping-Erkennung
  audio/stereo_recorder.dart        Dart-Seite des Kotlin-Plugins (Channels, Fähigkeiten, RecordingInfo)
  audio/wav.dart                    WAV-Encoder/-Decoder (16 Bit PCM) und streamender WavFileWriter
  ui/recorder/                      RecorderController (Riverpod Notifier) und RecorderScreen
android/app/src/main/kotlin/de/nyooom/app/
  MainActivity.kt                   registriert NyooomAudioPlugin
  NyooomAudioPlugin.kt              AudioRecord-Aufnahme, Berechtigung, Effekte
```

- Das Kotlin-Plugin liegt im App-Modul (kein eigenes Plugin-Paket) und wird in `MainActivity.configureFlutterEngine` registriert.
- Flutter 3.50 liefert Material als eigenes Paket: Widgets kommen aus `package:material_ui/material_ui.dart` (nicht `package:flutter/material.dart`).
- Abhängigkeiten: `flutter_riverpod`, `path_provider` (App-Dokumentordner), dev: `test`.

## Plattform-Schnittstelle Aufnahme

- MethodChannel `de.nyooom/audio`:
  - `getCapabilities` → `{unprocessedSupported, agcAvailable, nsAvailable, aecAvailable, deviceModel, sdkInt, microphones: [String]}`
  - `start {sampleRate}` → `{audioSource: "UNPROCESSED"|"VOICE_RECOGNITION", sampleRate, channels, effects: {agc, ns, aec: "unavailable"|"disabled"|"enabled"}, activeMicrophones: [String]}`; fragt bei Bedarf die Mikrofon-Berechtigung an. Fehlercodes: `PERMISSION_DENIED`, `INIT_FAILED`, `ALREADY_RUNNING`, `BUSY`.
  - `stop`
- EventChannel `de.nyooom/audio_stream`: `Uint8List`-Blöcke (ca. 20 ms), interleaved 16 Bit little-endian, L/R in der Reihenfolge von `CHANNEL_IN_STEREO`. Vor `start` abonnieren.
- Rohaufnahmen landen als `nyooom_YYYYMMDD_HHMMSS.wav` in `<App-Dokumentordner>/recordings/`.

## Offene Entscheidungen

- Zielgerätemodell (Roadmap Task_01/05).
- Ob reines Dart für die Live-Auswertung schnell genug ist (Roadmap Task_12). Eine neue Sprache (C++/FFI) nur nach Rückfrage.

---
Pflege: Bei Änderungen an Stack oder Architektur diese Datei sofort aktualisieren.

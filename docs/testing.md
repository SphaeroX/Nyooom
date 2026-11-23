# Testing-Strategie

> Wann lesen: bevor du Tests schreibst, Test-Fixtures anlegst oder die Test-Konfiguration änderst.

## Testing-Suite

`flutter_test` für Widget- und Integrationsnahe Tests, `package:test` für reine Dart-Logik aus `lib/core/`. Das ist der Standard im Flutter-Ökosystem; die DSP-Logik lässt sich ohne Gerät gegen synthetische Signale mit bekannter Wahrheit testen.

## TDD-Ablauf (verbindlich)

1. Red: Test schreiben, ausführen, Fehlschlag prüfen.
2. Green: minimalen Code schreiben, bis der Test besteht.
3. Refactor: aufräumen, Tests bleiben grün.

## Befehle

Tests liegen in `tests/` (nicht im Flutter-Standardordner `test/`), deshalb den Pfad immer angeben.

```bash
fvm flutter test tests/                                   # alle Tests
fvm flutter test tests/core/dsp/gcc_phat_test.dart        # einzelne Datei
fvm flutter test tests/core/dsp/gcc_phat_test.dart --plain-name "findet konstante Verzögerung"   # einzelner Test
fvm flutter test tests/ --coverage                        # mit Coverage (coverage/lcov.info)
```

## Welche Tests wann ausführen

- Änderung in `lib/core/<bereich>/` → `fvm flutter test tests/core/<bereich>/`
- Änderung in `lib/audio/`, `lib/data/`, `lib/ui/` → jeweils `tests/audio/`, `tests/data/`, `tests/ui/`
- Änderung an Konfiguration, Signalmodell oder synthetischem Generator (gemeinsam genutzt) → komplette Suite.
- Änderung an `motion_fit.dart`, `doppler*.dart`, `fusion.dart` oder `event_pipeline.dart` → zusätzlich `tests/data/real_recordings_test.dart` (echte Ausschnitte).

## Fertig-Kriterien

Eine Aufgabe ist fertig, wenn mechanisch prüfbar gilt:

1. Tests des betroffenen Bereichs laufen grün, vor Abschluss eines Roadmap-Tasks die komplette Suite: `fvm flutter test tests/`
2. `fvm flutter analyze` meldet keine Fehler und keine Warnungen.
3. `fvm dart format --output=none --set-exit-if-changed lib tests` endet mit Exit-Code 0.
4. Kein bestehender Test wurde geändert, gelöscht oder abgeschwächt (außer ausdrücklich beauftragt).
5. Nur auf dem Gerät prüfbares Verhalten ist per manueller Geräte-Checkliste im Roadmap-Task belegt, Ergebnis dort notiert.

## Harte Regeln

- Bei fehlschlagendem Test wird die Implementierung korrigiert, nicht der Test.
- Höchstens 3 Reparaturversuche pro fehlschlagendem Test; danach anhalten und berichten.
- Muss ein bestehender Test geändert werden: Grund nennen und Freigabe abwarten.
- Numerische Toleranzen in Tests stammen aus `technik.pdf` oder werden im Test begründet; nie nachträglich lockern, um Grün zu erreichen.

## Teststruktur

- **Ablage:** `tests/` spiegelt `lib/`: `lib/core/dsp/gcc_phat.dart` → `tests/core/dsp/gcc_phat_test.dart`. Dateien enden auf `_test.dart`.
- **Unit-Tests** (`package:test`): gesamte `lib/core/`-Logik. Kein Flutter-Import nötig.
- **Widget-Tests** (`flutter_test`): Screens und Formulare in `lib/ui/`, Provider per Riverpod-Overrides ersetzt. Echte Datei-I/O in `testWidgets` vermeiden (FakeAsync); Controller-Logik mit Dateien besser als `test` mit `ProviderContainer` prüfen.
- **Plattform-Channel:** Dart-Seite gegen gemockte MethodChannel/EventChannel testen (`TestDefaultBinaryMessengerBinding`). Das Kotlin-Plugin selbst wird über die manuelle Geräte-Checkliste geprüft.
- **Hilfsklassen:** `tests/helpers/` (z. B. `FakeStereoRecorder`, `sinePcm16`) für Tests, die einen Recorder ohne Plattform brauchen; per `stereoRecorderProvider.overrideWithValue(...)` einsetzen. Eingabegeräte über `FakeStereoRecorder.devices` vorgeben, An-/Abstecken mit `emitDeviceChange()` simulieren. Für Dateizugriffe `recordingsDirectoryProvider` auf ein Temp-Verzeichnis überschreiben. Die app-weite Eingabegerät-Auswahl liegt ohne Override in `MemoryInputChoiceStore`; eine gespeicherte Auswahl vom letzten Start per `inputChoiceStoreProvider.overrideWithValue(MemoryInputChoiceStore(...))` vorgeben. Datensammler: `collectionStorageProvider` auf ein Temp-Verzeichnis, `clipPlayerProvider` auf einen Fake (`ClipPlayer`), `collectExportDirectoryProvider` und `fileSharerProvider` überschreiben. Widget-Tests mit echten Dateizugriffen brauchen `tester.runAsync` mit kurzer Verzögerung im Wechsel mit `pump`; der gestreamte ZIP-Export braucht viele Runden (in einer Schleife bis zum Ergebnis warten).
- **Countdown/Zeitabläufe:** Wartezeiten der UI über Provider einstellbar machen (z. B. `calibrationCountdownProvider` mit `tick` in Millisekunden) statt `fake_async`; Widget-Tests tippen dann in `tester.runAsync` und warten auf den Provider-Zustand (Beispiel `tests/ui/calibration/calibration_wizard_test.dart`).
- **Datenbank:** drift mit In-Memory-Datenbank (`NativeDatabase.memory()`). Migrationen prüft man mit einer Datei-Datenbank, aus der die neue Spalte per `ALTER TABLE … DROP COLUMN` entfernt und `PRAGMA user_version` zurückgesetzt wird (Beispiele `tests/data/passes_test.dart`, `tests/data/series_resume_repository_test.dart`, `tests/data/learned_spacing_repository_test.dart`).
- **Fortsetzen/USB:** `tests/ui/series/series_resume_test.dart` (Controller mit `FakeStereoRecorder`, `devices` für USB-Geräte), `tests/ui/series/series_resume_screen_test.dart` (Bildschirm mit überschriebenem `seriesRecordingProvider`).
- **Simulation:** Fahrzeuge für Tests mit `Scenarios.combustion/electric` bzw. `VehiclePass(..., audibleSpanS:)` erzeugen; `audibleSpanS` begrenzt die Rechenzeit langer Szenarien. Ganze Auswertungen: `evaluateSignalFull` (Offline-Referenz) oder `LivePipeline`.
- **Mehrere Fahrzeuge:** `tests/data/multi_vehicle_test.dart` (Kolonne, Gegenverkehr, Spiegelspur, Zufallsverkehr mit `TrafficGenerator(minGapS:, meanExtraGapS:)`) prüft Zählung und Geschwindigkeit gegen `GroundTruth`. Erwartung dort: jedes Fahrzeug genau ein Datensatz, kein Datensatz ohne Fahrzeug. Bei Änderungen an Ereigniserkennung, `motion_fit.dart` oder `event_evaluator.dart` zusätzlich zu `tests/core/` auch `tests/data/` ausführen.
- **Zeichenkodierung:** Dateien nie mit PowerShell 5.1 `Get-Content`/`Set-Content` ohne `-Encoding utf8` umschreiben: Das liest UTF-8 als ANSI und schreibt Umlaute doppelt kodiert zurück („GerÃ¤t“). `tests/ui/device/input_device_selection_test.dart` prüft die Beschriftungen darauf.
- **Windows:** `build/unit_test_assets`, `.dart_tool/build/generated` und `build/app/intermediates` sind gelegentlich gesperrt. Ordner löschen (bei APK-Builds vorher `android/gradlew.bat --stop`) und den Befehl wiederholen.
- **Testdaten:**
  - Synthetische Vorbeifahrten aus dem Generator in `lib/core/` (Roadmap Task_02) sind die Standard-Fixtures. Sie werden im Test erzeugt und nicht als Datei abgelegt.
  - Echte Aufnahmen nur als kurze Ausschnitte (wenige Sekunden) unter `tests/fixtures/`. Große Rohaufnahmen werden nicht versioniert.
  - Vorhandene Ausschnitte (Fenstersims, 2026-11-23, 48 kHz Stereo, 4 bis 5 s): `fenster_auto_011.wav` (Auto, Richtung −1), `fenster_auto_003.wav` (Auto, Richtung +1, ohne Ton), `fenster_kein_auto_024.wav` (Nachklang eines Autos, kein Fahrzeug). `tests/data/real_recordings_test.dart` wertet sie mit `evaluateClip` aus. Es gibt keine Referenzgeschwindigkeit: Die Tests prüfen Fahrzeug ja/nein, Richtung und dass kein Doppler-Wert erfunden wird, nicht die Geschwindigkeit. Neue Ausschnitte mit Python `wave` oder `readWavStereoRange` schneiden; der Test liest sie relativ zum Projekt-Root (`tests/fixtures/…`).
- **Gelabelte Sammlungen:** Ein Export aus dem Tab „Sammeln“ (Ordner mit `collection.json` und Clips) lässt sich am PC gegen die Markierungen auswerten: `fvm dart run tool/evaluate_collection.dart <ordner> --abstand 3 --hoehe 2.5 --temperatur 2 --b 0.15 --b-schaetzen`. Ausgabe: je Clip Klasse, Richtung, Geschwindigkeit, Grund, dazu Autos mit Geschwindigkeit, falsche Fahrzeuge und der aus den Vorbeifahrten gelernte Mikrofonabstand. Die Logik liegt in `lib/data/collection_evaluation.dart` (`evaluateCollection`, `evaluateClip`), Test `tests/data/collection_evaluation_test.dart` baut eine synthetische Sammlung in einem Temp-Ordner. Bei Änderungen an der Auswertung das Werkzeug auf einer echten Sammlung laufen lassen und das Ergebnis mit `docs/method-notes.md` („Erste echte Aufnahmen“) vergleichen.
  - Rechenintensive Tests: kurze Szenarien wählen, damit die Suite schnell bleibt. Beispiel `tests/data/series_spacing_learning_test.dart`: drei Vorbeifahrten statt fünf (`plateauMinCount: 3`), Doppler-Variante 2 aus, grobes Spektrogramm. Die Tests `live_pipeline_test` und `series_analysis_test` brauchen einzeln 10 bis 16 s bei 30 s Zeitlimit und fallen aus, wenn parallel viel gerechnet wird; neue Tests in `tests/data/` deshalb klein halten.

---
Pflege: Bei Änderungen an Testing-Suite oder -Strategie diese Datei sofort aktualisieren.

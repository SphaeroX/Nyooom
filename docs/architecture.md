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
- `lib/data/`: drift-Datenbank, Repositories, Dateiablage der Messreihen, gespeicherte Eingabegerät-Auswahl.
- `lib/ui/`: Screens, Widgets, Riverpod-Provider.
- `android/`: Flutter-Host und Kotlin-Plugin-Code.

Alle Parameter aus `technik.pdf` 9.2 liegen in **einem** Konfigurationsobjekt (JSON-serialisierbar), nicht als Literale im Code. Die ausgelieferte Datei `assets/nyooom_config.json` wird mit `fvm dart run tool/write_default_config.dart` aus den Defaults erzeugt; ein Test hält beide gleich.

**Kanal- und Vorzeichenkonvention:** linker Kanal = Mikrofon bei x = −b/2, rechter Kanal = Mikrofon bei x = +b/2. Δ ist Ankunft links minus Ankunft rechts, also Δ = +b/c·u + Δ0; positive Geschwindigkeit bedeutet Fahrt in +x-Richtung (von links nach rechts).

## Umgebung

- Flutter immer über FVM aufrufen: `fvm flutter …`, `fvm dart …`. Nie das global installierte Flutter verwenden (dort ist eine andere Version aktiv).
- `fvm` liegt unter `%LOCALAPPDATA%\Pub\Cache\bin`; dieser Ordner muss im PATH sein.
- `.fvm/` wird nicht versioniert. Der Symlink `.fvm/versions/3.50.0` für die IDE braucht unter Windows den Entwicklermodus; `fvm flutter` funktioniert auch ohne ihn.
- Abhängigkeiten nur über `fvm flutter pub add`, keine anderen Paketmanager.
- Einziger externer Dienst: Open-Meteo (`api.open-meteo.com`, kostenlos, ohne Schlüssel) für die Außentemperatur. Gesendet wird nur die auf zwei Nachkommastellen (ca. 1 km) gerundete Position, und nur, wenn der Nutzer die Temperatur per GPS holt oder die automatische Aktualisierung an ist. Dafür braucht die App `android.permission.INTERNET`. Keine Secrets, deshalb keine `.env`.

## Auswertung mehrerer Fahrzeuge

Die App wertet nicht nach dem Buchstaben von `technik.pdf` 5.1 aus (ein Ergebnis pro Fenster, Überlappung gleich Klasse C), sondern mit Spurtrennung im Korrelogramm. Der Ablauf in allen drei Wegen (`LivePipeline`, `runSeriesAnalysis`, `evaluateSignalFull`) ist derselbe:

1. `EventDetector(secondaryEvents: true)` meldet jedes ausgeprägte Pegelmaximum als Ereignis.
2. `EventPipeline.evaluateAll` liefert pro Ereignis null bis zwei Datensätze (`EventEvaluator.analyseTracks`, danach Doppler und Fusion je Spur).
3. `TrackDeduplicator` entfernt Wiederholungen desselben Fahrzeugs aus überlappenden Fenstern.

`detectEvents`, `EventEvaluator.analyse` und `EventPipeline.evaluate` bilden weiter die PDF-Regel ab und dienen Tests und Vergleichen. Begründung und Grenzen: [method-notes.md](method-notes.md).

## Projektstruktur (Stand Konzeptprüfung nach Task_19)

```
lib/
  main.dart                         App-Einstieg (ProviderScope, MaterialApp)
  core/config/nyooom_config.dart    Konfigurationsobjekt mit allen 9.2-Parametern (JSON); Kopie in assets/nyooom_config.json
  core/model/acoustics.dart         c(T), Schrägabstand, km/h-Umrechnung
  core/model/passby_model.dart      PassByModel: u, r, t = te + r/c, Δ(t), Doppler (technik.pdf 3.1–3.4)
  core/dsp/fft.dart                 radix-2-FFT, Hann-Fenster, Blockzerlegung
  core/dsp/gcc_phat.dart            GCC-PHAT, Correlogram, singleTdoa (technik.pdf 5.2)
  core/dsp/spectrogram.dart         Spektrogramm (technik.pdf 5.4), Spitzenfrequenz mit Parabelinterpolation
  core/dsp/biquad.dart              IIR-Filter (Butterworth Hoch-/Tiefpass, Bandpass-Kette)
  core/dsp/fractional_delay.dart    Kaiser-gefensterter Sinc-Interpolator für Bruchteil-Verzögerungen
  core/sim/passby_simulator.dart    Generator synthetischer Vorbeifahrten mit GroundTruth
  core/sim/scenarios.dart           Fixture-Fabrik: Verbrenner, Elektroauto, Standard-Setups
  core/sim/traffic.dart             TrafficGenerator: deterministischer Mischverkehr für die Simulationsquelle
  core/calibration/device_checks.dart  Eignungsprüfung 4.4 und Kalibrierung 7.1 (reine Logik)
  core/calibration/self_calibration.dart  Selbstkalibrierung der Spurabstände (technik.pdf 7.4)
  core/calibration/plateau_calibration.dart  wirksamer Mikrofonabstand b und Δ0 aus den Plateaus der Laufzeitkurve einer Vorbeifahrt; judgeSpacing entscheidet, ob der Median einer Messreihe die Kalibrierung ersetzt
  core/sim/calibration_signals.dart Klatschen in Achsrichtung, Dauerrauschen (mit simulierter AGC)
  core/events/event_detector.dart   Ereigniserkennung blockweise (technik.pdf 5.1), wahlweise mit Nebenmaxima als eigenen Ereignissen
  core/inspection/                  Pegelverlauf, Heatmap-Renderer (RGBA), Daten der Sichtprüfung
  core/pipeline/motion_fit.dart     Grobsuche + robuste Feinanpassung von κ, t0 (technik.pdf 5.3); Maxima neben der Kurve, Suche mit ausgeblendeten Spuren
  core/pipeline/reasons.dart        Gründe für Klasse B/C (Code + Text)
  core/pipeline/event_evaluator.dart  Laufzeitauswertung eines Ereignisfensters (v_T, σ_T, Klasse B/C); `analyseTracks` trennt mehrere Fahrzeuge
  core/pipeline/track_dedup.dart    TrackDeduplicator: dasselbe Fahrzeug aus zwei Fenstern nur einmal
  core/pipeline/doppler.dart        Doppler Variante 1: Tonspuren + Regression mit bekanntem u(t) (technik.pdf 5.4), Abstandsprüfung je Tonspur (ToneGate)
  core/pipeline/doppler_sharpness.dart  Doppler Variante 2: Entzerrung und Schärfemaximum mit Gegenprobe (falsch herum entzerrt), Kombinationsregel
  core/pipeline/fusion.dart         Beschleunigungs-/Abstandsprüfung, gewichtete Fusion, Klassenlogik (5.4–5.6)
  core/pipeline/least_squares.dart  allgemeiner Levenberg-Marquardt-Löser mit Kovarianz
  core/pipeline/joint_fit.dart      gemeinsame Ausgleichsrechnung über v, d, t0, f0_k (Option)
  core/pipeline/pass_record.dart    Datensatz nach technik.pdf 9.1
  core/pipeline/analysis_setup.dart Auswertekonstanten einer Messreihe (b, Δ0, Tausch, c, Spuren, Temperaturverlauf; `speedOfSoundAt`/`atOffset` für c an einer Signalposition)
  core/series/temperature_log.dart  Temperaturwerte über die Aufnahme (Signalposition, °C, Uhrzeit, Quelle `start`/`gps`)
  core/weather/open_meteo.dart      Anfrage-URL (Koordinaten auf 2 Nachkommastellen) und Antwort-Parser für Open-Meteo
  core/export/                      CSV (9.1 plus `audio_pos_s`/`audio_pos`: Position von t0 in der WAV), JSON-Export, ZIP-Writer
  core/reference/                   Referenzfahrten: GPX/CSV-Leser, Logger, abgeleitete Geschwindigkeit
  core/validation/                  Zuordnung Referenz ↔ Messung, Fehlerkennzahlen, Abnahmeprüfung (technik.pdf 8)
  core/stats/statistics.dart        Median, V85, Anteil über Limit, Korrektur 8.3, Gruppierung, Histogramm
  core/site/site.dart               SiteSpec/LaneSpec, Schrägabstand je Spur, Validierung (technik.pdf 4.1)
  core/series/series_metadata.dart  Inhalt von metadata.json einer Messreihe (mit Eingabegerät und Abschnitten)
  core/series/recording_segment.dart  Aufnahmeabschnitte einer fortgesetzten Messreihe, Uhrzeit zu Signalposition
  audio/simulated_stereo_recorder.dart  StereoRecorder mit synthetischem Verkehr (Isolate-Rendering, Echtzeit-Takt)
  audio/capture.dart                Aufnahme fester Dauer, CalibrationCapture (echt/simuliert)
  data/database.dart                drift-Schema (Devices, Calibrations, Sites, Lanes, MeasurementSeries, Passes, ReferenceTracks, ReferencePoints), Version 7
  data/outdoor_temperature.dart     Außentemperatur: GPS-Position (geolocator) → Open-Meteo über `dart:io` HttpClient (`GpsOutdoorTemperatureService`)
  data/repository.dart              NyooomRepository
  data/event_pipeline.dart          EventPipeline: vollständige Auswertung eines Ereignisfensters (offline und live), `evaluateAll` für alle Fahrzeuge des Fensters
  data/live_pipeline.dart           Live-Auswertung: Ringpuffer, Worker-Isolate, Warteschlange
  data/series_analysis.dart         Datei-Auswertung in 1-s-Stücken, Hintergrund-Isolate mit Fortschritt; lernt auf Wunsch b und Δ0 aus den Vorbeifahrten (learnSeriesSpacing)
  data/collection_evaluation.dart   wertet die Clips einer gelabelten Sammlung aus (evaluateCollection, evaluateClip, evaluateStoredClip für einen gespeicherten Clip) und vergleicht mit den Markierungen
  data/series_export.dart           Export einer Messreihe in Dateien bzw. ZIP (gestreamt)
  data/series_storage.dart          Dateiablage <Dokumente>/series/<id>/{audio.wav, metadata.json}
  data/onboarding_store.dart        Merker-Datei <Dokumente>/onboarding_done (Einführung gesehen)
  ui/providers.dart                 zentrale Riverpod-Provider (DB, Repository, Ablage, Recorder-Fabrik)
  ui/home/                          HomeScreen mit Tabs (homeTabsProvider)
  ui/help/                          Einführung beim ersten Start (OnboardingGate in main.dart), Tab "Hilfe" mit Schritt-für-Schritt-Anleitung
  ui/sites/                         Standortliste und -formular
  ui/evaluation/                    Auswertung starten, Ergebnisliste, Detail einer Vorbeifahrt, Karten zu gelerntem Mikrofonabstand (SpacingLearningCard) und Spurabstand (SelfCalibrationCard)
  ui/reference/                     Tab "Referenz": Logger, Import, Verlauf
  ui/validation/                    Validierung mit Ampel und Streudiagramm
  ui/export/                        Teilen-Buttons (share_plus)
  ui/stats/                         Statistik-Bildschirm (Tabellen, Histogramm)
  ui/inspection/                    Sichtprüfung (Korrelogramm, Spektrogramm, Modellkurve)
  ui/common/                        RgbaImageView
  ui/calibration/                   Tab "Gerät", Kalibrier-Assistent (CalibrationController)
  ui/device/                        Eingabegeräte-Auswahl (InputDeviceSelector im Tab Gerät, InputDeviceHint auf Aufnahme-Bildschirmen, inputDevicesProvider, activeInputDeviceProvider, inputChoiceStoreProvider)
  ui/series/                        Messreihenliste, Start, Aufnahme (SeriesRecordingController), Detailansicht
  ui/weather/                       outdoorTemperatureServiceProvider, temperatureRefreshIntervalProvider (15 min), GpsTemperatureButton (Startbildschirm, Kalibrier-Assistent)
  ui/collect/                       Tab "Sammeln": Sammlungen, freie Aufnahme (CollectController), Clips anhören und markieren (ClipLabelScreen, optional ab initialIndex), Clips aus Messreihe (CollectFromSeriesSection), seriesClipsProvider (Sammlung einer Messreihe)
  ui/series/series_clips_section.dart  Detailansicht der Messreihe: Clips der Reihe abspielen, zum Markieren öffnen und einzeln auswerten (clipAnalyzerProvider: learnedSetup der Reihe, evaluateClip im Hintergrund-Isolate); ohne Clips der Knopf aus CollectFromSeriesSection
  core/collect/clip_collector.dart  schneidet das Auswertefenster jedes erkannten Ereignisses (EventDetector) als Clip aus einem laufenden Strom
  core/collect/collection_manifest.dart  collection.json (Clips, Markierung auto/kein_auto/unklar/offen) und labels.csv
  data/collection_storage.dart      Ablage <App-Dokumente>/collections/<id>/clip_NNN.wav + collection.json, ZIP-Export, collectFromWav (Messreihe → Clips), LiveClipCollection (Clips einer laufenden Aufnahme, genutzt vom Datensammler und von Messreihen mit „Clips“), forSeries/seriesCollectionSource (Sammlung mit `source` = `messreihe <id>`)
  audio/clip_player.dart            Wiedergabe der Clips: ClipPlayer, PlatformClipPlayer (Kotlin-Plugin), AudioplayersClipPlayer (PC)
  audio/desktop_stereo_recorder.dart  StereoRecorder für den PC (Paket record, ersetzbares DesktopAudioBackend)
  audio/platform_audio.dart         Auswahl von Recorder und Player je Plattform
  core/signal/pcm.dart              StereoBlock, De-/Interleaving (PCM16, Float32)
  core/signal/level.dart            RMS/Peak in dBFS, Clipping-Erkennung
  core/signal/stereo_content.dart   Stereo-Inhalt: identisch (Mono), ein Kanal stumm, echtes Stereo
  audio/stereo_recorder.dart        Dart-Seite des Kotlin-Plugins (Channels, Fähigkeiten, RecordingInfo, InputDevice)
  audio/input_devices.dart          Auswahl-Logik der Eingabegeräte (Filter, Kalibrier-Name, Wiedererkennung nach Neustecken)
  audio/wav.dart                    WAV-Encoder/-Decoder (16 Bit PCM) und streamender WavFileWriter
  ui/recorder/                      RecorderController (Riverpod Notifier) und RecorderScreen
android/app/src/main/kotlin/de/nyooom/app/
  MainActivity.kt                   registriert NyooomAudioPlugin
  NyooomAudioPlugin.kt              AudioRecord-Aufnahme, Berechtigung, Effekte
  ClipPlayback.kt                   MediaPlayer-Wiedergabe der Sammel-Clips (eigener MethodChannel)
```

- Plattformen: Android (Messgerät) und Windows-Desktop (`windows/`, `fvm flutter build windows`). `lib/audio/platform_audio.dart` wählt nach `Platform.isAndroid`: Android nimmt über das Kotlin-Plugin auf und spielt darüber ab, der PC über `DesktopStereoRecorder` (Paket `record`, PCM16 Stereo, AGC/Echo/Rauschunterdrückung aus) und `AudioplayersClipPlayer` (Paket `audioplayers`). Der PC meldet keine An-/Absteck-Ereignisse (Liste über den Aktualisieren-Knopf), Eingänge haben den Typ `desktopInputType` („PC“) und gelten als extern, damit Kalibrierung und Messreihe denselben Gerätenamen verwenden. Viele PC-Mikrofone sind mono und werden von Windows auf zwei Kanäle verdoppelt; das zeigt die Stereo-Prüfung im Pegeltest. Der Windows-Build braucht den Entwicklermodus (Symlinks für Plugins) und Visual Studio mit C++.
- Werkzeuge am PC (`tool/`, reines Dart, Aufruf `fvm dart run tool/<name>.dart`): `write_default_config.dart` schreibt `assets/nyooom_config.json`, `evaluate_collection.dart` wertet eine exportierte Sammlung gegen ihre Markierungen aus (Optionen im Dateikopf, siehe `docs/testing.md`).
- Das Kotlin-Plugin liegt im App-Modul (kein eigenes Plugin-Paket) und wird in `MainActivity.configureFlutterEngine` registriert.
- Flutter 3.50 liefert Material als eigenes Paket: Widgets kommen aus `package:material_ui/material_ui.dart` (nicht `package:flutter/material.dart`).
- Abhängigkeiten: `flutter_riverpod`, `path_provider` (App-Dokumentordner), `drift` + `drift_flutter` (SQLite, Datenhaltung laut Roadmap), `share_plus` (Android-Teilen-Dialog für Exporte), `geolocator` (GPS-Logger für Referenzfahrten, Position für die Außentemperatur), `file_picker` (GPX/CSV-Import), `record` (Aufnahme am PC), `audioplayers` (Clip-Wiedergabe am PC), dev: `test`, `drift_dev`, `build_runner`, `archive` (nur zum Prüfen der ZIP-Exporte in Tests) (Code-Generierung `fvm dart run build_runner build -d`).
- Simulationsquelle: Beim Start einer Messreihe kann statt der Mikrofone `SimulatedStereoRecorder` gewählt werden (synthetischer Verkehr aus `lib/core/sim/`). Damit läuft die App im Emulator und ohne geeignetes Gerät. Standard ist seit Task_20 das Mikrofon (`simulationDefaultProvider` = false); die Simulation wird im Startbildschirm eingeschaltet.
- Kalibrier-Assistent (`CalibrationScreen`): sechs Seiten für Laien (Willkommen mit Temperatur, Handy aufstellen, rechts klatschen, links klatschen, konstantes Signal optional/überspringbar, Ergebnis mit Speichern). „Weiter" ist gesperrt, bis `CalibrationController.stepPassed` den Schritt bestätigt. Vor jeder Aufnahme läuft ein Countdown (`calibrationCountdownProvider`, Standard 5 s), damit man ca. 3 m zur Klatschposition gehen kann; die Klatsch-Aufnahmen dauern 5 s. Countdown (orange) und Aufnahme (grün) füllen den Bildschirm, damit sie aus 3 m lesbar sind. Bewusst kein Piepton und keine Vibration: beides würde als Transiente in der Aufnahme landen.
- Eingabegerät einer Messreihe: Der Startbildschirm bietet „Mikrofon“ an (eingebaut oder ein externes Gerät aus `getInputDevices`); ein externes Gerät mit zwei Kanälen wird vorausgewählt (`preferredInputDevice`). `SeriesStartRequest.inputDevice` geht als `inputDeviceId` an das Plugin. Gerätezeile und Kalibrierung hängen an Modell **und** Eingabegerät (`devices.input_device`: `intern` oder Gerätename), deshalb braucht ein USB-Mikrofon eine eigene Kalibrierung. Der Aufnahmebildschirm zeigt `RecordingInfo.preferredDevice` und warnt, wenn Android das gewählte Gerät nicht übernommen hat.
- Mikrofonabstand aus den Vorbeifahrten: `EvaluationController.run` wertet mit `analyseSeriesInBackground(learnSpacing: true)` aus, ausgehend von der Kalibrierung (`repo.learnedSetup(…, learnedSpacing: false)`), und speichert das Ergebnis mit `repo.setLearnedSpacing` an der Messreihe (Schema 6, drei Spalten `learned_…`, null = Kalibrierung gilt). `repo.analysisSetup(id)` liefert danach den gelernten Wert. Regeln und Grenzen in `docs/method-notes.md`.
- Fortsetzen einer Messreihe (`SeriesRecordingController.resume`): nach „Aufnahme beenden“ oder aus der Detailansicht. Die WAV wird mit `WavFileWriter.append` weitergeschrieben (auch ohne finalisierten Kopf), die Live-Auswertung startet mit `LivePipeline(startOffsetS:)` an der bisherigen Signalposition, sodass `offsetS` sich weiter auf die Datei bezieht. Jede Fortsetzung legt einen `RecordingSegment` (Signalposition, Uhrzeit) an: Spalte `measurement_series.segments_json` (Schema 5, null = ein Abschnitt) und `metadata.json` → `segments`. `AnalysisSetup.utcMsAt` rechnet damit die Uhrzeit der Vorbeifahrten, `StoredSeries.durationS` zählt die Pausen nicht mit. Das Eingabegerät wird beim Fortsetzen über den Namen wiedergefunden; ist es nicht angesteckt, bricht `resume` mit Meldung ab.
- Außentemperatur per GPS: Das Standort-Symbol im Temperaturfeld (Startbildschirm, Kalibrier-Assistent) holt über `outdoorTemperatureServiceProvider` die aktuelle 2-m-Temperatur am Standort (Handys haben keinen Außentemperatursensor). Danach erscheint im Startbildschirm „Alle 15 min per GPS aktualisieren“ (vorausgewählt, bei Simulation aus). `SeriesStartRequest.autoUpdateTemperature` startet im `SeriesRecordingController` einen Timer (`temperatureRefreshIntervalProvider`); jeder neue Wert gilt ab der aktuellen Signalposition: `repo.addTemperatureReading` (Spalte `measurement_series.temperature_log_json`, Schema 7, der erste Eintrag ist der Startwert bei 0 s, gleiche Werte werden nicht wiederholt) und `LivePipeline.addTemperatureReading` (schickt das neue Setup an das Worker-Isolate). `EventPipeline` wertet jedes Ereignisfenster mit c der Temperatur an seinem Fensteranfang aus (`AnalysisSetup.atOffset`), live wie in der Datei-Auswertung. `temperatureC`/`speedOfSound` der Messreihe bleiben der Startwert. Fehlschläge (kein GPS, kein Netz) behalten den letzten Wert, der Aufnahmebildschirm zeigt den Grund. `metadata.json` enthält `temperatureAutoUpdate` und nach dem Beenden `temperatureLog`; „Weiter aufnehmen“ holt bei automatischer Aktualisierung sofort einen neuen Wert. Die Mikrofonabstand-Lernrunde (`learnSeriesSpacing`) rechnet weiter mit dem Start-c.
- Schnelltest: Ohne Standort bietet der Startbildschirm `quickTestSite()` an (`lib/core/site/site.dart`, Spuren 5 m → und 8 m ←, Höhe 1,5 m). Ohne Kalibrierung gelten b = 0,15 m und Δ0 = 0. Geschwindigkeiten skalieren mit dem angenommenen Abstand, Erkennung und Zählung nicht.

## Plattform-Schnittstelle Aufnahme

- MethodChannel `de.nyooom/audio`:
  - `getCapabilities` → `{unprocessedSupported, agcAvailable, nsAvailable, aecAvailable, deviceModel, sdkInt, microphones: [String]}`
  - `start {sampleRate}` → `{audioSource: "UNPROCESSED"|"VOICE_RECOGNITION", sampleRate, channels, effects: {agc, ns, aec: "unavailable"|"disabled"|"enabled"}, activeMicrophones: [String]}`; fragt bei Bedarf die Mikrofon-Berechtigung an. Fehlercodes: `PERMISSION_DENIED`, `INIT_FAILED`, `ALREADY_RUNNING`, `BUSY`.
  - `getInputDevices` → `[{id, name, type, isExternal, channelCounts, sampleRates, channelMasks, channelIndexMasks}]` (`AudioManager.getDevices(GET_DEVICES_INPUTS)`)
  - `start` akzeptiert zusätzlich `inputDeviceId` (→ `AudioRecord.setPreferredDevice`, z. B. USB-Stereo-Interface, technik.pdf 4.3); Antwort enthält `preferredDevice` sowie `routedDevice`/`routedDeviceId` (`AudioRecord.getRoutedDevice`, das Gerät, von dem Android tatsächlich aufnimmt).
  - Plattform → Dart: `inputDevicesChanged` (ohne Argumente), sobald ein Eingabegerät angeschlossen oder entfernt wird (`AudioDeviceCallback`). Bewusst über den MethodChannel statt eines eigenen EventChannels: Ohne Plugin (Tests, andere Plattformen) bleibt das still, ein fehlender EventChannel würde einen Fehler melden.
  - `stop`
- Während einer Aufnahme setzt das Plugin `FLAG_KEEP_SCREEN_ON` am Activity-Fenster und nimmt es bei `stop` wieder weg. Grund: Es gibt keinen Foreground-Service (Task_04), und Android schaltet das Mikrofon stumm, sobald die App nicht mehr sichtbar ist.
- MethodChannel `de.nyooom/playback` (`ClipPlayback.kt`, Datensammler): `playFile {path}` spielt eine WAV-Datei mit `MediaPlayer` ab (ersetzt eine laufende Wiedergabe), `stopPlayback`; Plattform → Dart `playbackCompleted` am Ende eines Clips. Eigener Kanal, damit der Rückruf-Handler nicht den von `inputDevicesChanged` ersetzt. Bewusst ohne Audio-Paket: keine neue Abhängigkeit.
- EventChannel `de.nyooom/audio_stream`: `Uint8List`-Blöcke (ca. 20 ms), interleaved 16 Bit little-endian, L/R in der Reihenfolge von `CHANNEL_IN_STEREO`. Vor `start` abonnieren.
- Eingabegerät: Ausgewählt wird nur im Tab „Gerät“ (`InputDeviceSelector`); die Auswahl gilt app-weit (`inputDeviceChoiceProvider`) für Pegeltest, Kalibrierung und Messreihen. Diese Bildschirme zeigen nur `InputDeviceHint` (aktuelles Gerät plus Warnungen: nicht verbunden, nur Mono). Die Auswahl bleibt über App-Neustarts erhalten: `main` setzt `inputChoiceStoreProvider` auf `FileInputChoiceStore` (`input_device.json` im App-Dokumentenverzeichnis, `lib/data/input_choice_store.dart`); ohne diese Verdrahtung (Tests) hält `MemoryInputChoiceStore` sie nur im Speicher. Eine Aufnahme wartet über `readActiveInputDevice` auf das Einlesen der gespeicherten Auswahl. „Interne Mikrofone (Standard)“ öffnet Android ohne bevorzugtes Gerät; die eingebauten Mikrofone stehen deshalb nicht einzeln in der Liste, ebenso keine Systemquellen (Telefonie, Submix, Echo-Referenz, Tuner). Externe Geräte stehen zuerst. Nach dem Neustecken vergibt Android eine neue Id; die Auswahl folgt dem Gerät über Name und Typ, solange es fehlt, wird intern aufgenommen und die Auswahl zeigt einen Hinweis.
- Stereo-Nachweis: Die Auswahl zeigt, was Android über das Gerät meldet (`InputDevice.reportedFormat`, Kanäle und Abtastraten), ohne es zu sperren. Der Pegeltest bewertet jede Sekunde den Inhalt beider Kanäle (`RecorderState.stereoContent`, `analyseStereoContent`); siehe `docs/method-notes.md`, „Externe Mikrofone“. `getInputDevices` liefert zusätzlich `sampleRates`, `channelMasks`, `channelIndexMasks`; das Plugin schreibt jedes Gerät ins Logcat (Tag `NyooomAudio`).
- Kalibrierungen gelten je Telefonmodell und Eingabegerät (`Devices.model` + `Devices.inputDevice`: `intern` oder Produktname des Geräts). Eine Messreihe übernimmt die Kalibrierung des gewählten Eingabegeräts; `metadata.json` enthält `inputDevice`.
- Rohaufnahmen landen als `nyooom_YYYYMMDD_HHMMSS.wav` in `<App-Dokumentordner>/recordings/`.

## Offene Entscheidungen

- Zielgerätemodell (Roadmap Task_01/05).
- Ob reines Dart auf dem Zielgerät schnell genug ist: am PC ca. 1 s pro Ereignis, Messung auf dem Gerät in Roadmap Task_20. Eine neue Sprache (C++/FFI) nur nach Rückfrage.

## Release (GitHub Actions)

- `.github/workflows/release.yml` baut bei einem Tag `v*` (oder manuell mit Tag-Angabe) die Release-APK, führt vorher `flutter test tests/` aus und veröffentlicht `nyooom-<tag>.apk` als GitHub-Release.
- CI nutzt `subosito/flutter-action` mit derselben Version wie `.fvmrc` (3.50.0), nicht FVM. Bei einem Versionswechsel beide Stellen anpassen.
- Versionsname kommt aus dem Tag (`v0.1.0` → `0.1.0`), Build-Nummer aus der Laufnummer.
- Signatur: Debug-Schlüssel des CI-Runners (wie lokal, `android/app/build.gradle.kts`). Jeder Lauf hat einen anderen Schlüssel, ein Update über eine ältere Installation kann deshalb an der Signatur scheitern; dann alte Version deinstallieren. Ein eigener Release-Schlüssel (als Repository-Secret) ist noch nicht eingerichtet.

---
Pflege: Bei Änderungen an Stack oder Architektur diese Datei sofort aktualisieren.

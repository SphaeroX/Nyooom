# Nyooom – Roadmap

Projektübergreifendes Gedächtnis. Agenten lesen diese Datei vor jedem Task und aktualisieren sie, wenn sich etwas ergibt, das über einen einzelnen Task hinausgeht. Regeln für die Arbeit: [AGENTS.md](AGENTS.md).

## Projektziel

Nyooom ist eine Android-App (Flutter, iOS später möglich), die die Geschwindigkeit einzeln vorbeifahrender Fahrzeuge allein aus der Stereo-Aufnahme der beiden eingebauten Smartphone-Mikrofone schätzt. Grundlage ist das Messverfahren aus `technik.pdf` im Projekt-Root ("Akustische Geschwindigkeitsmessung: Methodik für den Prototyp"): Laufzeitdifferenz (GCC-PHAT) und Doppler-Verschiebung, fusioniert über den Richtungskosinus u(t), mit Qualitätsklassen A, B und C. Das Ergebnis dient einer Statistik über eine Straße, nicht dem Nachweis einzelner Verstöße.

**Was die Software tut:** Die App prüft, ob ein Smartphone echtes, unbearbeitetes Stereo liefert, und kalibriert den effektiven Mikrofonabstand b und den Kanalversatz Δ0. Sie legt Messreihen mit Standortdaten an (Spurabstände, Mikrofonhöhe, Temperatur, Zuordnung Fahrtrichtung → Spur), nimmt 48-kHz-Stereo auf, erkennt Vorbeifahrten live und berechnet pro Fahrzeug einen Datensatz (Abschnitt 9.1 der PDF). Daraus entstehen Statistiken (Median, V85, Anteil über dem Limit, getrennt nach Klasse A/B), ein CSV/JSON-Export und ein Abgleich mit GPS-Referenzfahrten zur Validierung (Abschnitt 8).

**Zielgruppe:** Der Entwickler selbst und Personen, die Verkehrsstatistiken für eine Straße erheben wollen; Bedienung am Straßenrand mit Smartphone auf Stativ.

**Nicht-Ziele:** Nachweis einzelner Verstöße; iOS-Umsetzung in dieser Roadmap (Architektur soll iOS aber nicht verbauen); Cloud, Backend oder Nutzerkonten; eine separate Python-Auswertung am PC (die PDF schlägt sie vor, es wurde bewusst entschieden, alles direkt in der App umzusetzen).

## Aktueller Status

Stand: 2026-11-16 – Task_18 läuft. Gerätetests sind gesammelt nach Task_20 verschoben (siehe unten).

| Task | Titel | Status |
|---|---|---|
| 01 | Durchstich: Stereo-Rohaufnahme | erledigt (Gerätetest → 20) |
| 02 | Signalmodell und synthetische Vorbeifahrten | erledigt |
| 03 | DSP-Kern und GCC-PHAT-Laufzeitspur | erledigt |
| 04 | Messreihe anlegen und aufnehmen | erledigt |
| 05 | Geräteeignung und Kalibrierung | erledigt (Gerätetest → 20) |
| 06 | Sichtprüfung: Korrelogramm und Spektrogramm | erledigt (Entscheidung → 20) |
| 07 | Ereigniserkennung | erledigt |
| 08 | Anpassung des Bewegungsmodells | erledigt |
| 09 | Laufzeitmessung Ende zu Ende (Klasse B/C) | erledigt |
| 10 | Doppler Variante 1: Linienverfolgung | erledigt |
| 11 | Beschleunigungsprüfung, Fusion, Klasse A | erledigt |
| 12 | Live-Auswertung | erledigt (Gerätemessung → 20) |
| 13 | Statistik | erledigt |
| 14 | Export | erledigt |
| 15 | GPS-Referenzfahrten | erledigt (Feldtest → 20) |
| 16 | Validierung und Abnahme | erledigt (echte Abnahme → 20) |
| 17 | Doppler Variante 2: Entzerrung | erledigt |
| 18 | Selbstkalibrierung | läuft |
| 19 | Gemeinsame Ausgleichsrechnung | offen |
| 20 | Geräte- und Feldtest | offen |

Status ist `offen`, `läuft` (Datei trägt das Präfix `RUN_`) oder `erledigt` (Datei liegt in `Archiv/`). Die Tabelle wird beim Archivieren eines Tasks aktualisiert.

## Taskübergreifende Entwicklungsinfos

Globale Informationen, Architekturentscheidungen und Wissen, das für das gesamte Projekt gilt. Wird laufend ergänzt; jeden Eintrag mit dem Task kennzeichnen, aus dem er stammt.

**Festgelegt im Roadmap-Interview:**

- **Stack:** Flutter/Dart für App und UI. Die gesamte Signalverarbeitung (FFT, GCC-PHAT, Modellanpassung, Doppler, Fusion, Statistik) ist reines Dart, plattformunabhängig und ohne Flutter-Abhängigkeit testbar.
- **Aufnahme:** Eigenes Kotlin-Plugin (Platform/EventChannel) mit `AudioRecord`, `AudioSource.UNPROCESSED` (Rückfall `VOICE_RECOGNITION`), 48 kHz, `CHANNEL_IN_STEREO`, 16 Bit PCM oder Float; AGC, NoiseSuppressor und AcousticEchoCanceler werden deaktiviert. Hinweise: PDF Abschnitt 4.3.
- **Datenhaltung:** drift (SQLite) für Geräte, Kalibrierungen, Standorte, Messreihen und Vorbeifahrt-Datensätze; Rohaudio als Stereo-WAV plus `metadata.json` im App-Ordner.
- **Konfiguration:** Alle Parameter aus PDF Abschnitt 9.2 stehen in einer Konfigurationsdatei bzw. einem Konfigurationsobjekt, nicht verstreut im Code.
- **Projekt-Setup (project-init):** Flutter 3.50.0 über FVM (`.fvmrc`), alle Befehle als `fvm flutter …`; State-Management Riverpod; Lint `flutter_lints`. Details in `docs/architecture.md` und Root-`AGENTS.md`.
- **Tests:** Ablage in `tests/` im Projekt-Root (nicht Flutters Standard `test/`). DSP-Tests nutzen den synthetischen Vorbeifahrt-Generator aus Task_02. Was nur auf einem echten Gerät prüfbar ist, steht als manuelle Checkliste im jeweiligen Task.
- **UI-Sprache:** Deutsch (Annahme).
- **Fachliche Referenz:** `technik.pdf`. Formeln, Startwerte und Abschnittsnummern in den Tasks beziehen sich darauf.

**Entscheidung des Nutzers (2026-11-16): Simulation statt Gerät während der Entwicklung**

- Es ist kein Android-Gerät angeschlossen. Alle Tasks werden gegen synthetische Daten abgearbeitet; der Generator (Task_02) bietet dafür Fahrzeugprofile **Elektroauto** (breitbandiges Reifenrauschen, optional Warnton) und **Verbrenner** (Rauschen plus Motorharmonische).
- Alles, was nur auf einem echten Gerät, mit echten Vorbeifahrten oder echten Referenzfahrten prüfbar ist, steht gesammelt in `Tasks/Task_20.md` (Geräte- und Feldtest) und wird ganz am Ende durchgeführt. Tasks werden archiviert, sobald alle automatisch prüfbaren Kriterien erfüllt sind; manuelle Kriterien werden im Task mit „→ Task_20“ markiert.
- Die App bekommt eine Simulationsquelle (synthetische Vorbeifahrten statt Mikrofon), damit sie ohne Gerät bzw. im Emulator ausprobiert werden kann.

**Aus Task_01:**

- Flutter 3.50 hat Material ausgelagert: Widgets aus `package:material_ui/material_ui.dart` importieren, nicht `package:flutter/material.dart`. (Task_01)
- `NyooomConfig` (`lib/core/config/nyooom_config.dart`) existiert bereits mit `sampleRate` und `clipThreshold`; Task_02 erweitert genau dieses Objekt, statt ein zweites anzulegen. Der UI-Zugriff läuft über `configProvider`. (Task_01)
- Kanonische Signaldarstellung: `StereoBlock` (`lib/core/signal/pcm.dart`) mit zwei `Float64List`, normiert auf [-1, 1]. WAV lesen über `decodeWav` (`lib/audio/wav.dart`). (Task_01)
- `technik.pdf` lässt sich mit `pdftotext -layout technik.pdf -` (MSYS2, im Bash-PATH) als Text lesen. (Task_01)

**Aus Task_02:**

- Alle Parameter: `NyooomConfig` (`lib/core/config/`), Defaults = PDF 9.2 plus abgeleitete Grenzen (5.1–5.6, 7.4). Neue Parameter dort ergänzen, `tool/write_default_config.dart` neu laufen lassen. (Task_02)
- Signalmodell: `PassByModel` (`lib/core/model/passby_model.dart`) mit `directionCosine(t)`, `tdoa(t)`, `dopplerFrequency(f0, t)`, `emissionTime(t)`; Zeiten ohne Suffix sind Empfangszeiten, `t0` ist Abstrahlzeit. `solveEmissionTime` löst t = te + r/c per Newton (schneller und genauer als Raster + Interpolation). (Task_02)
- Kanalkonvention: links = Mikrofon bei −b/2, rechts bei +b/2, Δ = Ankunft links − rechts = +b/c·u + Δ0. GCC-PHAT mit X_links·X_rechts* liefert genau dieses Δ. (Task_02)
- **Generator-API** (`lib/core/sim/`): `Scenarios.combustion(speedKmh:, distance:, direction:, t0:, tone:, acceleration:, toneLeadS:)`, `Scenarios.electric(..., warningTone:)`, `Scenarios.render(pass, durationS:, snrDb:, channelOffset:, micSpacing:, temperatureC:, seed:)` → `SimulatedRecording{signal: StereoBlock, truths: [GroundTruth]}`. Mehrere Fahrzeuge: `PassBySimulator(Scenarios.setup(...)).render(durationS, [pass1, pass2])`. `GroundTruth.model`/`toneModel` liefern das wahre `PassByModel`, `receptionT0` den Empfangszeitpunkt der größten Annäherung. Rechenzeit: ca. 0,1 s pro Sekunde Signal; in Tests kurze Fenster nehmen. (Task_02)
- Hilfsbausteine: `fractionalSample` (Sinc-Interpolation), `Biquad`/`BiquadChain` (Hochpass, Tiefpass, Bandpass) in `lib/core/dsp/`. (Task_02)

**Aus Task_03:**

- `GccPhat(config:, micSpacing:, speedOfSound:)`: `correlogram(signal, from:, to:)` → `Correlogram` (Zeiten = Blockmitten relativ zu `from`, `peakDelays`, `peakWeights`, `valueAt`), `singleTdoa(signal)` für ganze Stücke. R normiert auf 1 bei perfekter Kohärenz. Laufzeit 8-s-Fenster: 125 ms am Entwicklungsrechner. (Task_03)
- FFT: `Fft.of(n).transform(re, im, inverse:)`, `hannWindow(n)`, `blockStarts(len, block, hop)` in `lib/core/dsp/fft.dart`. (Task_03)

**Aus Task_04:**

- Persistenz: `NyooomDatabase` + `NyooomRepository` (`lib/data/`), Provider in `lib/ui/providers.dart` (`databaseProvider`, `repositoryProvider`, `seriesStorageProvider`, `recorderFactoryProvider`, `sitesProvider`, `seriesListProvider`). Nach Schemaänderung `fvm dart run build_runner build -d` und `schemaVersion` + Migration. (Task_04)
- Simulationsquelle: `SimulatedStereoRecorder(lanes:)` implementiert `StereoRecorder`; `TrafficGenerator` erzeugt deterministischen Mischverkehr (ca. 35 % E-Autos, Verbrenner mit Motorton, einige beschleunigen). `pastTruths` liefert die wahren Werte der bereits vorbeigefahrenen Fahrzeuge (für Vergleichsanzeigen). (Task_04)
- Erweiterungspunkte der UI: `homeTabsProvider` (Tabs), `seriesOpenerProvider` (Tippen auf Messreihe), `recordingExtrasProvider` (Zusatzinhalt im Aufnahmebildschirm), `SeriesRecordingController.addBlockListener` (Live-Blöcke). (Task_04)

**Aus Task_05:**

- Kalibrierung: neueste Zeile in `Calibrations` je Gerät (`repo.latestCalibration(deviceId)`), Felder `micSpacingM`, `channelOffsetS`, `swapChannels`. Messreihen speichern `calibrationId` und die Werte in `metadata.json`. Ohne Kalibrierung gelten b = 0,15 m und Δ0 = 0. Bei `swapChannels` die Kanäle vor jeder Auswertung tauschen. (Task_05)
- Vorzeichenkonvention am Standort: Richtung +1 = "nach rechts" (Blick vom Gerät zur Straße) = +x = Seite des rechten Mikrofons. (Task_05)

**Aus Task_06:**

- Spektrogramm: `Spectrogram.compute(mono, config:, from:, to:)`, Zeiten = Fenstermitten relativ zu `from`. Auswertekonstanten einer Messreihe: `repo.analysisSetup(id)` → `AnalysisSetup` (b, Δ0, swapChannels, c, Spuren). WAV-Ausschnitte: `readWavStereoRange(file, startS:, durationS:)`. (Task_06)
- Die Entscheidung interne vs. externe Mikrofone (PDF 10, erster Entscheidungspunkt) steht noch aus und fällt in Task_20. (Task_06)

**Aus Task_07:**

- Ereignisse: `EventDetector(config:).add(block)` / `finish()`, `detectEvents(signal, config:)` → `PassEvent` (Zeiten relativ zum Stream-Anfang). Meldung 4 s nach dem Maximum. (Task_07)

**Aus Task_08:**

- `MotionFitter(config:, maxTdoa:, channelOffset:, speedOfSound:, laneDistance:)` → `fit(correlogram, timeOffsetS:, peakTimeS:)` → `MotionFit` (κ, σκ, t0 als Abstrahlzeit, Reststreuung, `reason`). Gründe für B/C zentral in `DowngradeReason`. Rechenzeit ≈ 0,7 s pro Ereignis am PC. (Task_08)

**Aus Task_09:**

- Datensatz: `PassRecord` (km/h wie 9.1, `reason` als `DowngradeReason`). Auswertung pro Ereignisfenster zentral über `EventPipeline` (`lib/data/event_pipeline.dart`); ganze Dateien über `runSeriesAnalysis`/`analyseSeriesInBackground`. Persistenz `repo.replacePasses/addPass/passes`. DB-Schema jetzt Version 2. (Task_09)

**Aus Task_10:**

- Doppler Variante 1: `DopplerEstimator(config:, speedOfSound:).estimate(window, windowStartS:, receptionT0:, directionCosine:)` → `DopplerResult`. In `EventPipeline` integriert. (Task_10)

**Aus Task_11:**

- Vollständige Auswertung pro Ereignis: `EventPipeline.evaluate` (TDOA → Doppler → `fuse` → Klasse A/B/C mit Grund). Klassenlogik zentral in `classify` (`lib/core/pipeline/fusion.dart`). (Task_11)

**Aus Task_12:**

- Live: `LivePipeline(config:, setup:)` mit `add(block)`, `records`, `finish()`; in `SeriesRecordingController` integriert. Rechenzeit am PC ca. 1 s pro Ereignis. (Task_12)

**Aus Task_13:**

- Statistik: `StatisticsReport.from(records, limitKmh:)` (A/B/A+B, Richtung, Spur, Stunde, C mit Gründen), Perzentil Typ 7, Anteil über Limit = v > Limit. (Task_13)

**Aus Task_14:**

- Exportformate: CSV (`;`, Dezimalpunkt, Spalten = 9.1, Einheiten in `einheiten.txt`), JSON `nyooom-series` v1, ZIP (ungepackt, mit `audio.wav` und `metadata.json`). Code: `lib/core/export/`, `exportSeries` in `lib/data/series_export.dart`. (Task_14)

**Aus Task_15:**

- Referenzfahrten: `ReferenceTrack` (`lib/core/reference/`), Import GPX/CSV, Logger über `geolocator`; DB-Schema 3 (`reference_tracks`, `reference_points`). (Task_15)

**Aus Task_16:**

- Validierung: `closestApproaches` → `matchReferences` → `ValidationReport.acceptance(config)` (`lib/core/validation/`). Standort braucht Breite/Länge und für die Richtungsprüfung die Kompassrichtung von +x. DB-Schema 4. **Offener Punkt:** echte Abnahme mit Referenzfahrten (Task_20). (Task_16)

**Aus Task_17:**

- Doppler Variante 2 (`SharpnessEstimator`) läuft nur ohne Ton in Variante 1 (Schalter `dopplerVariant2`). Zwei dokumentierte Abweichungen vom PDF-Schärfemaß (Rauschschwelle, Median außerhalb des Maximums). Kostet ca. 1,5 s pro Ereignis am PC. (Task_17)

## Auffälligkeiten & Details

Dinge, die global noch zu beachten sind: Besonderheiten, bekannte Einschränkungen, kleinere Details. Wird laufend ergänzt.

- Das Projekt-Setup (Git, `.gitignore`, `docs/`, Root-`AGENTS.md`, FVM) ist erledigt; die Root-`AGENTS.md` gilt zusätzlich (siehe `Roadmap/AGENTS.md`, Abschnitt 7). Das Flutter-Projekt wurde in Task_01 generiert; Struktur und Plattform-Schnittstelle stehen in `docs/architecture.md`.
- Der FVM-Symlink `.fvm/versions/3.50.0` (für die IDE) ließ sich ohne Windows-Entwicklermodus nicht anlegen; `fvm flutter` funktioniert trotzdem.
- Größtes Projektrisiko: Ob das Zielgerät zwei getrennte, unbearbeitete Mikrofonkanäle liefert, ist herstellerabhängig. Geklärt wird das in Task_01, Task_05 und Task_06. Ausweichlösung ist ein externes USB-Stereomikrofon.
- Offene fachliche Punkte aus der PDF (Abschnitt 10): Anteil der Fahrzeuge mit auswertbarem Ton, systematischer Fehler durch die ausgedehnte Schallquelle, Frequenzabhängigkeit von b, Warnton von E-Autos.

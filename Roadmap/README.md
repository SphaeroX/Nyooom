# Nyooom – Roadmap

Projektübergreifendes Gedächtnis. Agenten lesen diese Datei vor jedem Task und aktualisieren sie, wenn sich etwas ergibt, das über einen einzelnen Task hinausgeht. Regeln für die Arbeit: [AGENTS.md](AGENTS.md).

## Projektziel

Nyooom ist eine Android-App (Flutter, iOS später möglich), die die Geschwindigkeit einzeln vorbeifahrender Fahrzeuge allein aus der Stereo-Aufnahme der beiden eingebauten Smartphone-Mikrofone schätzt. Grundlage ist das Messverfahren aus `technik.pdf` im Projekt-Root ("Akustische Geschwindigkeitsmessung: Methodik für den Prototyp"): Laufzeitdifferenz (GCC-PHAT) und Doppler-Verschiebung, fusioniert über den Richtungskosinus u(t), mit Qualitätsklassen A, B und C. Das Ergebnis dient einer Statistik über eine Straße, nicht dem Nachweis einzelner Verstöße.

**Was die Software tut:** Die App prüft, ob ein Smartphone echtes, unbearbeitetes Stereo liefert, und kalibriert den effektiven Mikrofonabstand b und den Kanalversatz Δ0. Sie legt Messreihen mit Standortdaten an (Spurabstände, Mikrofonhöhe, Temperatur, Zuordnung Fahrtrichtung → Spur), nimmt 48-kHz-Stereo auf, erkennt Vorbeifahrten live und berechnet pro Fahrzeug einen Datensatz (Abschnitt 9.1 der PDF). Daraus entstehen Statistiken (Median, V85, Anteil über dem Limit, getrennt nach Klasse A/B), ein CSV/JSON-Export und ein Abgleich mit GPS-Referenzfahrten zur Validierung (Abschnitt 8).

**Zielgruppe:** Der Entwickler selbst und Personen, die Verkehrsstatistiken für eine Straße erheben wollen; Bedienung am Straßenrand mit Smartphone auf Stativ.

**Nicht-Ziele:** Nachweis einzelner Verstöße; iOS-Umsetzung in dieser Roadmap (Architektur soll iOS aber nicht verbauen); Cloud, Backend oder Nutzerkonten; eine separate Python-Auswertung am PC (die PDF schlägt sie vor, es wurde bewusst entschieden, alles direkt in der App umzusetzen).

## Aktueller Status

Stand: 2026-11-16 – Task_02 läuft. Gerätetests sind gesammelt nach Task_20 verschoben (siehe unten).

| Task | Titel | Status |
|---|---|---|
| 01 | Durchstich: Stereo-Rohaufnahme | erledigt (Gerätetest → 20) |
| 02 | Signalmodell und synthetische Vorbeifahrten | läuft |
| 03 | DSP-Kern und GCC-PHAT-Laufzeitspur | offen |
| 04 | Messreihe anlegen und aufnehmen | offen |
| 05 | Geräteeignung und Kalibrierung | offen |
| 06 | Sichtprüfung: Korrelogramm und Spektrogramm | offen |
| 07 | Ereigniserkennung | offen |
| 08 | Anpassung des Bewegungsmodells | offen |
| 09 | Laufzeitmessung Ende zu Ende (Klasse B/C) | offen |
| 10 | Doppler Variante 1: Linienverfolgung | offen |
| 11 | Beschleunigungsprüfung, Fusion, Klasse A | offen |
| 12 | Live-Auswertung | offen |
| 13 | Statistik | offen |
| 14 | Export | offen |
| 15 | GPS-Referenzfahrten | offen |
| 16 | Validierung und Abnahme | offen |
| 17 | Doppler Variante 2: Entzerrung | offen |
| 18 | Selbstkalibrierung | offen |
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

## Auffälligkeiten & Details

Dinge, die global noch zu beachten sind: Besonderheiten, bekannte Einschränkungen, kleinere Details. Wird laufend ergänzt.

- Das Projekt-Setup (Git, `.gitignore`, `docs/`, Root-`AGENTS.md`, FVM) ist erledigt; die Root-`AGENTS.md` gilt zusätzlich (siehe `Roadmap/AGENTS.md`, Abschnitt 7). Das Flutter-Projekt wurde in Task_01 generiert; Struktur und Plattform-Schnittstelle stehen in `docs/architecture.md`.
- Der FVM-Symlink `.fvm/versions/3.50.0` (für die IDE) ließ sich ohne Windows-Entwicklermodus nicht anlegen; `fvm flutter` funktioniert trotzdem.
- Größtes Projektrisiko: Ob das Zielgerät zwei getrennte, unbearbeitete Mikrofonkanäle liefert, ist herstellerabhängig. Geklärt wird das in Task_01, Task_05 und Task_06. Ausweichlösung ist ein externes USB-Stereomikrofon.
- Offene fachliche Punkte aus der PDF (Abschnitt 10): Anteil der Fahrzeuge mit auswertbarem Ton, systematischer Fehler durch die ausgedehnte Schallquelle, Frequenzabhängigkeit von b, Warnton von E-Autos.

# Task_06: Sichtprüfung: Korrelogramm und Spektrogramm

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_06.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Eine gespeicherte Aufnahme lässt sich in der App als Pegelverlauf, Korrelogramm und Spektrogramm darstellen. Damit wird nach PDF Abschnitt 10, Schritt 2 sichtbar, ob die S-förmige Laufzeitspur mit dem Gerät erkennbar ist. Das ist der erste Entscheidungspunkt des Projekts.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_03 (Korrelogramm) und Task_04 (gespeicherte Messreihen) archiviert; Task_05 sollte eine Kalibrierung geliefert haben.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitt 10 (Schritt 2 und Entscheidung danach), 5.2 (Korrelogramm), 5.4 Variante 1 Schritt 1 (Spektrogramm-Parameter: Fenster 4096, Vorschub 512, Padding 16384, Band 150 Hz bis 8 kHz).

## Umfang

**Gehört dazu:**

- Spektrogramm-Berechnung (Summensignal) als wiederverwendbare Dart-Funktion, Parameter aus der Konfiguration.
- Darstellung in der App: Zeitachse wählbar (Ausschnitt), Pegelverlauf, Korrelogramm (Verzögerung in µs über Zeit), Spektrogramm (Frequenz über Zeit), Farbskala.
- Berechnung im Hintergrund-Isolate, damit die UI flüssig bleibt.
- Optional einblendbare Modellkurve Δ(t) für manuell eingegebene κ und t0 (Hilfe für die Sichtprüfung).

**Gehört nicht dazu:**

- Automatische Ereigniserkennung (Task_07) und Modellanpassung (Task_08).
- Tonspur-Verfolgung (Task_10).

## Umsetzungsschritte

1. Spektrogramm-Funktion implementieren und testen.
2. Rendering der Matrizen in ein Bild (z. B. `dart:ui` Image aus Pixeldaten) mit Farbskala.
3. Viewer-Bildschirm für eine Messreihe mit Zeitausschnitt-Auswahl.
4. Isolate-Anbindung.
5. Tests schreiben; Nutzer nimmt 20 bis 30 Vorbeifahrten auf und begutachtet sie.
6. Entscheidung des Nutzers dokumentieren: S-Spur bei den meisten Fahrzeugen sichtbar (weiter mit internen Mikrofonen) oder nicht (externes USB-Mikrofon nach Task_05 verwenden und Folge-Tasks entsprechend anpassen).

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Spektrogramm: Sinus mit 1 kHz erscheint in der richtigen Frequenzzeile (nach Parabelinterpolation auf besser als 1 Hz).
- Synthetische Vorbeifahrt mit Ton: Der Frequenzverlauf im Spektrogramm geht von f_an nach f_ab.
- Synthetische Vorbeifahrt: Der Bildrenderer erzeugt ein Bild mit erwarteter Größe; die hellste Spur im Korrelogramm liegt auf der Modellkurve.
- Widget-Test: Viewer öffnet eine Fixture-Messreihe ohne Fehler.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `fvm flutter test tests/` läuft grün.
- [ ] (→ Task_20; mit simulierter Messreihe geprüft) Für eine echte Aufnahme mit Vorbeifahrten sind Korrelogramm und Spektrogramm in der App sichtbar (Screenshot in den Notizen beschrieben oder abgelegt).
- [ ] (→ Task_20) Die Entscheidung interne vs. externe Mikrofone ist vom Nutzer getroffen und in `Roadmap/README.md` festgehalten.

## Offene Fragen / Annahmen

- Die Entscheidung trifft der Nutzer. Fällt sie auf externes Mikrofon, müssen Standort- und Kalibrier-Abläufe (Task_04/05) eventuell angepasst und Folge-Tasks überarbeitet werden.
- Annahme: Echte Beispielaufnahmen (kurze Ausschnitte) werden als zusätzliche Test-Fixtures abgelegt; Größe begrenzen und Ablageort in der README dokumentieren.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Erster Entscheidungspunkt der PDF (interne vs. externe Mikrofone) braucht echte Aufnahmen und liegt jetzt in Task_20. Mit simulierten Messreihen zeigt der Viewer die S-Spur und die Doppler-Linien wie erwartet.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle automatisch prüfbaren Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** `Spectrogram.compute` (`lib/core/dsp/spectrogram.dart`, 4096/512/16384, Band 150 Hz–8 kHz, `peakFrequency` mit Parabelinterpolation, `parabolicOffset`). `heatmapRgba` + `colorScale` (`lib/core/inspection/heatmap.dart`), `computeInspection` (Pegel 50 ms, Korrelogramm, Spektrogramm). WAV-Ausschnitte ohne Volllast: `readWavInfo`, `readWavStereoRange`. UI: `SeriesDetailScreen` (Tippen auf eine Messreihe) mit Button zur `InspectionScreen` (Zeitausschnitt 4/8/16 s per Slider, Modellkurve Δ(t) für manuelles κ/t0 als Overlay). Berechnung per `Isolate.run`.
- **Learnings & Stolpersteine:** Widget-Tests mit Isolates und Datei-I/O brauchen `tester.runAsync` und eine Pump-Schleife. `decodeImageFromPixels` funktioniert im Test.
- **Wichtige Entscheidungen und ihre Gründe:** Bildrenderer liefert RGBA-Bytes aus reinem Dart (testbar), die Umwandlung in `ui.Image` macht nur `RgbaImageView`. Korrelogramm-Farbskala fest 0..1 (R ist normiert), Spektrogramm 60 dB Dynamik ab Maximum.
- **Auswirkungen auf Folge-Tasks:** Task_10 nutzt `Spectrogram.compute(sum, from:, to:)` und `peakFrequency`/`parabolicOffset`. `AnalysisSetup` (`lib/core/pipeline/analysis_setup.dart`) und `repo.analysisSetup(seriesId)` liefern b, Δ0, Tausch, c und Spurgeometrie für jede Auswertung. `StereoBlock.swapped` tauscht Kanäle. Weitere Abschnitte der Detailansicht über `seriesSectionsProvider`.
- **Hinweise zu Tests und Befehlen:** `tests/core/dsp/spectrogram_test.dart`, `tests/core/inspection/`, `tests/ui/inspection/`.

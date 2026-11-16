# Task_10: Doppler Variante 1: Linienverfolgung

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_10.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Für ein Ereignis mit gültiger Laufzeitspur wird die Doppler-Geschwindigkeit v_D nach PDF 5.4 Variante 1 geschätzt: Tonspuren im Spektrogramm verfolgen und mit dem bekannten Richtungsverlauf u(t) per linearer Regression mit gemeinsamem v auswerten.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_08 archiviert (u(t) als glatte Modellkurve). Task_06 liefert die Spektrogramm-Funktion.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitte 3.3/3.4 (Doppler und Fusionsbeziehung), 5.4 Variante 1 (Schritte 1 bis 5, Zeitversatz −0,3 bis +0,3 s), 9.2 (Mindestüberhöhung 8 dB, Mindestlänge 0,5 s, Band 150 Hz bis 8 kHz).

## Umfang

**Gehört dazu:**

- Spektrogramm des Summensignals im Ereignisfenster, Normierung jeder Zeile durch gleitenden Median über die Frequenz.
- Lokale Maxima mit mindestens 8 dB Überhöhung, Parabelinterpolation der Frequenz.
- Verketten zu Spuren (Frequenzsprung-Toleranz festlegen), Mindestlänge 0,5 s, Überdeckung von t0.
- Gemeinsame lineare Ausgleichsrechnung: ln f_k(t_j) = ln f0_k − (v/c)·u(t_j), eigener Achsenabschnitt je Spur, gemeinsames v; u stets aus der Modellkurve.
- Wiederholung für Zeitversätze −0,3 bis +0,3 s, Wahl des Versatzes mit kleinster Reststreuung.
- Ergebnis: v_D, σ_D, Anzahl Tonspuren, gewählter Versatz; oder "kein Ton".

**Gehört nicht dazu:**

- Beschleunigungsprüfung, Fusion, Klasse A (Task_11).
- Variante 2 Entzerrung (Task_17).

## Umsetzungsschritte

1. Median-Normierung und Spitzensuche implementieren.
2. Spurverkettung implementieren.
3. Lineare Ausgleichsrechnung mit Blockstruktur (gemeinsames v, Achsenabschnitte je Spur) umsetzen, σ_D aus der Kovarianz.
4. Schleife über Zeitversätze.
5. Ergebnis an die Pipeline aus Task_09 anhängen (Felder `v_doppler`, `n_toene` werden befüllt, Klasse noch unverändert).
6. Tests schreiben und grün bekommen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Synthetische Vorbeifahrt mit einem Ton (z. B. 800 Hz plus Harmonische), 30 km/h/5 m und 50 km/h/4 m: v_D auf 1,5 km/h genau.
- Mehrere Töne verbessern die Schätzung gegenüber einem Ton (kleineres σ_D).
- Synthetischer Versatz der Tonquelle um 0,2 s: Der gefundene Versatz liegt nahe 0,2 s und v_D bleibt in der Toleranz.
- Vorbeifahrt ohne Ton: Ergebnis "kein Ton", keine Scheinschätzung.
- Spuren kürzer als 0,5 s oder ohne Überdeckung von t0 werden verworfen.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `fvm flutter test tests/` läuft grün.
- [x] Alle Schwellen aus der Konfiguration.
- [ ] (→ Task_20) Auf echten Aufnahmen ist der Anteil der Ereignisse mit nutzbarem Ton gezählt und in `Roadmap/README.md` notiert (offener Punkt der PDF).

## Offene Fragen / Annahmen

- Welcher Anteil der Fahrzeuge einen auswertbaren Ton hat, ist unbekannt und ein Hauptergebnis dieses und des nächsten Tasks.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Gleitender Median über 150 Hz (`toneMedianWidthHz`) wird nur an jedem ~6. Bin exakt berechnet und dazwischen linear interpoliert (sonst zu langsam bei 2679 Bins pro Zeile).
- Spurverkettung: nächster Spitzenwert innerhalb `toneMaxJumpHz` = 15 Hz pro Rahmen (8-kHz-Ton bei 50 km/h/4 m ändert sich um ca. 12 Hz pro Rahmen); Lücken bis `toneMaxGapS` = 0,1 s werden überbrückt (ohne das zerfielen schwächere Harmonische in Stücke). "Überdeckt t0" = Spur reicht mindestens 0,2 s vor und nach dem Empfangszeitpunkt der größten Annäherung.
- Regression nicht linearisiert: Gauss-Newton auf ln f = ln f0_k − ln(1 + v/c·u), Achsenabschnitt je Spur; σ_D aus der Reststreuung, aufgeblasen mit Fenster/Vorschub (= 8) wegen überlappender Rahmen. Zusätzlich wird bereits die Regression mit g·(t − t0) gerechnet (`speedWithAcceleration`) für Task_11.
- Anteil Ereignisse mit nutzbarem Ton auf echten Daten → Task_20. In der Simulation haben ca. 80 % der Verbrenner und die E-Autos mit Warnton einen Ton.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle automatisch prüfbaren Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** `DopplerEstimator` (`lib/core/pipeline/doppler.dart`): Spektrogramm des Summensignals, Median-Normierung, Spitzen ≥ 8 dB mit Parabelinterpolation, Spurverkettung (`trackTones`), Auswahl (`selectTracks`), gemeinsame Ausgleichsrechnung mit Versatzsuche ±0,3 s. `DopplerResult` (speed, sigma, toneCount, offsetS, speedWithAcceleration). In `EventPipeline` eingehängt: `v_doppler`, `sigma_doppler`, `n_toene` werden gefüllt, Klasse bleibt (Task_11). Neuer Konfigurationswert `toneMaxGapS`.
- **Learnings & Stolpersteine:** Schwache Harmonische liegen knapp an der 8-dB-Schwelle; ohne Lückentoleranz entstehen nur kurze Bruchstücke, die die 0,5-s-Regel verwerfen.
- **Wichtige Entscheidungen und ihre Gründe:** u(t) kommt immer aus der angepassten Modellkurve (`fitter.tdoaAt`), nie aus den Einzelmaxima (PDF 5.4). Der Versatz δ verschiebt das Argument von u: u(t + δ), positives δ = Tonquelle fährt voraus.
- **Auswirkungen auf Folge-Tasks:** Task_11 nutzt `DopplerResult.speedWithAcceleration` für die Beschleunigungsprüfung (|v − v_g| > 2 km/h) und `speed/sigma` für Abstandsprüfung und Fusion; dafür `EventPipeline.evaluate` erweitern. Task_17 (Variante 2) ergänzt den Fall "kein Ton".
- **Hinweise zu Tests und Befehlen:** `tests/core/pipeline/doppler_test.dart`, `tests/data/event_pipeline_test.dart`.

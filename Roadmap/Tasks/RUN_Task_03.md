# Task_03: DSP-Kern und GCC-PHAT-Laufzeitspur

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_03.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Aus zwei Kanälen entsteht ein Korrelogramm per GCC-PHAT nach PDF 5.2, und pro Block werden Lage und Höhe des Maximums als Laufzeitmesswert und Gewicht geliefert. Das ist der Messkern für Kalibrierung, Sichtprüfung und Laufzeitmessung.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_02 archiviert (Konfiguration, Generator).
- **Relevantes Vorwissen:** `technik.pdf` Abschnitt 5.2 (Laufzeitspur per Kreuzkorrelation), 3.5 (Größenordnungen). Parameter Blocklänge 2048, Vorschub 512, Band 300 Hz bis 8 kHz, Zero-Padding 16-fach, Suchbereich ±1,2·b/c.

## Umfang

**Gehört dazu:**

- Reelle FFT/IFFT in Dart (eigenes Modul oder geprüftes Pub-Paket wie `fftea`), Hann-Fenster, Hilfen für Zero-Padding.
- GCC-PHAT pro Block: normiertes Kreuzspektrum mit ε, Bandmaske W(f), Rücktransformation mit Zero-Padding, Beschränkung auf ±1,2·b/c.
- Korrelogramm-Datenstruktur (Zeit × Verzögerung) und Extraktion von Maximum (Lage per Parabelinterpolation) und Gewicht pro Block.
- Funktion für eine einzelne Laufzeitdifferenz über ein ganzes Signalstück (wird in der Kalibrierung gebraucht).

**Gehört nicht dazu:**

- Modellanpassung (Task_08).
- Darstellung als Bild (Task_06).
- Spektrogramm für Doppler (Task_10).

## Umsetzungsschritte

1. FFT-Variante wählen und begründen (Geschwindigkeit, Lizenz); kurzen Benchmark für 2048 Werte mit 16-fachem Padding auf dem Rechner festhalten.
2. Fenster- und Blockzerlegung als wiederverwendbare Funktion anlegen (auch für das Spektrogramm später).
3. GCC-PHAT gemäß der Formel in PDF 5.2 implementieren, alle Werte aus der Konfiguration lesen.
4. Spitzensuche im erlaubten Verzögerungsbereich mit Parabelinterpolation.
5. Korrelogramm über ein ganzes Auswertefenster berechnen.
6. Tests mit synthetischen Signalen schreiben und grün bekommen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- FFT: Vergleich mit einer naiven DFT bei kleinen Längen; Parseval; Roundtrip FFT → IFFT.
- Bekannte konstante Verzögerung (z. B. +200 µs, −350 µs, 0) in weißem Rauschen wird auf besser als 3 µs gefunden.
- Verzögerung außerhalb ±1,2·b/c wird nicht als Maximum gemeldet.
- Synthetische Vorbeifahrt aus Task_02: Die Spur der Blockmaxima folgt dem Modell Δ(t) nahe t0 mit einer Abweichung unter 10 µs (RMS) bei gutem SNR.
- Das Gewicht (Spitzenhöhe) ist bei reinem unkorreliertem Rauschen deutlich kleiner als bei einer Quelle.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Die Zeitauflösung der Korrelation entspricht 1/(48 kHz·16) ≈ 1,3 µs; durch Test belegt.
- [ ] Die Berechnung eines 8-s-Fensters dauert auf dem Entwicklungsrechner unter einer festgehaltenen Schranke; Messwert steht in den Erkenntnissen (Grundlage für Task_12).

## Offene Fragen / Annahmen

- Annahme: Dart ist schnell genug. Wird der Benchmark kritisch, in den Erkenntnissen vermerken; die Entscheidung über Optimierung fällt in Task_12.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [ ] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [ ] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [ ] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [ ] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

<!-- ERKENNTNISSE-OFFEN: Vor der Archivierung ausfüllen und diese Zeile löschen. -->

Vor der Archivierung vom Agenten auszufüllen. Schreibe so, dass ein Agent, der diesen Task nie gesehen hat, davon bei späteren Tasks profitiert:

- **Umgesetzt (und Abweichungen vom Plan):**
- **Learnings & Stolpersteine:**
- **Wichtige Entscheidungen und ihre Gründe:**
- **Auswirkungen auf Folge-Tasks:**
- **Hinweise zu Tests und Befehlen:**

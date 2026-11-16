# Task_12: Live-Auswertung

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_12.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Während einer laufenden Messreihe werden Vorbeifahrten in Echtzeit erkannt und ausgewertet; jedes Fahrzeug erscheint wenige Sekunden nach der Vorbeifahrt mit Geschwindigkeit und Klasse auf dem Bildschirm. Das Speichern von Rohaudio wird abschaltbar.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_11 archiviert (vollständige Pipeline offline).
- **Relevantes Vorwissen:** `technik.pdf` Abschnitt 1 (Rohaudio nur in der Entwicklungsphase), 5.1 (Fenster ±4 s, also mindestens 4 s Latenz nach dem Maximum). Laufzeitmessungen aus den Erkenntnissen von Task_03 und Task_08.

## Umfang

**Gehört dazu:**

- Streaming-Architektur: Aufnahme-Stream → Ringpuffer (mindestens Grundpegel-Historie und ±4 s Fenster) → Ereigniserkennung → Auswertung je Ereignis in einem Worker-Isolate.
- Backpressure: Laufen Ereignisse schneller auf, als ausgewertet werden kann, Warteschlange mit Begrenzung und Anzeige; verlorene Ereignisse zählen.
- Live-Bildschirm: aktueller Pegel, Liste der letzten Fahrzeuge (v, Richtung, Klasse), Zähler A/B/C, Laufzeit der Messreihe.
- Schalter "Rohaudio speichern" pro Messreihe (Standard an während der Entwicklung); ohne Rohaudio bleiben nur die Datensätze.
- Gleiche Ergebnisse wie die Offline-Auswertung derselben Aufnahme.
- Optimierung von Hotspots, falls die Echtzeit auf dem Zielgerät nicht erreicht wird.

**Gehört nicht dazu:**

- Statistik-Ansichten (Task_13).
- Neue Auswertealgorithmen.

## Umsetzungsschritte

1. Laufzeitbudget auf dem Zielgerät messen (Ereignis-Auswertung in Release-Build).
2. Ringpuffer und Streaming-Pipeline aufbauen; Ereigniserkennung im Streaming-Modus (Task_07) anbinden.
3. Worker-Isolate mit Warteschlange für die Ereignis-Auswertung.
4. Live-UI und Persistenz der Datensätze während der Aufnahme.
5. Rohaudio-Schalter.
6. Falls nötig: Hotspots optimieren (z. B. FFT, Grobsuche) und Vorher/Nachher-Zahlen festhalten.
7. Tests schreiben; mindestens 30 Minuten Live-Betrieb auf dem Gerät testen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Synthetische lange Aufnahme in Blöcken in die Live-Pipeline gespeist: Datensätze identisch zur Offline-Auswertung (gleiche Ereignisse, v innerhalb numerischer Toleranz).
- Ereignis am Anfang und am Ende einer Aufnahme (Fenster unvollständig): definiertes Verhalten, kein Absturz.
- Warteschlange voll: verlorene Ereignisse werden gezählt und gemeldet.
- Rohaudio aus: keine WAV-Datei, Datensätze trotzdem gespeichert.
- Manuell: 30 Minuten Live-Betrieb, CPU-Auslastung und Akku notieren, keine wachsende Warteschlange.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `fvm flutter test tests/` läuft grün.
- [ ] (→ Task_20) Auf dem Zielgerät erscheint ein Ergebnis spätestens 10 s nach der Vorbeifahrt (gemessen, in den Notizen).
- [x] Live- und Offline-Auswertung derselben Aufnahme stimmen überein (Test).

## Offene Fragen / Annahmen

- Reicht reines Dart für Echtzeit auf dem Zielgerät? Falls nicht, Optionen (Algorithmen vereinfachen, Teile nativ) mit dem Nutzer besprechen, bevor eine neue Sprache eingeführt wird.
- Bildschirm-aus und Hintergrundbetrieb: Entscheidung aus Task_04 übernehmen bzw. hier finalisieren.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Laufzeitbudget am PC: ca. 0,8–1,2 s pro Ereignis (Korrelogramm, Modellanpassung, Spektrogramm, Doppler). Bei einem Fahrzeug alle ~6 s reicht das auch bei 3–5-fach langsamerem Telefon. Messung im Release-Build auf dem Gerät → Task_20; keine Optimierung nötig, solange die Warteschlange nicht wächst.
- Ringpuffer 12 s (Fenster 8 s + Meldelatenz 4 s). Fenster, deren Anfang schon überschrieben ist, werden als verloren gezählt.
- Warteschlange: höchstens 4 Ereignisse laufend/wartend, weitere werden verworfen und gezählt (`liveDropped`).
- Rohaudio-Schalter: gibt es seit Task_04 beim Start einer Messreihe; ohne Rohaudio werden nur die Live-Datensätze gespeichert.
- Hintergrundbetrieb: Entscheidung aus Task_04 übernommen (kein Foreground-Service); Prüfung auf dem Gerät → Task_20.
- Die Simulation nimmt jetzt die eingegebene Temperatur (c passt zur Messreihe).

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle automatisch prüfbaren Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** `LivePipeline` (`lib/data/live_pipeline.dart`): Ringpuffer, `EventDetector` im Streaming, langlebiger Worker-Isolate mit `EventPipeline`, Warteschlange mit Verlustzähler, `finish()` wertet Ereignisse am Aufnahmeende aus. `evaluateSignalFull` als Offline-Referenz. Integration in `SeriesRecordingController` (Datensätze per `repo.addPass` während der Aufnahme, Zustand `liveRecords/livePending/liveDropped`), Live-Bereich `LiveResultsPanel` auf dem Aufnahmebildschirm; in der Simulation zusätzlich die wahren Werte der vorbeigefahrenen Fahrzeuge zum Vergleich. Schalter `liveEvaluationProvider` (Standard an).
- **Learnings & Stolpersteine:** Worker-Isolate per `Isolate.spawn` mit Top-Level-Einstieg; Anfragen und Ergebnisse als einfache Klassen über `SendPort` (gleiche Isolate-Gruppe). Fenstergrenzen live wie offline über `round(t·fs)` bilden, sonst weichen die Ergebnisse ab.
- **Wichtige Entscheidungen und ihre Gründe:** Reines Dart bleibt (keine native Optimierung nötig nach PC-Messung). Live-Datensätze werden nicht ersetzt, sondern ergänzt; eine spätere Offline-Neuauswertung ersetzt sie (`replacePasses`).
- **Auswirkungen auf Folge-Tasks:** Statistik (Task_13) kann während und nach der Aufnahme `repo.passes(seriesId)` lesen. Task_17 (Variante 2) erhöht die Rechenzeit; Live-Budget im Blick behalten.
- **Hinweise zu Tests und Befehlen:** `tests/data/live_pipeline_test.dart` (Live = Offline, Ränder, volle Warteschlange), `tests/ui/series/series_live_test.dart` (ohne Rohaudio).

# Task_09: Laufzeitmessung Ende zu Ende (Klasse B/C)

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_09.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Eine gespeicherte Messreihe wird vollständig ausgewertet: Ereignisse finden, Korrelogramm, Modellanpassung, v_T = κ·d_Spur mit σ_T nach PDF 5.5. Pro Vorbeifahrt entsteht ein Datensatz nach PDF 9.1 (Klasse B oder C mit Grund), gespeichert in der Datenbank und als Liste in der App sichtbar. Damit liefert die App erstmals Geschwindigkeiten.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_05 (Kalibrierung), Task_07 und Task_08 archiviert.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitte 5.3 letzter Absatz (Richtung bestimmt Spur und Sollabstand), 5.5 (v_T, σ_T mit σd = 0,4 m), 5.6 (Klassen), 9.1 (Datensatz).

## Umfang

**Gehört dazu:**

- Pipeline-Klasse, die Messreihe + Kalibrierung + Standort + Konfiguration nimmt und Datensätze liefert.
- Zuordnung Richtung → Fahrspur → Schrägabstand d_Spur.
- Berechnung v_T, σ_T; Umrechnung in km/h.
- Klassenzuordnung B oder C mit Grund (Überlappung, Reststreuung, nicht monoton, außerhalb Suchbereich, Übersteuerung).
- Übersteuerungsprüfung im Ereignisfenster (Abtastwerte über 90 %).
- Speichern der Datensätze in drift (alle Felder aus 9.1; Doppler-Felder leer).
- UI: "Messreihe auswerten" mit Fortschritt, Ergebnisliste (Zeit, Richtung, v, σ_v, Klasse, Grund), Detailansicht mit Korrelogramm-Ausschnitt und angepasster Modellkurve.

**Gehört nicht dazu:**

- Doppler und Klasse A (Task_10/11).
- Statistik (Task_13).
- Live-Betrieb (Task_12).

## Umsetzungsschritte

1. Pipeline aus den Bausteinen von Task_03, Task_07 und Task_08 zusammensetzen.
2. v_T und σ_T nach Formel 5.5 berechnen.
3. Klassenlogik und Übersteuerungsprüfung.
4. Datensatz-Modell und Persistenz.
5. Auswertung in einem Isolate mit Fortschrittsmeldung.
6. UI für Ergebnisliste und Detail.
7. Tests schreiben; eine echte Messreihe auswerten und das Ergebnis mit der Sichtprüfung vergleichen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Synthetische Aufnahme mit mehreren Vorbeifahrten bei bekannten Geschwindigkeiten (20 bis 60 km/h, beide Richtungen, zwei Spuren): v_T liegt bei seitlicher Lage exakt in Spurmitte innerhalb von 1 km/h, Richtung und Spur stimmen.
- Seitliche Abweichung von 0,4 m: Fehler entspricht der erwarteten Größenordnung aus PDF 6.2, σ_T deckt ihn ab.
- Überlappung, übersteuerte Vorbeifahrt und reines Rauschen ergeben Klasse C mit passendem Grund.
- Persistenz: Datensätze lassen sich nach Neustart wieder laden; alle Felder aus 9.1 sind vorhanden.
- Widget-Test: Ergebnisliste zeigt Klasse und Grund an.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `fvm flutter test tests/` läuft grün.
- [ ] (→ Task_20; simulierte Messreihen liefern plausible Listen) Eine echte Messreihe ergibt eine Ergebnisliste mit plausiblen Geschwindigkeiten (Ergebnis in den Notizen).
- [x] Jeder Datensatz enthält alle Felder aus PDF 9.1; nicht belegte Doppler-Felder sind leer, nicht null-wertig falsch belegt.

## Offene Fragen / Annahmen

- Auf echten Daten ist keine Referenz vorhanden; die quantitative Prüfung folgt in Task_16.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Klasse B ohne Grund, solange Doppler fehlt (Task_11 setzt "kein Ton" usw.). Klasse C: `v`, `sigma_v`, `v_laufzeit` leer; κ und Reststreuung bleiben zur Diagnose gefüllt.
- `zeit` = Startzeit der Messreihe + t0 (Abstrahlzeit). `offset_s` = t0 relativ zum Aufnahmebeginn.
- Neuer Grund `noLane` (C), falls keine Spur für die erkannte Richtung angelegt ist.
- Schema 2: `passes.sigma_laufzeit`, `passes.sigma_doppler` (Migration mit `addColumn`, Test simuliert eine Schema-1-Datei per `DROP COLUMN` + `user_version = 1`).

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle automatisch prüfbaren Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** `PassRecord` (`lib/core/pipeline/pass_record.dart`, Felder nach 9.1, `toJson` mit 9.1-Namen), `EventEvaluator` + `evaluateSignal` + `laufzeitSigma` (`event_evaluator.dart`), `EventPipeline` (`lib/data/event_pipeline.dart`, zentraler Einstieg pro Ereignisfenster für offline und live), `runSeriesAnalysis`/`analyseSeriesInBackground` (`lib/data/series_analysis.dart`, WAV in 1-s-Stücken, Isolate mit Fortschritt). Repository: `replacePasses`, `addPass`, `passes`. UI: Abschnitt "Auswertung" in der Detailansicht (Button, Fortschritt, A/B/C-Zähler, Liste), `PassDetailScreen` mit allen Feldern und Korrelogramm samt angepasster Modellkurve (`InspectionScreen(fixedModel:)`).
- **Learnings & Stolpersteine:** `Isolate.spawn` braucht eine Top-Level-Einstiegsfunktion; Closures, die einen `ReceivePort` erfassen, sind nicht sendbar. Die Datei-Auswertung muss mit dem 16-Bit-quantisierten Signal verglichen werden.
- **Wichtige Entscheidungen und ihre Gründe:** Fenster werden pro Ereignis aus der Datei gelesen (keine ganze Aufnahme im Speicher). `PassRecord` speichert km/h (wie 9.1), intern bleibt alles SI.
- **Auswirkungen auf Folge-Tasks:** Task_10/11 erweitern `EventPipeline.evaluate` (Doppler, Fusion); `EventEvaluator.analyse` liefert dafür `EventAnalysis` mit Fit, Fitter und Fenstersignal. Task_12 ruft `EventPipeline` pro Live-Ereignis auf und speichert per `repo.addPass`. Task_13/14 lesen `repo.passes(seriesId)`.
- **Hinweise zu Tests und Befehlen:** `tests/core/pipeline/event_evaluator_test.dart` (mehrere Fahrzeuge, seitlicher Versatz, C-Gründe, Kanaltausch), `tests/data/passes_test.dart` (Roundtrip, Migration), `tests/data/series_analysis_test.dart`.

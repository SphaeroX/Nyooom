# Task_13: Statistik

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_13.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Für eine Messreihe (und zusammengefasst für einen Standort) zeigt die App Median, V85 und den Anteil über dem Tempolimit, getrennt nach Klasse A und B sowie nach Fahrtrichtung, zusammen mit dem Anteil der Klasse C und der Korrektur der Streuung nach PDF 8.3.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_11 archiviert (Datensätze mit Klassen).
- **Relevantes Vorwissen:** `technik.pdf` Abschnitte 1 (Zweck: Statistik), 2 letzter Absatz (Ausweis getrennt nach A und B), 5.6 letzter Absatz (Anteil C ausweisen), 8.3 (σ_wahr² = σ_gemessen² − σ_Messung², Effekt auf V85).

## Umfang

**Gehört dazu:**

- Statistikfunktionen in reinem Dart: Anzahl, Median, V85 (Perzentil-Definition festlegen und dokumentieren), Mittelwert, Standardabweichung, Anteil über Limit.
- Gruppierung nach Klasse (A, B, A+B), Richtung, Fahrspur, optional Zeitfenster (z. B. pro Stunde).
- Anteil C absolut und relativ mit Aufschlüsselung der Gründe.
- Korrektur nach 8.3: wahre Streuung aus gemessener Streuung und mittlerer Messunsicherheit (σ_v), korrigiertes V85 unter Normalverteilungsannahme zusätzlich ausweisen.
- Statistik-Bildschirm mit Tabellen und Histogramm der Geschwindigkeiten (A und B unterscheidbar).

**Gehört nicht dazu:**

- Export (Task_14).
- Vergleich mit Referenz (Task_16).

## Umsetzungsschritte

1. Perzentil-Definition festlegen und begründen.
2. Statistikfunktionen und Gruppierung implementieren.
3. Korrektur nach 8.3 implementieren.
4. UI mit Tabellen und Histogramm (Chart-Paket wählen oder selbst zeichnen).
5. Tests schreiben und grün bekommen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Median und V85 gegen handgerechnete Beispiele (gerade und ungerade Anzahl, Bindungen).
- Anteil über Limit an der Grenze (genau gleich dem Limit) nach festgelegter Regel.
- Korrektur: Beispiel aus PDF 8.3 (6 km/h wahre Streuung, 3 km/h Messunsicherheit) ergibt eine V85-Verschiebung von etwa 0,7 km/h.
- Gruppierung nach Klasse und Richtung liefert konsistente Summen.
- Leere Gruppen und Gruppen mit nur einem Wert werden sauber behandelt.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `fvm flutter test tests/` läuft grün.
- [x] (mit simulierter Messreihe; echte → Task_20) Der Statistik-Bildschirm zeigt für eine echte Messreihe alle Kennzahlen getrennt nach A und B sowie den Anteil C.

## Offene Fragen / Annahmen

- Annahme: Das Tempolimit kommt aus dem Standort (Task_04). Mehrere Limits pro Standort sind kein Ziel.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Perzentil-Definition: lineare Interpolation zwischen den Rängen, h = (n − 1)·p ("Typ 7", Standard in NumPy/Excel PERZENTIL.INKL). Begründung: stetig, verbreitet, Median identisch mit der üblichen Definition.
- Anteil über Limit: nur echt schneller (v > Limit); genau gleich zählt nicht.
- Korrektur 8.3: σ_wahr = √(max(0, σ² − σ_Messung²)) mit σ_Messung = RMS der σ_v der Gruppe; V85 korr. = Mittel + 1,0364·σ_wahr (Normalverteilung). Zusätzlich das empirische V85.
- Stundengruppen in Ortszeit des Geräts. Fahrspur-Gruppen werden berechnet (`byLane`), angezeigt werden Richtungen (Richtung = Spur, siehe Task_04).
- Kein Chart-Paket: Histogramm per `CustomPainter` (gestapelt, A grün, B blau, Linie = Tempolimit).

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle automatisch prüfbaren Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** `lib/core/stats/statistics.dart`: `percentile`, `speedStats` (`SpeedStats`), `ClassStats` (A, B, A+B), `StatisticsReport.from` (gesamt, Richtung, Spur, Stunde, Klasse C mit Gründen), `speedHistogram`, Korrektur `correctedSd`/`v85Shift`. UI: `StatisticsScreen`/`StatisticsView` aus der Detailansicht einer Messreihe und aus dem Standort (alle Messreihen, `repo.passesForSite`).
- **Learnings & Stolpersteine:** Zeitgruppen hängen von der Zeitzone ab; Tests mit `toLocal()` rechnen.
- **Wichtige Entscheidungen und ihre Gründe:** Statistik nur über `v` (Klasse C hat kein `v`), C wird separat gezählt (PDF 5.6).
- **Auswirkungen auf Folge-Tasks:** Task_14 kann `StatisticsReport` als Zusammenfassung exportieren. Task_16 nutzt eigene Fehlerkennzahlen, kann aber `percentile` verwenden.
- **Hinweise zu Tests und Befehlen:** `tests/core/stats/`, `tests/ui/stats/`.

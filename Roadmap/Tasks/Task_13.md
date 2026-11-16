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

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Der Statistik-Bildschirm zeigt für eine echte Messreihe alle Kennzahlen getrennt nach A und B sowie den Anteil C.

## Offene Fragen / Annahmen

- Annahme: Das Tempolimit kommt aus dem Standort (Task_04). Mehrere Limits pro Standort sind kein Ziel.

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

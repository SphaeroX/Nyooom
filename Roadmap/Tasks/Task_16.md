# Task_16: Validierung und Abnahme

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_16.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Messreihen werden mit Referenzfahrten verknüpft, Vorbeifahrten über die Uhrzeit zugeordnet und die Kennzahlen aus PDF 8 berechnet. Eine Ansicht zeigt, ob die Abnahmekriterien erfüllt sind (Ampel), getrennt nach Klasse, Richtung und Geschwindigkeitsstufe.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_11 und Task_15 archiviert.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitte 8 (Abnahmekriterien), 8.1 (Stufen 20/30/40/50 km/h, beide Richtungen, je 5 Wiederholungen, Beschleunigen/Bremsen), 8.3 (Auswertung). Abschnitt 1 (Systematischer Fehler unter 1 km/h).

## Umfang

**Gehört dazu:**

- Zuordnung: Für jede Referenzfahrt den Zeitpunkt der größten Annäherung an den Standort bestimmen (Standortkoordinate des Messgeräts eingeben oder aus der Logger-Spur nächster Punkt) und mit t0 der Datensätze innerhalb einer Toleranz (Startwert 2 s) verknüpfen.
- Referenzgeschwindigkeit als Mittel der GPS-Geschwindigkeit um die Vorbeifahrt.
- Fehler = Messwert − Referenz; Mittelwert, Standardabweichung und Fehler über Referenzgeschwindigkeit, getrennt nach Klasse, Richtung, Stufe und (falls angegeben) Fahrzeugart.
- Abnahmeprüfung gegen alle Schwellen aus PDF 8 (mittlere Abweichung ≤ 1 km/h, je Stufe ≤ 2 km/h ohne Trend, σ Klasse A ≤ 3 km/h, σ Klasse B ≤ 5 km/h, Anteil C ≤ 30 %, Richtung ≥ 99 % richtig).
- Validierungs-Bildschirm mit Ampel je Kriterium und Streudiagramm Fehler über Referenz.
- Export der Validierungsergebnisse (CSV), aufbauend auf Task_14.

**Gehört nicht dazu:**

- Anpassung von Algorithmen aufgrund der Ergebnisse; Erkenntnisse fließen in Task_17 bis Task_19 bzw. in neue Tasks, die mit dem Nutzer abgestimmt werden.

## Umsetzungsschritte

1. Standortkoordinate im Standort-Datensatz ergänzen (Migration) oder aus der Referenzspur ableiten.
2. Zuordnungslogik implementieren.
3. Kennzahlen und Abnahmeprüfung als reine Dart-Funktionen.
4. Trendprüfung über die Stufen festlegen (z. B. Steigung einer Regression Fehler über Referenz mit Schwelle) und dokumentieren.
5. UI und Export.
6. Tests schreiben; mit echten Referenzfahrten die Abnahme durchführen und die Ergebnisse in `Roadmap/README.md` eintragen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Zuordnung: synthetische Referenz- und Messzeitpunkte mit Versatz und Störern werden korrekt verknüpft; nicht zuordenbare werden gemeldet.
- Kennzahlen gegen handgerechnete Beispiele.
- Abnahmeprüfung: Datensatz, der knapp besteht, und einer, der knapp scheitert, für jedes Kriterium.
- Richtungserkennung: Anteil richtig wird korrekt berechnet.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Mit echten Referenzfahrten ist das Validierungsergebnis (alle Kennzahlen, Ampel) erstellt und in `Roadmap/README.md` festgehalten.

## Offene Fragen / Annahmen

- Die Referenzfahrten muss der Nutzer selbst durchführen (40 Fahrten plus Beschleunigen/Bremsen). Liegen sie zum Zeitpunkt des Tasks noch nicht vor, ist die Funktion mit synthetischen Daten belegt und die echte Abnahme wird als offener Punkt in der README geführt.
- Validierung an einem zweiten Standort und Gerätemodell (PDF 10, Schritt 6) ist wünschenswert, aber nicht Bedingung dieses Tasks.

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

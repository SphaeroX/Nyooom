# Task_18: Selbstkalibrierung

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_18.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Die App lernt pro Fahrspur den wirksamen Abstand aus den Messungen der Klasse A (Median von d_est nach PDF 7.4). Ab 30 Messungen ersetzt er den Maßbandwert, wodurch auch Klasse-B-Messungen genauer werden. Bei mehr als 20 % Abweichung warnt die App vor einem Aufbaufehler.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_11 archiviert (d_est in den Datensätzen).
- **Relevantes Vorwissen:** `technik.pdf` Abschnitt 7.4 (Selbstkalibrierung im Betrieb), 6.1 (ausgedehnte Schallquelle als systematischer Fehler).

## Umfang

**Gehört dazu:**

- Median von d_est pro Fahrspur über alle Klasse-A-Messungen eines Standorts (bzw. einer Messreihe; Bezug festlegen und dokumentieren).
- Ab mindestens 30 Klasse-A-Messungen pro Spur ersetzt der Median den Sollabstand für die Laufzeitschätzung; Mindestanzahl in der Konfiguration.
- Neuberechnung von v_T und der Fusion für bestehende Datensätze mit dem gelernten Abstand (Kennzeichnung, welcher Abstand verwendet wurde).
- Warnung bei Abweichung über 20 % mit möglichen Ursachen (Spurzuordnung, b, schräge Mikrofonachse).
- Anzeige: Maßbandwert, gelernter Wert, Anzahl Messungen pro Spur.

**Gehört nicht dazu:**

- Automatische Kalibrierung von b (bleibt bei Task_05).

## Umsetzungsschritte

1. Bezug (Standort oder Messreihe) und Aktualisierungszeitpunkt (laufend oder nach Abschluss) festlegen.
2. Berechnung und Speicherung des gelernten Abstands.
3. Pipeline so erweitern, dass der wirksame Abstand verwendet wird; Datensatzfeld für den verwendeten Abstand ergänzen (Migration).
4. Warnlogik und UI.
5. Tests schreiben und grün bekommen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Synthetische Messreihe mit systematisch 5 % zu kurzem effektiven Abstand: Nach 30 Klasse-A-Messungen verschwindet der systematische Fehler der Klasse-B-Messungen weitgehend.
- Weniger als 30 Messungen: Maßbandwert bleibt aktiv.
- Abweichung über 20 %: Warnung wird ausgelöst.
- Migration: bestehende Datensätze bleiben lesbar.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Die Anzeige zeigt für eine echte Messreihe Maßband- und gelernten Abstand pro Spur.

## Offene Fragen / Annahmen

- Wie groß der systematische Fehler durch die ausgedehnte Schallquelle am gewählten Abstand ist, ist offen (PDF 10). Ergebnis hier festhalten.

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

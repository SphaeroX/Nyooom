# Task_17: Doppler Variante 2: Entzerrung

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_17.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Zusätzlich zur Linienverfolgung schätzt die App v_D über das Schärfemaximum nach PDF 5.4 Variante 2. Dadurch werden auch schwache und hochfrequente Töne nutzbar, und der Anteil der Klasse A steigt.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_11 archiviert (Fusion, Klassen). Validierungsergebnisse aus Task_16 helfen beim Vergleich.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitt 5.4 Variante 2 (Schritte 1 bis 5: d = v/κ, Entzerrung t → te, gemitteltes Leistungsspektrum für |u| ≤ 0,95, Schärfemaß S(v), Suche 3 bis 25 m/s in 0,1-m/s-Schritten, Kriterium Maximum größer als das Dreifache des Medians).

## Umfang

**Gehört dazu:**

- Resampling des Signals von Empfangszeit auf ein gleichmäßiges te-Raster für einen Kandidaten v.
- Gemitteltes, median-normiertes Leistungsspektrum, Schärfemaß S(v).
- Suche über v, Maximum, Breite als Unsicherheit, Kriterium für "kein Ton".
- Einbindung in die Fusion: Regel festlegen, wie Variante 1 und 2 kombiniert werden (z. B. Variante 2 nur, wenn Variante 1 keinen Ton findet, oder gewichtetes Mittel), und dokumentieren.
- Konfigurationsschalter zum Aktivieren.

**Gehört nicht dazu:**

- Gemeinsame Ausgleichsrechnung (Task_19).

## Umsetzungsschritte

1. Resampling mit Interpolation (Fractional Delay aus Task_02 wiederverwenden).
2. Schärfemaß und Suchschleife implementieren; Laufzeit messen und ggf. grob-fein suchen.
3. Unsicherheit aus der Breite des Maximums ableiten.
4. Kombinationsregel mit Variante 1 festlegen und in der Fusion umsetzen.
5. Tests schreiben; echte Messreihen neu auswerten und Anteil A vorher/nachher vergleichen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Synthetische Vorbeifahrt mit schwachem Ton (unter der 8-dB-Schwelle von Variante 1): Variante 2 findet v_D innerhalb 2 km/h.
- Ohne Ton: Kriterium "kein Ton" greift.
- Bei korrektem v ist das entzerrte Spektrum schärfer als bei v ± 2 m/s (Test der Schärfefunktion).
- Fusion mit beiden Varianten liefert konsistente Klassen (Tabellen-Test erweitert).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Auf echten Daten ist der Anteil Klasse A mit und ohne Variante 2 verglichen und in `Roadmap/README.md` festgehalten.
- [ ] Live-Echtzeit aus Task_12 bleibt erhalten oder die Einschränkung ist dokumentiert und mit dem Nutzer abgestimmt.

## Offene Fragen / Annahmen

- Rechenaufwand auf dem Gerät ist unbekannt; ggf. nur offline oder mit gröberem Raster.

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

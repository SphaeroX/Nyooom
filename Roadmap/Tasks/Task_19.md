# Task_19: Gemeinsame Ausgleichsrechnung

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_19.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Als Verfeinerung werden Laufzeit- und Doppler-Daten in einer gemeinsamen Ausgleichsrechnung über v, d, t0 und die Grundfrequenzen angepasst (Kostenfunktion J aus PDF 5.5). Das Ergebnis wird mit der einfachen gewichteten Fusion verglichen und nur übernommen, wenn es nachweislich besser ist.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_17 und Task_18 archiviert.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitt 5.5 (Kostenfunktion J mit Laufzeitterm, Doppler-Term und Abstands-Prior), 6.2 (Fehlerbudget). Validierungswerkzeug aus Task_16.

## Umfang

**Gehört dazu:**

- Nichtlineare Ausgleichsrechnung über v, d, t0 und f0_k mit den drei Termen der Kostenfunktion J; Startwerte aus der bestehenden Fusion.
- Gewichte σ_Δ, σ_f, σ_d aus den Daten bzw. der Konfiguration.
- Unsicherheit aus der Kovarianz.
- Konfigurationsschalter: einfache Fusion oder gemeinsame Ausgleichsrechnung.
- Vergleich beider Verfahren mit dem Validierungswerkzeug (Task_16) auf synthetischen und, wenn vorhanden, echten Referenzdaten.

**Gehört nicht dazu:**

- Weitere Modellerweiterungen (Beschleunigung im Modell, ausgedehnte Quelle).

## Umsetzungsschritte

1. Löser aus Task_08 auf mehr Parameter verallgemeinern oder einen allgemeinen Levenberg-Marquardt-Löser bereitstellen.
2. Residuen und Jacobi-Matrix für alle drei Terme implementieren.
3. In die Pipeline als Option einbinden.
4. Vergleich durchführen und Entscheidung (Standardverfahren) mit Begründung dokumentieren.
5. Tests schreiben und grün bekommen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Synthetische Fahrten mit Ton: Die gemeinsame Ausgleichsrechnung findet v, d und t0 innerhalb der Toleranzen und ist nicht schlechter als die einfache Fusion.
- Ohne Ton: Fällt sauber auf das reine Laufzeitergebnis zurück.
- Konvergenz aus leicht falschen Startwerten (±20 % v, ±0,2 s t0).
- Kovarianz plausibel: σ_v sinkt mit besserem SNR.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Der Vergleich einfache Fusion gegenüber gemeinsamer Ausgleichsrechnung ist mit Zahlen in `Roadmap/README.md` festgehalten, und das Standardverfahren ist danach gewählt.
- [ ] Status in `Roadmap/README.md` zeigt die Roadmap als abgeschlossen, wenn kein Task mehr offen ist.

## Offene Fragen / Annahmen

- Ob sich der Aufwand lohnt, entscheidet der Vergleich. Bleibt die einfache Fusion gleich gut, wird sie Standard und die gemeinsame Ausgleichsrechnung bleibt als Option.

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

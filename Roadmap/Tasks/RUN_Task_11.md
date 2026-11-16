# Task_11: Beschleunigungsprüfung, Fusion, Klasse A

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_11.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Doppler- und Laufzeitschätzung werden nach PDF 5.4 (Beschleunigungsprüfung) und 5.5 (Abstandsprüfung, gewichtete Fusion) zusammengeführt. Jeder Datensatz bekommt seine endgültige Klasse A, B oder C nach 5.6, inklusive d_est.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_09 und Task_10 archiviert.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitte 5.4 (Prüfung auf Beschleunigung mit Zusatzterm g·(t−t0), Grenze 2 km/h), 5.5 (d_est = v_D/κ, Toleranz ±25 %, gewichtetes Mittel), 5.6 (Klassen), 6.2 (Fehlerbudget).

## Umfang

**Gehört dazu:**

- Zweite Regression mit Zusatzterm g·(t−t0); weicht v um mehr als 2 km/h ab, Doppler verwerfen (Grund "Beschleunigung").
- Abstandsprüfung: d_est innerhalb ±25 % des Sollabstands, sonst Doppler verwerfen (Grund "Abstandsprüfung").
- Gewichtete Fusion v und σ_v; Klasse A.
- Fallback auf Klasse B mit Grund (kein Ton, Beschleunigung, Abstandsprüfung).
- Datensatz-Felder `v`, `sigma_v`, `v_laufzeit`, `v_doppler`, `d_est`, `klasse`, `grund` vollständig befüllen.
- Ergebnisliste in der App zeigt Klasse A/B/C farblich und die Einzelschätzungen in der Detailansicht.

**Gehört nicht dazu:**

- Selbstkalibrierung mit d_est (Task_18).
- Gemeinsame Ausgleichsrechnung (Task_19).

## Umsetzungsschritte

1. Beschleunigungsprüfung als Erweiterung der Regression aus Task_10.
2. Abstandsprüfung und Fusion implementieren.
3. Klassenlogik zentral in einer Funktion bündeln (Eingabe: alle Teilergebnisse, Ausgabe: Klasse + Grund).
4. Pipeline und Persistenz erweitern; bestehende Messreihen neu auswerten können.
5. UI-Anpassungen.
6. Tests schreiben und grün bekommen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Synthetische konstante Fahrt mit Ton und seitlicher Abweichung 0,4 m: Klasse A, Fehler kleiner als bei reiner Laufzeit, d_est nahe am wahren Abstand.
- Synthetische Fahrt mit 0,5 m/s² Beschleunigung und Ton: Doppler wird verworfen, Klasse B mit Grund "Beschleunigung".
- Falscher Sollabstand (40 % daneben): Klasse B mit Grund "Abstandsprüfung".
- Fusionsformel: Zahlenbeispiel aus PDF 6.2 (σ_T 2,7 km/h, σ_D 1,9 km/h) ergibt σ_v ≈ 1,6 km/h.
- Klassenfunktion: Tabellen-Test über alle Kombinationen aus PDF 5.6.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Jeder Datensatz einer ausgewerteten Messreihe trägt Klasse und, bei B oder C, einen Grund.
- [ ] Auf echten Daten ist der Anteil A/B/C ermittelt und in `Roadmap/README.md` notiert.

## Offene Fragen / Annahmen

- E-Auto-Warntöne ändern die Tonhöhe mit der Geschwindigkeit; ob die Beschleunigungsprüfung das abfängt, zeigt erst die Validierung (Task_16).

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

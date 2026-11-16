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

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Eine echte Messreihe ergibt eine Ergebnisliste mit plausiblen Geschwindigkeiten (Ergebnis in den Notizen).
- [ ] Jeder Datensatz enthält alle Felder aus PDF 9.1; nicht belegte Doppler-Felder sind leer, nicht null-wertig falsch belegt.

## Offene Fragen / Annahmen

- Auf echten Daten ist keine Referenz vorhanden; die quantitative Prüfung folgt in Task_16.

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

# Task_07: Ereigniserkennung

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_07.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Aus einem fortlaufenden Stereo-Signal werden Vorbeifahrten nach PDF 5.1 erkannt: Pegelmaximum mindestens 10 dB über Grundpegel, Auswertefenster ±4 s, überlappende Fahrzeuge werden als Klasse C verworfen. Die Erkennung arbeitet blockweise, damit sie offline und später live funktioniert.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_02 archiviert (Konfiguration, Generator). Task_06 liefert Sichtprüfungs-Erfahrung mit echten Aufnahmen.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitt 5.1 (Vorverarbeitung und Ereigniserkennung), 9.1 (Felder `pegel`, `dauer`).

## Umfang

**Gehört dazu:**

- Hochpass 100 Hz auf beiden Kanälen (IIR, z. B. Butterworth 2. Ordnung; Wahl dokumentieren).
- Kurzzeitpegel im Band 500 bis 4000 Hz in 50-ms-Schritten, geglättet über 0,3 s.
- Grundpegel als gleitendes 20. Perzentil der letzten 60 s.
- Ereignis bei Maximum mindestens 10 dB über Grundpegel, Fenster −4 s bis +4 s.
- Überlappungsprüfung: zweites Maximum im Fenster weniger als 10 dB unter dem ersten → Ereignis Klasse C mit Grund "Überlappung".
- Ereignisobjekt mit Zeitpunkt des Maximums, Pegel über Grund, Dauer über halbem Maximalpegel, Fenstergrenzen.
- Streaming-fähige API (Blöcke rein, Ereignisse raus) plus Komfortfunktion für ganze Dateien.

**Gehört nicht dazu:**

- Laufzeit- und Doppler-Auswertung der Ereignisse (Task_08 ff.).
- Live-Einbindung in die Aufnahme (Task_12).

## Umsetzungsschritte

1. Filter implementieren (Hochpass, Bandpass für den Pegel).
2. Pegelberechnung und Glättung.
3. Gleitendes Perzentil effizient umsetzen (Ringpuffer).
4. Spitzenerkennung mit Schwelle, Fensterbildung und Überlappungsprüfung.
5. Streaming-API und Datei-Komfortfunktion.
6. Tests schreiben; an echten Aufnahmen aus Task_06 manuell gegen die Sichtprüfung abgleichen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Hochpass: 50 Hz deutlich gedämpft, 1 kHz praktisch unverändert.
- Synthetische Aufnahme mit drei Vorbeifahrten im Abstand von 10 s: genau drei Ereignisse, Zeitpunkte innerhalb von 0,2 s am wahren t0.
- Zwei Fahrzeuge mit 1 s Abstand und ähnlichem Pegel: ein Ereignis der Klasse C mit Grund "Überlappung".
- Leises Fahrzeug unter 10 dB über Grund: kein Ereignis.
- Streaming und Datei-Modus liefern identische Ereignisse.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Alle Schwellen und Zeiten kommen aus der Konfiguration.
- [ ] Auf einer echten Aufnahme werden die visuell erkennbaren Einzelvorbeifahrten gefunden (Ergebnis in den Notizen).

## Offene Fragen / Annahmen

- Annahme: Am Anfang einer Aufnahme (weniger als 60 s Historie) wird der Grundpegel aus der vorhandenen Historie gebildet; Verhalten dokumentieren.

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

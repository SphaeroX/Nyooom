# Task_15: GPS-Referenzfahrten

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_15.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Für die Validierung gibt es Referenzgeschwindigkeiten: Die App hat einen Logger-Modus, der auf einem zweiten Smartphone im Fahrzeug GPS-Position, Geschwindigkeit und Uhrzeit aufzeichnet, und sie kann GPX- oder CSV-Logs externer GPS-Logger importieren.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_04 archiviert (drift, Messreihen).
- **Relevantes Vorwissen:** `technik.pdf` Abschnitt 8.1 (Referenzfahrten mit Tempomat, GPS-Logger statt Tacho, Zuordnung per Uhrzeit auf 1 s genau).

## Umfang

**Gehört dazu:**

- Logger-Modus: Standortberechtigung, Aufzeichnung mit höchster Genauigkeit (Rate 1 Hz oder mehr), Speichern von Zeit (UTC), Position, GPS-Geschwindigkeit und Genauigkeitsangaben.
- Import von GPX (Trackpoints mit Zeit, Geschwindigkeit aus Extension oder aus Positionen abgeleitet) und einfacher CSV-Formate.
- Speicherung der Referenzfahrten in drift; Verknüpfung mit einem Standort optional.
- Ansicht einer Referenzaufzeichnung (Geschwindigkeit über Zeit).
- Hinweis zur Uhrzeitsynchronisation beider Geräte (Netzwerkzeit), Anzeige der Gerätezeitabweichung falls ermittelbar.

**Gehört nicht dazu:**

- Zuordnung zu Vorbeifahrten und Fehlerkennzahlen (Task_16).
- Video- oder Radarreferenz für Fremdfahrzeuge (PDF 8.2), nur Import der Werte später denkbar.

## Umsetzungsschritte

1. GPS-Paket wählen (z. B. `geolocator`) und Berechtigungen einrichten.
2. Logger-Bildschirm und Aufzeichnung im Hintergrund während der Fahrt.
3. GPX- und CSV-Parser; Geschwindigkeit aus Positionen ableiten, wenn kein Geschwindigkeitsfeld vorhanden ist.
4. Persistenz und Ansicht.
5. Tests schreiben; eine echte Testfahrt aufzeichnen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- GPX-Parser: Beispieldatei mit und ohne Geschwindigkeit; abgeleitete Geschwindigkeit stimmt bei gleichförmiger Bewegung.
- CSV-Parser: verschiedene Zeitformate, fehlerhafte Zeilen werden gemeldet.
- Persistenz-Roundtrip einer Referenzfahrt.
- Logger-Logik mit gemocktem Positionsstrom.
- Manuell: Logger 5 Minuten im Auto, Verlauf plausibel.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Eine echte GPS-Aufzeichnung und ein GPX-Import sind in der App sichtbar.

## Offene Fragen / Annahmen

- Annahme: Der Logger-Modus läuft auf einem zweiten Gerät mit derselben App. Alternativ nur Import; mit dem Nutzer abstimmen, falls kein Zweitgerät vorhanden ist.

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

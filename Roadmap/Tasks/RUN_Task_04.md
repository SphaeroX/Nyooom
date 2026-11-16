# Task_04: Messreihe anlegen und aufnehmen

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_04.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Nutzer können einen Standort mit allen Größen aus PDF 4.1 und 7.2 erfassen, eine Messreihe starten und die Rohaufnahme als WAV plus `metadata.json` speichern. Alle Stammdaten liegen in einer drift-Datenbank, auf der spätere Tasks aufbauen.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_01 archiviert (Aufnahme-Plugin, WAV-Writer). Task_02 liefert `c(T)` und Schrägabstand.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitte 4.1 (Aufstellung, was vor jeder Messreihe erfasst wird), 4.4 letzter Absatz (WAV + Metadaten), 7.2 (Abstand der Fahrspuren, Quellhöhe 0,3 m), 7.3 (Temperatur).

## Umfang

**Gehört dazu:**

- drift einrichten mit Tabellen für Gerät, Standort, Fahrspur (horizontaler Abstand, zugeordnete Fahrtrichtung +1/−1), Messreihe (Standort, Gerät, Temperatur, Mikrofonhöhe, Tempolimit, Startzeit, Pfad der Rohdaten) und Vorbeifahrt (Felder aus PDF 9.1, wird ab Task_09 befüllt).
- Migrationsstrategie von Anfang an (Schema-Version 1).
- Formular "Standort": Name, Fahrspuren mit Abstand und Richtung, Mikrofonhöhe, Tempolimit; Validierung (Abstand 3 bis 10 m mit Warnung außerhalb, Höhe 1,0 bis 1,5 m empfohlen).
- Formular "Messreihe starten": Standort wählen, Temperatur eingeben, berechnete c und Schrägabstände anzeigen.
- Aufnahme läuft, bis sie gestoppt wird; Speicherung als fortlaufende WAV (Streaming in Datei, nicht im Speicher) und `metadata.json` mit Gerätemodell, Audioquelle, Effektstatus, Abständen, Höhe, Temperatur, Kanalzuordnung, Startzeit (UTC, ms).
- Liste der Messreihen mit Dauer und Dateigröße, Löschen mit Rückfrage.

**Gehört nicht dazu:**

- Eignungsprüfung und Kalibrierung (Task_05); die Kanalzuordnung kommt bis dahin aus einer Voreinstellung.
- Auswertung der Aufnahme (ab Task_07).
- Export (Task_14).

## Umsetzungsschritte

1. drift und Code-Generierung einrichten, Schema anlegen, Datenzugriffsschicht (Repository) in reinem Dart.
2. Streaming-WAV-Writer: Header beim Stopp korrigieren, damit lange Aufnahmen nicht im Speicher liegen.
3. Metadatenmodell und JSON-Serialisierung.
4. UI für Standort, Messreihe, Aufnahme und Liste umsetzen.
5. Stoppen, App-Wechsel und Bildschirm aus abfangen (Aufnahme weiterlaufen lassen über Foreground-Service oder sauber abbrechen; Entscheidung dokumentieren).
6. Tests schreiben und grün bekommen; manuelle Geräte-Checkliste durchgehen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Repository-Tests mit In-Memory-drift: Standort mit zwei Spuren anlegen, Messreihe anlegen und laden, Löschen kaskadiert.
- Schrägabstand und c werden beim Anlegen korrekt aus den Eingaben berechnet (Werte aus PDF 3.1/3.5).
- Streaming-WAV-Writer: in Stücken geschriebene Datei ist gültig und identisch mit den Eingangsdaten.
- `metadata.json`: Roundtrip, alle Pflichtfelder vorhanden.
- Formularvalidierung: Widget-Tests für ungültige und grenzwertige Eingaben.
- Manuell: 2-minütige Aufnahme auf dem Gerät, Datei am PC prüfbar, Metadaten vollständig.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Eine Messreihe mit zwei Fahrspuren lässt sich anlegen, aufnehmen, stoppen und erscheint in der Liste; WAV und `metadata.json` liegen im Messreihen-Ordner.
- [ ] Eine 10-minütige Aufnahme verursacht keinen wachsenden Speicherverbrauch (manuell geprüft, Ergebnis in den Notizen).

## Offene Fragen / Annahmen

- Annahme: Rohaudio wird in dieser Entwicklungsphase immer gespeichert; die Option zum Abschalten kommt in Task_12.
- Offen: Foreground-Service für lange Aufnahmen ja/nein, im Task entscheiden und begründen.

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

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

- [x] `fvm flutter test tests/` läuft grün.
- [x] (Controller-Test mit Fake-Recorder; echtes Gerät → Task_20) Eine Messreihe mit zwei Fahrspuren lässt sich anlegen, aufnehmen, stoppen und erscheint in der Liste; WAV und `metadata.json` liegen im Messreihen-Ordner.
- [ ] (→ Task_20) Eine 10-minütige Aufnahme verursacht keinen wachsenden Speicherverbrauch (manuell geprüft, Ergebnis in den Notizen).

## Offene Fragen / Annahmen

- Annahme: Rohaudio wird in dieser Entwicklungsphase immer gespeichert; die Option zum Abschalten kommt in Task_12.
- Offen: Foreground-Service für lange Aufnahmen ja/nein, im Task entscheiden und begründen.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Entscheidung Foreground-Service: **nein** (vorerst). Die Aufnahme läuft, solange der App-Prozess lebt; der Aufnahmebildschirm verhindert das Zurücknavigieren während der Aufnahme (`PopScope`). Verhalten bei App-Wechsel/Bildschirm aus wird in Task_20 auf dem Gerät geprüft; falls Android die Aufnahme im Hintergrund abbricht, Foreground-Service vom Typ `microphone` nachrüsten.
- Speicher: WAV wird blockweise per `WavFileWriter` in die Datei geschrieben, nichts sammelt sich im Speicher. Messung auf dem Gerät → Task_20.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle automatisch prüfbaren Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** drift-Datenbank `NyooomDatabase` (`lib/data/database.dart`, Schema 1) mit Tabellen Devices, Calibrations, Sites, Lanes, MeasurementSeries, Passes (Spalten nach PDF 9.1, plus `grund_code`, `laneIndex`, `distanceUsedM`, `offsetS`). Repository `NyooomRepository`, Dateiablage `SeriesStorage` (`<Dokumente>/series/<id>/audio.wav` + `metadata.json`). Fachmodelle in `lib/core/site/site.dart` (SiteSpec, LaneSpec, validateSite) und `lib/core/series/series_metadata.dart`. UI: Home mit Tabs (Messreihen, Standorte, Gerät), Standortformular, Start-, Aufnahme- und Listenbildschirm. Zusätzlich (Simulationsentscheidung): `SimulatedStereoRecorder` und `TrafficGenerator`, umschaltbar beim Start einer Messreihe (Standard: Simulation an).
- **Learnings & Stolpersteine:** drift braucht `PRAGMA foreign_keys = ON` in `beforeOpen`, sonst greift die Kaskade nicht. sqlite3 3.x bringt die native Bibliothek per Build-Hook mit; Tests mit `NativeDatabase.memory()` laufen ohne Zusatzinstallation. Code-Generierung: `fvm dart run build_runner build -d`.
- **Wichtige Entscheidungen und ihre Gründe:** Kein Foreground-Service (siehe Notizen). Lateral-Spread der simulierten Fahrzeuge ist auf 2,5·σ_d begrenzt. Richtung → Spur ist eindeutig (Validierung verbietet zwei Spuren mit gleicher Richtung), weil die Auswertung die Spur aus der Fahrtrichtung ableitet (PDF 5.3).
- **Auswirkungen auf Folge-Tasks:** Task_05 schreibt in `Calibrations` (`addCalibration`), Messreihen übernehmen automatisch `latestCalibration`. Task_09 schreibt `Passes`. Task_12 hängt sich per `SeriesRecordingController.addBlockListener` in den Block-Strom und per `recordingExtrasProvider` in den Aufnahmebildschirm. Task_09 setzt `seriesOpenerProvider` für die Detailansicht. Neue Tabs über `homeTabsProvider`. Task_15/16 brauchen eine Migration auf Schema 2 (Referenzfahrten); `Sites` hat schon `latitude`/`longitude`.
- **Hinweise zu Tests und Befehlen:** Controller-Tests überschreiben `databaseProvider` (In-Memory), `seriesStorageProvider` (Temp-Ordner) und `recorderFactoryProvider` (FakeStereoRecorder).

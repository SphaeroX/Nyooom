# Task_14: Export

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_14.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Datensätze und Metadaten einer Messreihe lassen sich als CSV und JSON exportieren und über den Android-Teilen-Dialog weitergeben, damit Auswertungen auch außerhalb der App möglich sind.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_13 archiviert.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitt 9.1 (Felder und Einheiten, Schnittstelle zur späteren Nutzung), 1 letzter Absatz (im Betrieb verlässt nur der Ergebnisdatensatz die Auswertung).

## Umfang

**Gehört dazu:**

- CSV-Export der Datensätze mit den Feldnamen aus PDF 9.1 als Spaltenköpfe, Einheiten im Kopf oder in einer Begleitdatei; Dezimaltrennzeichen und Trennzeichen festlegen (Annahme: Punkt und Semikolon oder Komma, dokumentieren).
- JSON-Export: Messreihe mit Standort, Kalibrierung, Konfiguration und allen Datensätzen.
- Optional die Statistik-Zusammenfassung als zusätzlicher Abschnitt bzw. eigene Datei.
- Teilen über den Systemdialog (z. B. `share_plus`), optional ZIP mit WAV, wenn Rohaudio vorhanden.

**Gehört nicht dazu:**

- Import von Messreihen.
- Cloud-Upload.

## Umsetzungsschritte

1. Exportformate festlegen und in `Roadmap/README.md` dokumentieren.
2. CSV- und JSON-Serialisierer in reinem Dart.
3. ZIP-Erstellung für die Variante mit Rohaudio.
4. Teilen-Funktion in der UI anbinden.
5. Tests schreiben und grün bekommen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- CSV: Spaltenköpfe entsprechen PDF 9.1, leere Doppler-Felder bleiben leer, Sonderzeichen im Grund-Text werden korrekt maskiert.
- JSON: Roundtrip einer Messreihe ergibt identische Daten.
- ZIP enthält die erwarteten Dateien.
- Manuell: Export auf dem Gerät teilen und am PC in einer Tabellenkalkulation öffnen.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `fvm flutter test tests/` läuft grün.
- [ ] (→ Task_20) Ein Export einer echten Messreihe lässt sich am PC öffnen und enthält alle Datensätze (manuell geprüft).

## Offene Fragen / Annahmen

- Annahme zum CSV-Format (Trennzeichen, Dezimalzeichen) ggf. mit dem Nutzer abstimmen.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- CSV: Trennzeichen Semikolon, Dezimalpunkt, UTF-8, leere Felder für fehlende Werte, Spaltenköpfe exakt die 14 Felder aus 9.1 (`zeit` als ISO 8601 UTC). Einheiten in `einheiten.txt` und im JSON (`units`). In deutschem Excel: Daten → Aus Text/CSV, Trennzeichen Semikolon, Gebietsschema Englisch (wegen Dezimalpunkt). Gegebenenfalls mit dem Nutzer abstimmen (Task_20).
- JSON: `format: nyooom-series`, `version: 1`, Abschnitte `series`, `setup` (b, Δ0, Kanaltausch, c, Spuren), `config`, `statistics` (Kurzfassung), `records` (9.1-Namen plus `zeit_ms`, `offset_s`, `grund_code`, `spur`, `abstand`, `sigma_laufzeit`, `sigma_doppler`).
- ZIP: eigener Writer ohne Kompression (WAV komprimiert kaum), gestreamt mit CRC-Vorlauf, damit lange WAVs nicht in den Speicher müssen. `archive` nur als Dev-Abhängigkeit zum Prüfen im Test.
- Teilen über `share_plus` (Android-Teilen-Dialog), Dateien im temporären App-Ordner.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle automatisch prüfbaren Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** `lib/core/export/` (`passesToCsv`, `csvField`, `unitsText`, `SeriesExport` mit JSON-Roundtrip, `ZipWriter`/`Crc32`), `lib/data/series_export.dart` (`exportSeries`, `writeZipFile` gestreamt), UI `ExportButtons` in der Auswertung der Messreihe ("CSV + JSON teilen", "ZIP mit Rohaudio").
- **Learnings & Stolpersteine:** share_plus 13: `SharePlus.instance.share(ShareParams(files: [XFile(path)]))`.
- **Wichtige Entscheidungen und ihre Gründe:** Kein `archive` zur Laufzeit (eigener 100-Zeilen-ZIP-Writer genügt), Semikolon/Punkt für eindeutige Maschinenlesbarkeit.
- **Auswirkungen auf Folge-Tasks:** Task_16 exportiert Validierungsergebnisse mit `csvField` und demselben Format. `fileSharerProvider` ist in Tests überschreibbar.
- **Hinweise zu Tests und Befehlen:** `tests/core/export/`, `tests/data/series_export_test.dart`.

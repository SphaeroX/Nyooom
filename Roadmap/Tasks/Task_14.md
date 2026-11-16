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

- [ ] `fvm flutter test tests/` läuft grün.
- [ ] Ein Export einer echten Messreihe lässt sich am PC öffnen und enthält alle Datensätze (manuell geprüft).

## Offene Fragen / Annahmen

- Annahme zum CSV-Format (Trennzeichen, Dezimalzeichen) ggf. mit dem Nutzer abstimmen.

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

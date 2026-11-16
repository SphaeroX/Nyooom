# Task_02: Signalmodell und synthetische Vorbeifahrten

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_02.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Das Signalmodell aus der PDF steht als getestete Dart-Bibliothek bereit, alle Parameter aus Abschnitt 9.2 liegen in einer zentralen Konfiguration, und ein Generator erzeugt simulierte Stereo-Vorbeifahrten mit bekannter Wahrheit (v, d, t0, Richtung, Töne). Alle folgenden DSP-Tasks testen gegen diese Fixtures.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_01 archiviert (Projektstruktur, WAV-Writer/Reader).
- **Relevantes Vorwissen:** `technik.pdf` Abschnitte 3.1 bis 3.5 (Geometrie, Laufzeitdifferenz, Doppler, Fusionsbeziehung, Schallgeschwindigkeit), 9.2 (Startwerte der Parameter).

## Umfang

**Gehört dazu:**

- Konfigurationsobjekt mit allen Parametern aus PDF 9.2 inklusive Defaults, serialisierbar als JSON (Datei als Asset oder im App-Ordner).
- Funktionen: `c(T)`, Schrägabstand `d = sqrt(dh² + Δh²)`, `u(te)`, `r(te)`, Empfangszeit `t = te + r/c`, Umrechnung te-Raster → t per Interpolation, TDOA `Δ(t) = b/c·u + Δ0`, Doppler `f = f0/(1 + v/c·u)`.
- Generator für synthetische Vorbeifahrten: Punktquelle mit breitbandigem Rauschen plus optional harmonischen Tönen, Ausbreitung zu zwei Mikrofonen im Abstand b (exakte Laufzeit je Mikrofon, 1/r-Dämpfung), Hintergrundrauschen mit wählbarem SNR, Ausgabe als zwei Float-Kanäle und optional WAV.
- Optionen im Generator: Fahrtrichtung, Beschleunigung, Zeitversatz zwischen Tonquelle und Rauschquelle, zweites überlappendes Fahrzeug, Kanalversatz Δ0.
- Struktur `GroundTruth` mit allen wahren Größen für Tests.

**Gehört nicht dazu:**

- FFT und Kreuzkorrelation (Task_03).
- Auswertealgorithmen jeder Art (ab Task_03).
- UI.

## Umsetzungsschritte

1. Konfigurationsklasse mit allen Parametern aus PDF 9.2 anlegen, JSON laden/speichern, Default-Datei ablegen.
2. Geometrie- und Modellfunktionen in `lib/core/` (reines Dart) implementieren.
3. Fractional-Delay-Verfahren für den Generator wählen (z. B. gefensterter Sinc-Interpolator), damit Laufzeitunterschiede unter einem Abtastwert korrekt entstehen.
4. Generator implementieren: Abstrahlsignal auf feinem te-Raster erzeugen, für jedes Mikrofon die Empfangszeit berechnen und auf das 48-kHz-Raster resamplen.
5. Töne mit Frequenz f0 und Harmonischen im Abstrahlsignal erzeugen, sodass Doppler automatisch korrekt entsteht.
6. Optionen für Beschleunigung, Überlappung, Δ0 und Versatz der Tonquelle ergänzen.
7. Tests schreiben und grün bekommen; einige Standard-Szenarien als wiederverwendbare Fixture-Fabrik bereitstellen (z. B. 30 km/h bei 5 m, 50 km/h bei 4 m).

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- `c(T)`: 0 °C ergibt 331,3 m/s, 20 °C ca. 343,2 m/s.
- `u(te)` ist bei te = t0 null, monoton, strebt gegen ±1; Vorzeichen folgt der Fahrtrichtung.
- Größenordnungen aus PDF 3.5 werden reproduziert: b/c = 437 µs bei b = 0,15 m; Steigung von Δ bei t0 = 0,73 ms/s für 30 km/h und d = 5 m; Frequenzsprung 5,0 % bzw. 8,4 %.
- Fusionsbeziehung 3.4: Aus modellierten Δ(t) und f(t) ergibt die Gerade 1/f über Δ exakt v = b·B/A.
- Generator: Die tatsächliche Kanalverzögerung zu einem Zeitpunkt (gemessen per Brute-Force-Kreuzkorrelation im Test) entspricht dem Modell auf besser als 2 µs; die Tonfrequenz weit vor und nach der Vorbeifahrt entspricht f_an bzw. f_ab.
- Konfiguration: JSON-Roundtrip erhält alle Werte; Defaults entsprechen PDF 9.2.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `fvm flutter test tests/` läuft grün, inklusive aller oben genannten Tests.
- [ ] Alle Parameter aus PDF 9.2 sind in der Konfiguration vorhanden und kein Zahlenwert davon ist an anderer Stelle im Code hart kodiert.
- [ ] Fixture-Fabrik liefert mindestens die Szenarien 30 km/h/5 m und 50 km/h/4 m in beiden Richtungen, mit und ohne Ton.
- [ ] Die Generator-API ist in `Roadmap/README.md` kurz beschrieben, damit Folge-Tasks sie finden.

## Offene Fragen / Annahmen

- Annahme: Ein vereinfachtes Quellenmodell (Punktquelle, kein ausgedehntes Fahrzeug, keine Reflexionen) genügt für Unit-Tests. Echte Aufnahmen kommen später als zusätzliche Fixtures hinzu.
- Laufzeit des Generators in Tests im Blick behalten (8-s-Fenster bei 48 kHz); bei Bedarf kürzere Szenarien oder niedrigere Rate nur in Tests verwenden und das dokumentieren.

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

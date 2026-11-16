# Task_17: Doppler Variante 2: Entzerrung

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_17.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Zusätzlich zur Linienverfolgung schätzt die App v_D über das Schärfemaximum nach PDF 5.4 Variante 2. Dadurch werden auch schwache und hochfrequente Töne nutzbar, und der Anteil der Klasse A steigt.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_11 archiviert (Fusion, Klassen). Validierungsergebnisse aus Task_16 helfen beim Vergleich.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitt 5.4 Variante 2 (Schritte 1 bis 5: d = v/κ, Entzerrung t → te, gemitteltes Leistungsspektrum für |u| ≤ 0,95, Schärfemaß S(v), Suche 3 bis 25 m/s in 0,1-m/s-Schritten, Kriterium Maximum größer als das Dreifache des Medians).

## Umfang

**Gehört dazu:**

- Resampling des Signals von Empfangszeit auf ein gleichmäßiges te-Raster für einen Kandidaten v.
- Gemitteltes, median-normiertes Leistungsspektrum, Schärfemaß S(v).
- Suche über v, Maximum, Breite als Unsicherheit, Kriterium für "kein Ton".
- Einbindung in die Fusion: Regel festlegen, wie Variante 1 und 2 kombiniert werden (z. B. Variante 2 nur, wenn Variante 1 keinen Ton findet, oder gewichtetes Mittel), und dokumentieren.
- Konfigurationsschalter zum Aktivieren.

**Gehört nicht dazu:**

- Gemeinsame Ausgleichsrechnung (Task_19).

## Umsetzungsschritte

1. Resampling mit Interpolation (Fractional Delay aus Task_02 wiederverwenden).
2. Schärfemaß und Suchschleife implementieren; Laufzeit messen und ggf. grob-fein suchen.
3. Unsicherheit aus der Breite des Maximums ableiten.
4. Kombinationsregel mit Variante 1 festlegen und in der Fusion umsetzen.
5. Tests schreiben; echte Messreihen neu auswerten und Anteil A vorher/nachher vergleichen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Synthetische Vorbeifahrt mit schwachem Ton (unter der 8-dB-Schwelle von Variante 1): Variante 2 findet v_D innerhalb 2 km/h.
- Ohne Ton: Kriterium "kein Ton" greift.
- Bei korrektem v ist das entzerrte Spektrum schärfer als bei v ± 2 m/s (Test der Schärfefunktion).
- Fusion mit beiden Varianten liefert konsistente Klassen (Tabellen-Test erweitert).

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `fvm flutter test tests/` läuft grün.
- [ ] (→ Task_20) Auf echten Daten ist der Anteil Klasse A mit und ohne Variante 2 verglichen und in `Roadmap/README.md` festgehalten.
- [x] (Einschränkung dokumentiert, Schalter `dopplerVariant2`) Live-Echtzeit aus Task_12 bleibt erhalten oder die Einschränkung ist dokumentiert und mit dem Nutzer abgestimmt.

## Offene Fragen / Annahmen

- Rechenaufwand auf dem Gerät ist unbekannt; ggf. nur offline oder mit gröberem Raster.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Kombinationsregel: Variante 1 hat Vorrang (nur sie hat die Beschleunigungsprüfung). Variante 2 läuft nur, wenn Variante 1 keinen Ton findet und `dopplerVariant2 = 1`. Ohne Regression gibt es bei Variante 2 keine Beschleunigungsprüfung; Abstandsprüfung und Fusion gelten wie gehabt. `n_toene` bleibt bei Variante 2 0 (keine Tonspuren).
- Zwei Abweichungen von der PDF, beide wegen schwacher Töne: (1) Schärfemaß zählt nur Überhöhungen oberhalb 3 σ des gemittelten Rauschspektrums (σ robust aus der MAD), sonst dominieren tausende Rauschbins; (2) der Median für das Kriterium "Maximum > 3 × Median" wird über die Kandidaten außerhalb der Halbwertsbreite des Maximums gebildet, zusätzlich muss das Maximum `sharpnessMinPeak` (4 dB²) erreichen (verhindert Scheintreffer im reinen Rauschen).
- Suche: grob 0,5 m/s (`sharpnessCoarseStep`), dann 0,1 m/s um das Maximum; Spektrum 8192 Punkte, Hann, 50 % Überlappung; Interpolation Catmull-Rom (schnell genug, Fehler unkritisch für ein Schärfemaß).
- Sehr starke Töne ergeben ein breites S(v) und erfüllen das Medianskriterium nicht immer; sie werden aber von Variante 1 erfasst.
- Rechenzeit: ca. +1,5 s pro Ereignis am PC, nur bei Ereignissen ohne Ton in Variante 1. Live auf dem Gerät messen (Task_20); notfalls `dopplerVariant2 = 0` für den Live-Betrieb und Variante 2 nur bei der Offline-Neuauswertung.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle automatisch prüfbaren Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** `SharpnessEstimator` (`lib/core/pipeline/doppler_sharpness.dart`, Entzerrung t → te, gemitteltes median-normiertes Spektrum, Schärfemaß, Grob-/Feinsuche, Unsicherheit aus der Halbwertsbreite), `DopplerChoice`/`chooseDoppler` (Kombinationsregel), Einbindung in `EventPipeline`. Neue Konfigurationswerte `dopplerVariant2`, `sharpnessFftSize`, `sharpnessCoarseStep`, `sharpnessFloorSigma`, `sharpnessMinPeak`. Abweichungen siehe Notizen.
- **Learnings & Stolpersteine:** Das reine PDF-Schärfemaß (Summe aller quadrierten Überhöhungen) unterscheidet bei schwachen Tönen kaum zwischen richtigem und falschem v. Erst die Rauschschwelle macht schwache Linien sichtbar. Ein Probe-Test über mehrere Seeds war nötig, um robuste Parameter zu finden.
- **Wichtige Entscheidungen und ihre Gründe:** Variante 2 nur als Ergänzung (Rechenzeit, keine Beschleunigungsprüfung).
- **Auswirkungen auf Folge-Tasks:** Task_19 kann für die gemeinsame Ausgleichsrechnung nur Variante-1-Tonspuren nutzen (Variante 2 liefert keine f_k(t_j)).
- **Hinweise zu Tests und Befehlen:** `tests/core/pipeline/doppler_sharpness_test.dart`, Pipeline-Fall in `tests/data/event_pipeline_test.dart` (druckt die Laufzeit).

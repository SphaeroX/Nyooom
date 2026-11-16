# Task_08: Anpassung des Bewegungsmodells

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_08.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Für ein erkanntes Ereignis werden κ = v/d und t0 aus dem Korrelogramm geschätzt: Grobsuche über ein Raster und robuste gewichtete Feinanpassung nach PDF 5.3. Ergebnis sind κ mit Standardabweichung, t0, Reststreuung und Fahrtrichtung.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_03 (Korrelogramm, Blockmaxima) und Task_07 (Ereignisfenster) archiviert.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitte 3.1/3.2 (Modell inklusive Schalllaufzeit), 5.3 (Grobsuche: κ von −8 bis +8 1/s ohne Bereich um null, t0 in 20-ms-Schritten ±1 s; Feinanpassung mit Huber-Verlust, Ausreißergrenze 40 µs).

## Umfang

**Gehört dazu:**

- Modellkurve Δ(t; κ, t0) mit fester Amplitude b/c und Δ0 aus der Kalibrierung, unter Berücksichtigung der Schalllaufzeit mit dem Sollabstand der Spur (te-Raster, Interpolation auf t).
- Grobsuche: Summe von R entlang der Modellkurve für jedes Rasterpaar, Maximum als Startwert.
- Feinanpassung: gewichtete nichtlineare Ausgleichsrechnung (Gauss-Newton oder Levenberg-Marquardt mit IRLS für Huber), Ausschluss von Punkten mehr als 40 µs neben der Startkurve.
- Kovarianz → σκ; Reststreuung in µs; Richtung aus Vorzeichen von κ.
- Gültigkeitsprüfungen für Klasse C: Spur nicht monoton, Reststreuung über 30 µs, κ außerhalb des Suchbereichs.

**Gehört nicht dazu:**

- Umrechnung in v und Klassenzuordnung im Datensatz (Task_09).
- Doppler (Task_10).

## Umsetzungsschritte

1. Modellkurve mit Schalllaufzeit implementieren (wiederverwendet Funktionen aus Task_02).
2. Grobsuche über das Korrelogramm implementieren und auf Laufzeit achten.
3. Kleinen Löser für nichtlineare Ausgleichsrechnung mit Huber-Gewichten in reinem Dart schreiben.
4. Kovarianz und Unsicherheiten berechnen.
5. Gültigkeitsprüfungen ergänzen.
6. Tests schreiben und grün bekommen.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Synthetisch 30 km/h bei 5 m und 50 km/h bei 4 m, beide Richtungen: κ auf 3 % genau, t0 auf 20 ms genau, Richtung korrekt.
- Mit starken Ausreißern in den Blockmaxima: Ergebnis bleibt innerhalb der Toleranz (Robustheit).
- Reines Rauschen ohne Quelle: Klasse-C-Grund wird gesetzt.
- σκ ist bei niedrigem SNR größer als bei hohem.
- Schalllaufzeit ein/aus: Ohne Berücksichtigung entsteht messbar ein Fehler in t0 bzw. eine Asymmetrie, mit Berücksichtigung nicht.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `fvm flutter test tests/` läuft grün.
- [x] Alle Raster, Grenzen und Schwellen stammen aus der Konfiguration.
- [x] Die Laufzeit pro Ereignis ist gemessen und in den Erkenntnissen notiert (Grundlage für Task_12).

## Offene Fragen / Annahmen

- Lange Fahrzeuge (mehrere Spuren im Korrelogramm) und Kurvenfahrt werden nur über Reststreuung bzw. Monotonie abgefangen, nicht speziell modelliert (PDF 6.1).

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Laufzeit pro Ereignis (8-s-Fenster, Grobsuche 302 κ × 101 t0 × 742 Blöcke plus Feinanpassung): **666 ms** auf dem Entwicklungsrechner (JIT). Zusammen mit dem Korrelogramm (125 ms) ca. 0,8 s pro Ereignis.
- Schalllaufzeit wird geschlossen gelöst: aus t − t0 = τ + √(d² + v²τ²)/c folgt eine quadratische Gleichung in τ (keine Iteration nötig).
- Kovarianz: Gewichte auf Mittelwert 1 normiert, s² = Σw·r²/(n−2), mit Faktor Blocklänge/Vorschub (= 4) aufgeblasen, weil sich überlappende Blöcke korrelieren.
- "Spur nicht monoton": Anteil der starken Blöcke (Gewicht ≥ 0,5·Maximum), die innerhalb der Ausreißergrenze auf der angepassten S-Kurve liegen, unter `monotonicMinFraction` (0,8).
- Neue Konfigurationswerte: `fitHuberDeltaS` (10 µs), `fitMinPoints` (12), `kappaGridStep` (0,05 1/s).

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** `MotionFitter` (`lib/core/pipeline/motion_fit.dart`): Grobsuche über κ ∈ ±[0,5; 8] (Schritt 0,05) und t0 = Pegelmaximum ± 1 s (20 ms), robuste gewichtete LM-Feinanpassung mit Huber-IRLS, Ausreißergrenze 40 µs zur Startkurve, Kovarianz → σκ, σt0, Reststreuung, Gültigkeitsprüfungen. `MotionFit` mit `reason` (`DowngradeReason` in `lib/core/pipeline/reasons.dart`, mit `code` für `grund_code` und deutschem `text`). Option `includePropagation` nur für den Vergleichstest.
- **Learnings & Stolpersteine:** t0 im Ergebnis ist die Abstrahlzeit (Modell inkl. r/c). Ohne Schalllaufzeit läge t0 um d/c (≈15–20 ms) zu spät. Reines Rauschen endet meist als "keine Laufzeitspur" (zu wenige Blockmaxima an der Startkurve).
- **Wichtige Entscheidungen und ihre Gründe:** Grobsuche mit voller Rasterauflösung (schnell genug), damit kein lokales Optimum gewählt wird. Huber-δ = 10 µs (etwa die typische Streuung der Blockmaxima bei mäßigem SNR).
- **Auswirkungen auf Folge-Tasks:** Task_09: `fit.kappa` · d_Spur = v_T, σ_T aus `sigmaKappa` und `lateralSpreadM`; `fit.reason` → Klasse C; `fit.residualS` → `rest_laufzeit`. Task_10: u(t) über `fitter.tdoaAt` bzw. `(tdoaAt − Δ0)/(b/c)`. Task_12: ca. 0,8 s Rechenzeit pro Ereignis am PC.
- **Hinweise zu Tests und Befehlen:** `tests/core/pipeline/motion_fit_test.dart` (der Benchmark-Test druckt die Laufzeit).

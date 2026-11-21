# Messverfahren: Prüfung und Ergänzungen zu technik.pdf

> Wann lesen: bevor du an Ereigniserkennung, Laufzeitanpassung, Doppler, Fusion oder Zählung etwas änderst, und bevor du Messungen am Fenster oder bei dichtem Verkehr beurteilst.

`technik.pdf` bleibt die fachliche Referenz. Diese Datei hält fest, was die Prüfung des Konzepts (2026-11-16, nach Task_19) ergeben hat und wo der Code bewusst über die PDF hinausgeht. Alle Zahlen stammen aus der Simulation; echte Aufnahmen stehen noch aus (Task_20).

## Geprüft und in Ordnung

- Signalmodell 3.1 bis 3.4: u(te), t = te + r/c, Δ = b/c·u + Δ0, f = f0/(1 + v/c·u), df/dt bei t0, Fusionsgerade 1/f über Δ. Die Fusionsbeziehung gilt mit Höhenunterschied exakt, weil d überall der Schrägabstand ist.
- Zahlen in 3.5 nachgerechnet (κ, Steigung von Δ, Dauer für u von −0,9 bis +0,9, Frequenzsprung, Änderungsrate, 1,6 Hz pro km/h, c(T)).
- Vorzeichen: Δ = Ankunft links minus rechts, positive Geschwindigkeit in +x; Simulator, GCC-PHAT, Anpassung und Kalibrierung verwenden dieselbe Konvention.
- Die Schalllaufzeit ist im Modell geschlossen gelöst (`directionCosineAt`), t0 ist überall die Abstrahlzeit.
- Die Doppler-Regression rechnet mit ln(1 + v/c·u) exakt, nicht mit der linearen Näherung aus 5.4.
- V85-Korrektur 8.3 (0,7 km/h bei 6 und 3 km/h) stimmt.

## Gefundene Schwächen und was geändert wurde

### 1. Fahrzeuge mit weniger als 4 s Abstand gingen verloren

Abschnitt 1 verspricht Messungen ab 3 s Abstand, 5.1 verwirft aber jedes Fenster (±4 s) mit einem zweiten Pegelmaximum. Zwei Fahrzeuge ergaben deshalb einen einzigen Datensatz der Klasse C: keine Geschwindigkeit und nur ein gezähltes Fahrzeug. Gegenverkehr zur selben Zeit (ein gemeinsames Pegelmaximum) ergab einen Datensatz für das nähere Fahrzeug, das zweite fehlte ganz.

**Jetzt: Spurtrennung im Korrelogramm.**

- `EventDetector(secondaryEvents: true)` meldet jedes ausgeprägte Pegelmaximum über der Schwelle als eigenes Ereignis, nicht nur das größte des Fensters. Die Auswertung nach dem Buchstaben von 5.1 (`detectEvents`, `EventEvaluator.analyse`) bleibt für Vergleiche erhalten.
- `EventEvaluator.analyseTracks` sucht t0 nur bis zur Mitte zwischen benachbarten Pegelmaxima (Maxima näher als `trackMinSeparationS` zählen nicht als Nachbarn, das sind Pegelwellen desselben Fahrzeugs).
- Danach wird die gefundene Spur ausgeblendet (`trackMaskWidthS`) und in der Gegenrichtung noch einmal gesucht. So wird Gegenverkehr zur selben Zeit gefunden.
- `TrackDeduplicator`: Zwei Spuren gleicher Richtung mit weniger als `duplicateWindowS` (0,5 s) Abstand in t0 sind dasselbe Fahrzeug. Bei 30 km/h wären das 4 m, weniger als eine Fahrzeuglänge.
- Ein Nebenmaximum ohne eigene gültige Spur ergibt keinen Datensatz. Eine Überlappung, die sich nicht auflösen lässt, bleibt Klasse C „Überlappung".

### 2. Ein Nachbar im Fenster machte die Spur „nicht monoton"

Die PHAT-Gewichtung macht jede kohärente Quelle zu einem Maximum ähnlicher Höhe, egal wie leise sie ist. Die alte Prüfung zählte „starke Blöcke neben der Kurve" über das ganze Fenster und verwarf damit das leisere von zwei Fahrzeugen auch bei 5 s Abstand.

**Jetzt:** Pro Block zählt das lokale Maximum neben der Kurve (innerhalb der Ausreißergrenze von 40 µs), nicht das größte des Blocks. Beurteilt wird eine Spur nur um ihre eigene größte Annäherung (|u| ≤ `trackCoreDirectionCosine`): mittlere Korrelation entlang der Kurve mindestens `trackMinStrength`, Reststreuung wie bisher, Anteil der Blöcke mit Maximum auf der Kurve mindestens `monotonicMinFraction`. Ist ein zweites Fahrzeug im Fenster bekannt, werden Blöcke nicht gewertet, in denen eine andere Quelle dominiert. Ohne zweites Fahrzeug gilt die strenge Regel weiter: Ein Fahrzeug, das anhält oder abbiegt, bleibt „nicht monoton".

Eine Quelle mit fester Richtung (Maschine, Gespräch) ergibt keine Spur mehr: Im Bereich der Annäherung liegt dort keine Korrelation.

### 3. Doppler: steigender Ton und fremde Töne

- Die Regression lieferte |v|. Ein Ton, der gegen das Modell steigt (Gasgeben, fremde Quelle), wurde so zu einer scheinbaren Geschwindigkeit. Jetzt setzt `DopplerResult.frequencyRises` denselben Befund wie die Beschleunigungsprüfung: Klasse B, Grund „Beschleunigung".
- Töne anderer Fahrzeuge sind während der Vorbeifahrt hörbar. Weit vor und nach der Vorbeifahrt zeigt ein Ton nur seine beiden Grenzfrequenzen, und die sind bei ähnlicher Geschwindigkeit für jedes Fahrzeug gleich. `ToneGate` prüft deshalb jede Tonspur einzeln im Bereich |u| ≤ 0,95: Ihre Geschwindigkeit geteilt durch |κ| muss zum Spurabstand passen (Toleranz wie 5.5 plus 2 σ). Besteht keine Spur, bleiben alle, damit die Abstandsprüfung der Fusion den Wert noch sieht.
- Fahren zwei Fahrzeuge gleichzeitig vorbei (zweite Spur im selben Fenster), wird Doppler nicht ausgewertet: Klasse B, Grund „Ton nicht zuordenbar (zweites Fahrzeug)" (`ton_mehrdeutig`).

### 4. Spiegelbild an einer Seitenwand

Eine Wand quer zur Fahrbahn (Fensterlaibung) spiegelt die Quelle so, dass sie scheinbar in die Gegenrichtung fährt, mit gleichem |κ| und gleichem t0. Eine zweite Spur mit diesen Eigenschaften (`mirrorKappaTolerance`, `mirrorT0ToleranceS`) wird nicht als Fahrzeug gezählt. Reflexionen an Boden und an Wänden parallel zur Fahrbahn verfälschen Δ in erster Näherung nicht, ihre Spur läuft in Fahrtrichtung und fällt unter die Dublettenregel.

### 5. Beidseitig befahrene Spur (Seitengasse)

In einer schmalen Gasse fahren beide Richtungen auf derselben Spur, also im selben Abstand zum Gerät. Eine Spur kann dafür die Richtung `LaneSpec.twoWay` (0, Anzeige ⇄) bekommen. `SiteSpec.laneForDirection` und `AnalysisSetup.laneFor` liefern sie für +1 und −1; die Richtung des Datensatzes kommt weiter aus dem Vorzeichen von κ. Eine beidseitige Spur muss die einzige Spur des Standorts sein, sonst wäre die Zuordnung Richtung → Spur mehrdeutig (`validateSite` meldet einen Fehler). Die Selbstkalibrierung (7.4) lernt den Abstand aus beiden Richtungen, weil sie nach `laneIndex` gruppiert. In der Datenbank steht 0 in `lanes.direction`, eine Migration ist nicht nötig.

### 6. Fortgesetzte Messreihe: Naht in der Aufnahme

Eine fortgesetzte Messreihe ist eine einzige WAV, die Abschnitte liegen direkt hintereinander. An der Naht springt der Pegel, und ein Fahrzeug, das in der Pause vorbeifuhr, fehlt. Die Ereigniserkennung kann an der Naht ein Fenster aus zwei Abschnitten bilden; das Ergebnis ist dann meist Klasse C oder fällt unter die Dublettenregel. Die Uhrzeit eines Datensatzes kommt aus dem Abschnitt, in dem t0 liegt (`AnalysisSetup.utcMsAt`). Die Live-Auswertung beginnt nach dem Fortsetzen neu (leerer Ringpuffer), eine Vorbeifahrt genau an der Naht wird deshalb live nicht ausgewertet.

## Wirkung in der Simulation

Zufallsverkehr auf zwei Spuren, 2 Minuten, seitliche Streuung 0,4 m, 10 % beschleunigend:

| Mittlerer Abstand | Fahrzeuge | vorher gemessen | jetzt gemessen | erfundene Fahrzeuge |
|---|---|---|---|---|
| 4,5 s (sehr dicht, zwei Läufe) | 45 | 6 | 38 | 0 |
| 8 s | 15 | nicht ermittelt | 15 | 0 |
| 14 s | 7 | nicht ermittelt | 7 | 0 |

Der Fehler von κ liegt bei etwa 1 % (quadratisches Mittel). Der Fehler der Geschwindigkeit in Klasse B kommt wie in 6.2 fast ganz aus der seitlichen Lage in der Spur.

## Bekannte Grenzen (nicht geändert, weil Startwerte der PDF)

- **Grundpegel bei Dauerverkehr.** Der Grundpegel ist das 20. Perzentil der letzten 60 s. Ist fast immer ein Fahrzeug zu hören, steigt er, und leise oder entfernte Fahrzeuge erreichen die 10 dB nicht. Bei 4,5 s mittlerem Abstand fehlten 7 von 45 Fahrzeugen; im genauer untersuchten Lauf hatten 4 von 5 fehlenden gar kein Pegelereignis. Die Zählung ist dann eine untere Grenze. Stellgrößen: `noiseFloorPercentile`, `noiseFloorHistoryS`, `eventThresholdDb`.
- **Suchbereich κ.** Mit `kappaMin` = 0,5 1/s ist die kleinste messbare Geschwindigkeit 0,5·d: 9 km/h bei 5 m, 18 km/h bei 10 m. Der Auslegungsbereich aus Abschnitt 1 (15 km/h in 10 m, κ = 0,42) ist damit nicht ganz abgedeckt. Langsame Fahrzeuge in großer Entfernung werden Klasse C „außerhalb des Suchbereichs" und fehlen in der Statistik.
- **Selbstkalibrierung 7.4.** Gelernt wird nur aus Klasse A, und Klasse A hat die Abstandsprüfung (±25 %) schon bestanden. Die Warnung ab 20 % Abweichung kann deshalb nur zwischen 20 und 25 % auslösen. Liegt der wirksame Abstand weiter daneben, entsteht stattdessen viel Klasse B mit Grund „Abstandsprüfung". Dieser Anteil ist das eigentliche Warnsignal.
- **Seitliche Streuung σd.** σd = 0,4 m ist eine horizontale Streuung. Im Schrägabstand wirkt sie mit dem Faktor dh/d. Bei der Aufstellung aus 4.1 ist das 2 %, bei 4 m Höhenunterschied und 6 m Abstand 17 %, σT wird dann etwas zu groß angesetzt.
- **Beschleunigungsprüfung.** Bei dichtem Verkehr schlägt sie öfter fälschlich an (Klasse B statt A). Die Geschwindigkeit bleibt gültig, nur ohne Doppler-Anteil.
- **Rechenzeit.** Etwa 2 s pro Ereignis am PC, der größte Teil ist die Doppler-Auswertung. Mit Nebenmaxima gibt es mehr Ereignisse. Im Live-Betrieb verwirft die Warteschlange Ereignisse, wenn das Gerät nicht nachkommt (`dropped`), das verfälscht die Zählung nach unten.

## Aufstellung auf dem Fenstersims

- Die Höhe geht nur über den Schrägabstand ein. Am Standort die echte Mikrofonhöhe über der Fahrbahn und den horizontalen Abstand zur Spurmitte eintragen; die Warnung „empfohlen 1,0 bis 1,5 m" ist nur ein Hinweis.
- Fenster offen oder Gerät außen: Durch die Scheibe kommt zu wenig vom Band 300 Hz bis 8 kHz an.
- Lange Kante parallel zur Fahrbahn, beide Mikrofonöffnungen frei. Möglichst weit vorn am Sims, damit die Laibung nicht seitlich neben den Mikrofonen steht (Spiegelspur, siehe oben).
- b und Δ0 in genau dieser Lage kalibrieren. Die Auflagefläche kann den wirksamen Mikrofonabstand ändern.
- Größerer Abstand heißt kleineres κ und leisere Fahrzeuge: siehe Suchbereich κ und Grundpegel.
- An der Fassade ist es oft windiger als am Stativ. Windschutz verwenden.

## Externe Mikrofone (USB, Funk-Ansteckmikrofone)

- Ob ein Gerät Stereo liefert, entscheidet die Aufnahme, nicht die Geräteangabe. `AudioDeviceInfo.getChannelCounts()` ist nur ein Hinweis; die App zeigt ihn an („Android meldet: …“), sperrt aber nichts. Der Pegeltest prüft jede Sekunde mit `analyseStereoContent` (`lib/core/signal/stereo_content.dart`): Korrelation bei Verschiebung 0 ab 0,999 → identische Kanäle (doppeltes Mono), ein Kanal mehr als 30 dB leiser → stummer Kanal, sonst echtes Stereo. Die Kalibrierprüfung 1 (zwei getrennte Maxima) bleibt der eigentliche Nachweis.
- Funkempfänger mit zwei Sendern mischen über USB-C oft beide Sender auf Mono, solange sie nicht in den Stereo-Modus geschaltet sind. Dann sind beide Kanäle identisch. Abhilfe am Empfänger, nicht in der App.
- Zwei Ansteckmikrofone dürfen weiter auseinander stehen als die Telefonmikrofone. Der Kalibrier-Assistent sucht bei externen Eingängen bis b = 1 m (`DeviceCheckLimits.externalMaxMicSpacing`, statt 0,3 m). Empfohlen sind 10 bis 50 cm: Das Modell Δ = b/c·u ist eine Fernfeld-Näherung, b muss klein gegen den Spurabstand bleiben (`spacingHint`).
- Bei Funkstrecken kann sich die Laufzeitdifferenz der beiden Sender nach dem Neukoppeln ändern. Δ0 deshalb nach jedem Einschalten neu kalibrieren; die Mikrofone fest montieren (Stange), denn b gilt nur für diese Aufstellung.

## Parameter der Spurtrennung

| Parameter | Startwert | Bedeutung |
|---|---|---|
| `trackCoreDirectionCosine` | 0,9 | Bereich \|u\|, in dem eine Spur beurteilt wird |
| `trackMinStrength` | 0,15 | Mindestwert der mittleren Korrelation entlang der Kurve |
| `trackMaskWidthS` | 60 µs | halbe Breite des Bands einer gefundenen Spur |
| `trackMinSeparationS` | 1 s | Pegelmaxima näher am Ereignis begrenzen die t0-Suche nicht |
| `duplicateWindowS` | 0,5 s | gleiche Richtung, t0 näher beieinander: dasselbe Fahrzeug |
| `mirrorKappaTolerance`, `mirrorT0ToleranceS` | 15 %, 0,15 s | Erkennung der Spiegelspur |

In der Simulation liegt die mittlere Korrelation einer echten zweiten Spur bei 0,3 bis 0,4, ohne zweites Fahrzeug bei 0,00 bis 0,02. Die Werte sind mit echten Aufnahmen zu prüfen (Task_20).

---
Pflege: Bei Änderungen am Auswerteverfahren diese Datei sofort aktualisieren.

## Datensammler (Lernmaterial)

Tab „Sammeln“: Eine Sammlung nimmt mit dem app-weit gewählten Eingabegerät frei auf. `ClipCollector` lässt die Ereigniserkennung aus technik.pdf 5.1 mitlaufen (nur dominante Maxima, wie `detectEvents`) und schneidet je Ereignis das Auswertefenster (±`eventWindowS` um das Maximum) als Stereo-WAV heraus. Im Speicher bleiben nur `3 · eventWindowS + eventLevelSmoothingS` Audio; die übrige Aufnahme wird nicht gespeichert. Erkannt wird alles, was `eventThresholdDb` über den Rauschboden steigt, also auch Nicht-Fahrzeuge: genau die soll der Nutzer beim Anhören als „kein Auto“ markieren. Dieselben Clips lassen sich nachträglich aus einer Messreihe mit Rohaudio erzeugen (Detailansicht). Export: ZIP mit allen Clips, `collection.json` (Gerät, Eingabegerät, Pegel, Rauschboden, Dauer, Überlappung, Markierung) und `labels.csv`. Damit lassen sich Schwelle, Fensterlänge und später eine Klassifikation Fahrzeug/kein Fahrzeug an echten Daten prüfen.

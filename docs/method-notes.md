# Messverfahren: Prüfung und Ergänzungen zu technik.pdf

> Wann lesen: bevor du an Ereigniserkennung, Laufzeitanpassung, Doppler, Fusion oder Zählung etwas änderst, und bevor du Messungen am Fenster oder bei dichtem Verkehr beurteilst.

`technik.pdf` bleibt die fachliche Referenz. Diese Datei hält fest, was die Prüfung des Konzepts (2026-11-16, nach Task_19) ergeben hat und wo der Code bewusst über die PDF hinausgeht. Die Zahlen der Konzeptprüfung stammen aus der Simulation; was die ersten echten Aufnahmen ergeben haben, steht im Abschnitt „Erste echte Aufnahmen“.

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

`monotonicMinFraction` steht seit den ersten echten Aufnahmen auf 0,45 statt 0,8 (Begründung im Abschnitt „Erste echte Aufnahmen“).

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

## Erste echte Aufnahmen (2026-11-23, Fenstersims)

Sammlung aus dem Tab „Sammeln“: 17 Minuten, 29 Clips, vom Nutzer markiert (10 Auto, 19 kein Auto). Zwei Funkmikrofone über USB („Wireless Microphone“), 15 cm Abstand laut Maßband, 2,5 m über der Fahrbahn, etwa 3 m zum Fahrbahnrand und etwa 4,4 m zur Mitte der Fahrspur (Angabe des Nutzers), 2 °C, Tempo-30-Zone. Es gibt **keine Referenzgeschwindigkeit**: Geprüft sind Erkennung, Richtung und Plausibilität, nicht die Genauigkeit. Nachrechnen: `fvm dart run tool/evaluate_collection.dart <ordner> --abstand 4.4 --hoehe 2.5 --temperatur 2 --b-schaetzen`.

### Was die Aufnahmen zeigen

- **Echtes Stereo, saubere S-Kurven.** Die Laufzeit geht von +425 µs nach −425 µs (bzw. umgekehrt), Kanalversatz etwa −6 µs.
- **Wirksamer Mikrofonabstand 14,2 cm statt 15 cm** (Einzelwerte aus den Vorbeifahrten 14,1 bis 14,4 cm). Das ist die wichtigste Stellgröße: Mit b = 15 cm erreicht die Messkurve die Asymptote des Modells nicht, die Anpassung gleicht das mit einem kleineren κ aus. 5 % zu viel b ergaben 15 bis 20 % zu wenig Geschwindigkeit.
- **Nebenmaxima ±150 µs neben der Spur.** Die Kohärenz der beiden Kanäle ist bei 0,3 bis 1,7 kHz und bei 3,7 bis 8 kHz hoch, dazwischen (2 bis 3,5 kHz) fast null. Mit dieser Lücke hat die PHAT-Korrelation starke Nebenmaxima. Sie liegen außerhalb der Ausreißergrenze von 40 µs und stören die Anpassung nicht; es ist keine zweite Quelle.
- **Ausgedehnte Quelle.** Vor der größten Annäherung liegt das Korrelationsmaximum 20 bis 40 µs vor der Modellkurve (Front des Autos), danach ebenso weit dahinter (Heck). Ein Auto ist bei 4 m Abstand kein Punkt. Ein Modell mit wandernder Quelle bzw. zwei Achsen passte nicht messbar besser und ließ sich aus den Daten nicht eindeutig bestimmen; es ist nicht umgesetzt. Der systematische Fehler in κ ist damit offen (Schätzung aus der Geometrie: einige Prozent zu klein).
- **Kennwerte der Spur:** Autos haben eine mittlere Korrelation (`MotionFit.strength`) von 0,17 bis 0,25 und einen Kurvenanteil von 0,62 bis 0,92. Ereignisse ohne Fahrzeug: höchstens 0,085 und 0,24. In der Simulation (Punktquelle) lag die Stärke bei 0,3 bis 0,4. `trackMinStrength` = 0,15 passt, der Abstand zu den Autos ist aber klein.
- **Motortöne nur unter 300 Hz.** Über 150 Hz, wo die Tonsuche arbeitet, gibt es bei keinem der 10 Autos eine durchgehende Tonspur. Die Motorordnungen (30 bis 300 Hz) sind gut zu sehen, aber die Drehzahl ändert sich an dieser Stelle bei jedem Auto um 2 bis 7 % pro Sekunde (Gasgeben, Auskuppeln bis Leerlauf). Der Doppler-Sprung bei 30 km/h beträgt insgesamt 5 %. Beides lässt sich nicht trennen: Versuchsweise Regressionen auf den Motorordnungen ergaben 12 bis 170 km/h. Eine Tonsuche unter 150 Hz ist deshalb nicht eingebaut.

### Was geändert wurde

- **`monotonicMinFraction` 0,8 → 0,45.** Der Startwert verwarf 5 von 9 Autos als „Spur nicht monoton“, weil die ausgedehnte Quelle Blöcke neben die Kurve legt. 0,45 liegt zwischen den Autos (ab 0,62) und allem anderen (bis 0,24). Die Simulationstests für anhaltende und abbiegende Fahrzeuge bestehen weiter.
- **Gegenprobe in Doppler-Variante 2.** Das Schärfemaß hat auf Reifenrauschen irgendwo ein größtes S, oft beim langsamsten Kandidaten, und stationäre Linien der Umgebung sind ohne Entzerrung am schärfsten. In 3 von 10 Clips entstand so ein „Ton“, je nach Ausschnitt mit 15 oder 25 km/h, einmal mit Klasse A. Jetzt wird ein Kandidat zusätzlich gleich stark falsch herum entzerrt (`sharpness(reversed: true)`, Laufzeit t = te + (2d − r)/c): Das verdoppelt die Doppler-Verschiebung eines Fahrzeugtons, behandelt alles andere gleich. Ein Ton gilt nur, wenn S um `sharpnessMinPeak` über dem `sharpnessPeakFactor`-Fachen dieser Gegenprobe liegt.
- **b und Δ0 aus den Vorbeifahrten** (`estimatePlateaus`, `lib/core/calibration/plateau_calibration.dart`): Weit vor und nach der Vorbeifahrt steht das Fahrzeug fast in Verlängerung der Mikrofone, die Laufzeit liegt bei Δ0 ± b/c. Aus den Blöcken mit |u| ≥ `plateauMinDirectionCosine` (0,95) folgen b und Δ0; gemeint ist der auf die Straßenrichtung projizierte Abstand, also genau der Wert, den das Modell braucht. Braucht eine gerade Straße und ein Fenster, das die Plateaus erreicht (κ ab etwa 0,8 1/s).
- **Die App lernt b und Δ0 beim Auswerten einer Messreihe** („Messreihe auswerten“, `learnSeriesSpacing` in `lib/data/series_analysis.dart`). Ablauf: Ereignisse suchen, dann zwei Runden nur mit der Laufzeitspur (ohne Doppler). Die erste Runde rechnet mit der Kalibrierung, die zweite mit dem Median der ersten, weil die Anpassung mit falschem b das Plateau um etwa 1 % verschiebt. Danach die volle Auswertung mit dem gelernten Wert. Regeln (`judgeSpacing`): mindestens `plateauMinCount` (5) Vorbeifahrten mit Plateaus, sonst gilt die Kalibrierung; weicht der Median mehr als `plateauMaxDeviation` (20 %) von der Kalibrierung ab, wird er nicht übernommen und gemeldet (gekrümmte Straße, Wand, Mikrofonachse schief). Der Median verträgt einzelne Ausreißer; auf der Sammlung lagen ein langes Fahrzeug bei 12,0 cm und das vermutete Fahrrad bei 11,1 cm, der Median bei 14,2 cm.
  - Gespeichert wird je Messreihe (`measurement_series.learned_mic_spacing_m`, `learned_channel_offset_s`, `learned_pass_count`, Schema 6). `repo.analysisSetup(id)` liefert danach den gelernten Wert, also auch für Sichtprüfung, Export und das Fortsetzen der Aufnahme; `analysisSetup(id, learnedSpacing: false)` die Kalibrierung. Jedes erneute Auswerten lernt von der Kalibrierung aus neu.
  - Die Kanalzuordnung (links/rechts getauscht) wird nicht gelernt, die Kalibrierung dafür bleibt nötig.
  - **Live** gilt die Kalibrierung, solange die Messreihe noch nicht ausgewertet wurde. Die Geschwindigkeiten der Live-Liste sind bei falschem b entsprechend zu klein; maßgeblich ist die Auswertung der gespeicherten Aufnahme.
  - Kosten: Das Lernen verlängerte die Auswertung am PC um etwa die Hälfte (232 s Aufnahme mit 20 Ereignissen: 46 s ohne, 71 s mit).
  - Probe mit den echten Clips, zu einer Datei verbunden und wie eine Messreihe ausgewertet, Start mit b = 15 cm: gelernt 14,2 cm und −9 µs aus 10 Vorbeifahrten, Geschwindigkeiten 17 bis 37 km/h statt 14 bis 27 km/h.
- **Auswertung gelabelter Sammlungen** (`lib/data/collection_evaluation.dart`, `tool/evaluate_collection.dart`).

### Ergebnis auf der Sammlung

| | vorher | jetzt |
|---|---|---|
| Autos mit Geschwindigkeit | 4 von 10 | 9 von 10 |
| davon Klasse A | 1 (falscher Ton) | 0 |
| „kein Auto“ mit Geschwindigkeit | 1 von 19 | 1 von 19 |

- Das fehlende Auto (Clip 14) hat stark verzögert, der Motor fällt auf Leerlauf. Das Pegelmaximum liegt 1,6 s vor der größten Annäherung und damit außerhalb des t0-Suchbereichs (`t0SearchRangeS` = 1 s).
- Der falsche Treffer (Clip 29, 14 dB über dem Grundpegel, Autos 23 bis 32 dB) hat eine vollständige S-Kurve mit κ wie ein Auto. Akustisch ist das eine Vorbeifahrt, vermutlich ein Fahrrad oder ein leises Fahrzeug. Die Laufzeitmethode kann das nicht unterscheiden.
- Richtung: 7 Autos −1, 2 Autos +1.
- **Geschwindigkeit: 17,6 bis 35,4 km/h, Median 27 km/h**, gerechnet mit 4,92 m Schrägabstand (4,4 m horizontal zur Spurmitte). Das passt zur Tempo-30-Zone (erwartet 25 bis 40 km/h). Mit den zuerst genannten 3 m (Fahrbahnrand, Schrägabstand 3,72 m) waren es 13 bis 27 km/h: Die Geschwindigkeit ist proportional zum Abstand, einzutragen ist immer der Abstand zur Mitte der Fahrspur. Beide Richtungen sind hier mit demselben Abstand gerechnet; fahren sie auf verschiedenen Spuren, braucht jede ihren eigenen. Der Fehler der ausgedehnten Quelle bleibt offen, eine Referenz gibt es weiter nicht.
- **Doppler: kein nutzbarer Wert bei 10 Autos.** Variante 1 findet keine Tonspur. Variante 2 meldet nach der Gegenprobe noch vereinzelt einen Wert, der an der Abstandsprüfung scheitert. Die Entscheidung ist nicht stabil: Sie kippt, wenn sich κ um 0,5 % ändert, weil S(v) auf echten Signalen um mehrere Einheiten schwankt. Ein Clip (lautes Fahrzeug mit Linien bei 160 bis 550 Hz) zeigt in allen Varianten ein Maximum bei 31 bis 34 km/h, besteht das Kriterium aber nur manchmal.

### Was für eine echte Validierung fehlt

- Abstand vom Mikrofon zur Mitte jeder Fahrspur mit dem Maßband messen und am Standort eintragen (bisher geschätzt: 4,4 m).
- Referenzfahrten nach `technik.pdf` 8.1 mit dem GPS-Logger. Für Doppler dazu ein Dauerton aus dem Fahrzeug (Lautsprecher, 1 bis 2 kHz): ein Ton, der sicher konstant ist, zeigt, ob die Doppler-Kette auf dem Gerät stimmt.
- Eine Stelle, an der gleichmäßig gefahren wird. Vor einer Einmündung oder Engstelle ändern alle die Drehzahl.

## Wirkung in der Simulation

Zufallsverkehr auf zwei Spuren, 2 Minuten, seitliche Streuung 0,4 m, 10 % beschleunigend:

| Mittlerer Abstand | Fahrzeuge | vorher gemessen | jetzt gemessen | erfundene Fahrzeuge |
|---|---|---|---|---|
| 4,5 s (sehr dicht, zwei Läufe) | 45 | 6 | 38 | 0 |
| 8 s | 15 | nicht ermittelt | 15 | 0 |
| 14 s | 7 | nicht ermittelt | 7 | 0 |

Der Fehler von κ liegt bei etwa 1 % (quadratisches Mittel). Der Fehler der Geschwindigkeit in Klasse B kommt wie in 6.2 fast ganz aus der seitlichen Lage in der Spur.

## Temperatur über lange Messreihen

technik.pdf 7.3 verlangt die Temperatur auf etwa 2 K genau; 1 K ändert c um rund 0,18 %, also auch v_T und v_D um diesen Anteil. Über einen Nachmittag ändert sich die Lufttemperatur leicht um 5 bis 10 K (1 bis 2 %). Die App holt deshalb auf Wunsch die 2-m-Temperatur des Wetterdienstes am Standort (Open-Meteo, Modellwert, kein Messwert am Fenster) und aktualisiert sie alle 15 min. Jedes Ereignis wird mit c der zuletzt davor gültigen Temperatur ausgewertet (Stufenfunktion, keine Interpolation). Grenzen: Der Modellwert kann bei Sonne auf der Fassade oder im Straßenschlucht-Mikroklima um mehrere Kelvin abweichen; der Mikrofonabstand aus der Kalibrierung und aus den Vorbeifahrten wird mit dem Start-c bzw. dem c der Kalibrierung gerechnet.

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

In der Simulation liegt die mittlere Korrelation einer echten zweiten Spur bei 0,3 bis 0,4, ohne zweites Fahrzeug bei 0,00 bis 0,02. Echte Autos am Fenstersims: 0,17 bis 0,25, ohne Fahrzeug höchstens 0,085 (Abschnitt „Erste echte Aufnahmen“). Mehrere Fahrzeuge gleichzeitig sind mit echten Aufnahmen noch nicht geprüft.

---
Pflege: Bei Änderungen am Auswerteverfahren diese Datei sofort aktualisieren.

## Datensammler (Lernmaterial)

Tab „Sammeln“: Eine Sammlung nimmt mit dem app-weit gewählten Eingabegerät frei auf. `ClipCollector` lässt die Ereigniserkennung aus technik.pdf 5.1 mitlaufen (nur dominante Maxima, wie `detectEvents`) und schneidet je Ereignis das Auswertefenster (±`eventWindowS` um das Maximum) als Stereo-WAV heraus. Im Speicher bleiben nur `3 · eventWindowS + eventLevelSmoothingS` Audio; die übrige Aufnahme wird nicht gespeichert. Erkannt wird alles, was `eventThresholdDb` über den Rauschboden steigt, also auch Nicht-Fahrzeuge: genau die soll der Nutzer beim Anhören als „kein Auto“ markieren. Dieselben Clips lassen sich nachträglich aus einer Messreihe mit Rohaudio erzeugen (Detailansicht). Beim Start einer Messreihe ist „Clips“ standardmäßig an: Dann läuft derselbe Sammler während der Messreihe mit (auch ohne Rohaudio) und schreibt in eine Sammlung mit `source` = `messreihe <id>`; `metadata.json` hält das als `collectClips` fest, damit „Weiter aufnehmen“ in dieselbe Sammlung schreibt (Zeiten um den Beginn des Abschnitts verschoben). In der Detailansicht der Messreihe lassen sich die Clips einzeln anhören, markieren und mit den Konstanten der Reihe (Kalibrierung, gelernter Abstand, Spurabstände) auswerten; die Zeiten im Ergebnis zählen dabei ab Clip-Beginn. Export: ZIP mit allen Clips, `collection.json` (Gerät, Eingabegerät, Pegel, Rauschboden, Dauer, Überlappung, Markierung) und `labels.csv`. Damit lassen sich Schwelle, Fensterlänge und später eine Klassifikation Fahrzeug/kein Fahrzeug an echten Daten prüfen.

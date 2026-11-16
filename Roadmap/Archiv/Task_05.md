# Task_05: Geräteeignung und Kalibrierung

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_05.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Ein geführter Assistent prüft ein Gerät nach PDF 4.4 (echtes Stereo, keine Vorverarbeitung, kein Übersteuern, Kanalzuordnung) und kalibriert den effektiven Mikrofonabstand b und den Kanalversatz Δ0 nach PDF 7.1. Das Ergebnis wird pro Gerät gespeichert und von jeder Messreihe verwendet.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Task_03 (GCC-PHAT) und Task_04 (drift, Gerätetabelle) archiviert.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitte 4.3 (Externes Mikrofon über `setPreferredDevice`), 4.4 (Eignungsprüfung), 7.1 (Mikrofonabstand und Kanalversatz).

## Umfang

**Gehört dazu:**

- Auswahl des Eingabegeräts im Kotlin-Plugin: interne Mikrofone oder angeschlossenes USB-Stereo-Interface (`AudioManager.getDevices`, `setPreferredDevice`).
- Prüfung 1, echtes Stereo: Klatschen links und rechts in Verlängerung der Mikrofonachse; zwei getrennte Maxima bei etwa ±b/c, sonst Hinweis "Monosignal".
- Prüfung 2, keine Vorverarbeitung: 10 s konstantes Signal; Pegelverlauf und Spektrum dürfen nicht nachregeln (Schwellen festlegen und dokumentieren).
- Prüfung 3, Übersteuerung: Hinweis und Spitzenwertanzeige; Übersteuerung über 90 % wird markiert.
- Prüfung 4, Kanalzuordnung: welcher Kanal zu welchem Mikrofon gehört; legt das Vorzeichen von Δ und damit die Fahrtrichtung fest.
- Kalibrierung 7.1: Δ+ und Δ− aus den Aufnahmen, Temperatur, Berechnung von b/c, Δ0 und b; Speicherung pro Gerät und Eingabegerät mit Datum.
- Anzeige des Kalibrierstatus; Messreihen verwenden automatisch die aktuelle Kalibrierung.

**Gehört nicht dazu:**

- Selbstkalibrierung im Betrieb (Task_18).
- Frequenzabhängige Kalibrierung von b (nur als offene Frage festhalten).

## Umsetzungsschritte

1. Gerätewahl im Kotlin-Plugin ergänzen und an Dart durchreichen.
2. Auswertefunktionen für die vier Prüfungen und die Kalibrierung als reine Dart-Logik mit klaren Ergebnisobjekten (bestanden/nicht bestanden, Messwerte, Begründung).
3. Transienten-Erkennung für Klatschen/Schlüsselbund (Pegelsprung), damit nur die relevanten Abschnitte korreliert werden.
4. Assistent-UI mit Anleitungstexten pro Schritt.
5. Ergebnisse in der Gerätetabelle speichern, Messreihen verknüpfen.
6. Tests mit synthetischen Signalen; manuelle Prüfung mit dem echten Gerät, Ergebnis festhalten.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- Synthetischer Impuls aus +x und −x in Achsrichtung mit bekanntem b und Δ0: Kalibrierung liefert b auf 1 % und Δ0 auf 2 µs genau.
- Dupliziertes Monosignal (beide Kanäle gleich): Prüfung 1 schlägt fehl mit passender Begründung.
- Signal mit simulierter AGC (Pegel regelt nach): Prüfung 2 schlägt fehl; konstantes Signal besteht.
- Übersteuertes Signal: Prüfung 3 meldet es.
- Vertauschte Kanäle: Prüfung 4 erkennt die Zuordnung, das Vorzeichen der Richtung kehrt sich korrekt um.
- Manuell: Assistent einmal vollständig auf dem Zielgerät durchlaufen, Werte für b und Δ0 dokumentieren.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [x] `fvm flutter test tests/` läuft grün.
- [ ] (→ Task_20) Auf dem Zielgerät ist dokumentiert, ob alle vier Prüfungen bestehen, und b liegt plausibel im Bereich 0,10 bis 0,20 m (oder abweichend begründet).
- [x] Jede neue Messreihe speichert die verwendete Kalibrierung in DB und `metadata.json`.

## Offene Fragen / Annahmen

- Liefert das Zielgerät überhaupt zwei unbearbeitete Kanäle? Herstellerabhängig, Ergebnis dieses Tasks in `Roadmap/README.md` eintragen.
- Ist b frequenzabhängig? Falls die Messungen das nahelegen, als Erkenntnis notieren; Umsetzung erst bei Bedarf.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

- Schwellen der Prüfungen (nicht in PDF 9.2, deshalb in `DeviceCheckLimits`): Transiente 15 dB über Median-Rahmenenergie (5-ms-Rahmen, 0,3 s Sperrzeit); Suchbereich vor der Kalibrierung b ≤ 0,3 m; Mono, wenn (Δ+ − Δ−)/2·c < 5 cm; Prüfung 2: Pegelschwankung der 100-ms-Rahmen ≤ 1,5 dB (erste 0,5 s ignoriert), mittlere Spektrumsänderung erste vs. letzte 3 s ≤ 2 dB im Band 300 Hz–8 kHz.
- Vorzeichen: "rechts" = Seite, zu der Fahrzeuge der Richtung +1 fahren (x > 0). Dort muss Δ positiv sein, sonst sind die Kanäle vertauscht (Prüfung 4).
- Gerätetest (Assistent auf dem echten Gerät, b und Δ0 dokumentieren, Ergebnis "zwei unbearbeitete Kanäle?") → Task_20.

## Abschluss-Checkliste

Reihenfolge und Details stehen in `AGENTS.md`, Abschnitt "Abschluss- und Archivierungs-Workflow".

- [x] Alle automatisch prüfbaren Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [x] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [x] Folge-Tasks und `Roadmap/README.md` geprüft und bei Bedarf angepasst
- [x] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

- **Umgesetzt (und Abweichungen vom Plan):** Prüf- und Kalibrierlogik `lib/core/calibration/device_checks.dart` (findTransients, measureAxis, checkStereo, checkNoProcessing, checkClipping, checkChannelMapping, calibrate). Synthetische Signale `lib/core/sim/calibration_signals.dart` (axialBursts, constantNoise). Kotlin: `getInputDevices`, `start {inputDeviceId}` mit `setPreferredDevice`. Dart: `StereoRecorder.inputDevices()`, `InputDevice`, `recordFor`, `CalibrationCapture` (echt oder simuliert). Assistent `CalibrationScreen` + `CalibrationController`, Status im Tab "Gerät" (`DeviceScreen`, mit Schalter "Simulation als Standard"). Ergebnis in `Calibrations` (inkl. `checksJson`), Messreihen übernehmen die neueste Kalibrierung des Geräts.
- **Learnings & Stolpersteine:** Δ0 bezieht sich nach dem Tauschen auf die physikalische Kanalreihenfolge (links = −b/2). `calibrate(swapChannels: true)` liefert Δ0 deshalb für die getauschten (= korrigierten) Kanäle. Riverpod-Ausdrücke `x ?? ref.watch(notifierProvider)` brauchen eine explizite `bool`-Annotation, sonst meldet der Analyzer `bool?`.
- **Wichtige Entscheidungen und ihre Gründe:** Kalibrierung pro (Gerätemodell, Eingabegerät); Simulation hat das Gerätemodell "Simulation" und damit eine eigene Kalibrierung. Klatschfenster = ein GCC-Block (2048 Abtastwerte) ab 5 ms vor dem Einsatz, Median über alle Klatscher.
- **Auswirkungen auf Folge-Tasks:** Auswertung (Task_09) muss `swapChannels` der Kalibrierung anwenden (Kanäle tauschen, bevor GCC-PHAT läuft) und b, Δ0 aus der Kalibrierung nehmen; ohne Kalibrierung Standard b = 0,15 m, Δ0 = 0. Frequenzabhängigkeit von b ist nicht untersucht (offen, Task_20).
- **Hinweise zu Tests und Befehlen:** `tests/core/calibration/`, `tests/ui/calibration/`. Der Assistent lässt sich mit simuliertem Gerät komplett durchklicken.

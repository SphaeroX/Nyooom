# Task_20: Geräte- und Feldtest

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_20.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Alle Prüfungen, die nur mit einem echten Android-Gerät, echten Vorbeifahrten oder echten Referenzfahrten möglich sind, werden gesammelt am Ende durchgeführt. Bis hierhin ist die App vollständig gegen synthetische Daten (Generator aus Task_02, Fahrzeugprofile Elektroauto und Verbrenner) getestet.

## Hintergrund (Entscheidung des Nutzers, 2026-11-16)

Während der Entwicklung war kein Gerät angeschlossen. Der Nutzer hat entschieden, die Tasks gegen synthetische Daten abzuarbeiten und alle gerätebezogenen Prüfungen in diesen Abschluss-Task zu verschieben. Die einzelnen Tasks verweisen in ihren Notizen auf die jeweiligen Punkte hier. Zum Ausprobieren ohne Gerät hat die App eine Simulationsquelle (synthetische Vorbeifahrten statt Mikrofon).

## Checkliste (Ergebnisse hier eintragen)

### Aus Task_01: Aufnahme

| Prüfung | Ergebnis |
|---|---|
| Gerätemodell / Android-Version | |
| App startet, Berechtigung wird angefragt | |
| Gemeldete Audioquelle (UNPROCESSED / Rückfall) | |
| Effektstatus AGC / NS / AEC | |
| Gemeldete Mikrofone (`getMicrophones`) | |
| Pegel reagieren getrennt (oberes bzw. unteres Mikrofon zuhalten); welcher Kanal = welches Mikrofon | |
| Gespeicherte WAV am PC: Stereo, 48 kHz, 16 Bit | |

WAV vom Gerät holen: `adb exec-out run-as de.nyooom.app ls app_flutter` und `adb exec-out run-as de.nyooom.app cat app_flutter/<pfad>.wav > aufnahme.local.wav`.

### Aus Task_04: Messreihe

- [ ] 2-minütige Aufnahme einer Messreihe, Datei am PC prüfbar, `metadata.json` vollständig.
- [ ] 10-minütige Aufnahme ohne wachsenden Speicherverbrauch (Android Studio Profiler oder `adb shell dumpsys meminfo de.nyooom.app`).
- [ ] Verhalten bei App-Wechsel und Bildschirm aus wie in Task_04 entschieden.

### USB-Stereomikrofon und Fortsetzen einer Messreihe (2026-11-17)

- [ ] USB-Stereomikrofon anstecken: erscheint es im Startbildschirm der Messreihe unter „Mikrofon“ und ist vorausgewählt? Gemeldete `channelCounts` notieren.
- [ ] Aufnahmebildschirm zeigt „Mikrofon: <USB-Name>“ (Android hat `setPreferredDevice` übernommen). Sonst Gerät, Android-Version und Audioquelle notieren.
- [ ] WAV am PC: beide Kanäle verschieden (zwei Kapseln, nicht dupliziertes Mono), linker Kanal = welche Kapsel? Abstand b der Kapseln messen.
- [ ] Kalibrierung mit dem USB-Mikrofon im Tab „Gerät“ (Eingabegerät wählen) und danach eine Messreihe: wird die USB-Kalibrierung verwendet (`metadata.json` → `calibration`, `inputDevice`)?
- [ ] USB-Mikrofon während der Aufnahme abziehen: Verhalten notieren (Abbruch, Wechsel auf eingebaute Mikrofone?).
- [ ] Messreihe beenden, „Weiter aufnehmen“, wieder beenden: eine WAV mit beiden Teilen, `metadata.json` → `segments` mit zwei Einträgen, Uhrzeiten der Vorbeifahrten nach der Pause stimmen.
- [ ] Fortsetzen aus der Detailansicht nach App-Neustart, auch mit USB-Mikrofon (muss wieder angesteckt sein).

### Einführung und Hilfe (2026-11-17)

- [ ] Einführung erscheint nach frischer Installation, nach „Überspringen“ bzw. „Los geht’s“ beim nächsten Start nicht mehr.
- [ ] Tab „Hilfe“: Texte auf dem Gerät gut lesbar, Schritte passen zum tatsächlichen Ablauf.

### Aus Task_05: Eignung und Kalibrierung

- [ ] Assistent vollständig durchlaufen; Ergebnis der vier Prüfungen notieren.
- [ ] Schritt-für-Schritt-Assistent (seit 2026-11-16): reichen 5 s Countdown für die 3 m, erkennt die 5-s-Aufnahme drei Klatscher, ist der grüne/orange Bildschirm aus 3 m erkennbar?
- [ ] b liegt im Bereich 0,10 bis 0,20 m; Werte für b und Δ0 notieren.
- [ ] Ergebnis "liefert das Gerät zwei unbearbeitete Kanäle?" in `Roadmap/README.md` eintragen.
- [ ] Optional: USB-Stereo-Interface über die Eingabegeräte-Auswahl testen (Tab „Gerät“: erscheint nach dem Anstecken ohne Neustart, Pegeltest zeigt „Eingang: <Gerät>“, Kalibrierung wird getrennt von „intern“ gespeichert, Abziehen fällt mit Hinweis auf intern zurück). Stereo-Prüfung im Pegeltest: an Sender 1 reiben → nur ein Balken, „echtes Stereo“ bei Umgebungsgeräusch; Logcat-Zeile `NyooomAudio Input …` mit Kanälen/Masken notieren.

### Aus Task_06: Sichtprüfung (erster Entscheidungspunkt der PDF)

- [ ] 20 bis 30 echte Vorbeifahrten aufnehmen, Korrelogramm und Spektrogramm im Viewer ansehen.
- [ ] Entscheidung interne vs. externe Mikrofone durch den Nutzer, in `Roadmap/README.md` festhalten.
- [x] Kurze Ausschnitte (wenige Sekunden) als Fixtures nach `tests/fixtures/` legen und Regressionstests ergänzen. (2026-11-23: drei Ausschnitte, `tests/data/real_recordings_test.dart`)

### Aus Task_07 bis Task_11: Auswertung auf echten Daten

- [ ] Ereigniserkennung findet die visuell erkennbaren Einzelvorbeifahrten.
- [ ] Ergebnisliste einer echten Messreihe mit plausiblen Geschwindigkeiten.
- [x] Anteil der Ereignisse mit nutzbarem Ton (Doppler) zählen, in `Roadmap/README.md` notieren. (2026-11-23, Fenstersims: 0 von 10)
- [x] Anteil A/B/C auf echten Daten ermitteln, in `Roadmap/README.md` notieren. (2026-11-23, Fenstersims, 10 Autos: 0 / 9 / 1)

### Aus Task_12: Live-Betrieb

- [ ] Laufzeit einer Ereignis-Auswertung im Release-Build auf dem Gerät messen.
- [ ] Ergebnis erscheint spätestens 10 s nach der Vorbeifahrt.
- [ ] 30 Minuten Live-Betrieb: CPU, Akku, keine wachsende Warteschlange.

### Aus Task_13/14: Statistik und Export

- [ ] Statistik-Bildschirm für eine echte Messreihe ansehen.
- [ ] Export teilen und am PC in einer Tabellenkalkulation öffnen.

### Aus Task_15/16: GPS und Validierung

- [ ] GPS-Logger 5 Minuten im Auto, Verlauf plausibel; GPX-Import sichtbar.
- [ ] Referenzfahrten nach PDF 8.1 (20/30/40/50 km/h, beide Richtungen, je 5 Wiederholungen, plus Beschleunigen/Bremsen; möglichst Elektro und Verbrenner).
- [ ] Validierung mit Ampel in der App, Ergebnis in `Roadmap/README.md`.

### Aus Task_17 bis Task_19: Verfeinerungen auf echten Daten

- [ ] Anteil Klasse A mit/ohne Doppler-Variante 2 vergleichen.
- [ ] Maßband- und gelernter Abstand pro Spur für eine echte Messreihe ansehen; systematischen Fehler der ausgedehnten Quelle notieren.
- [ ] Einfache Fusion vs. gemeinsame Ausgleichsrechnung auf echten Referenzdaten vergleichen; Standardverfahren ggf. neu wählen.

### Aus der Konzeptprüfung (nach Task_19): mehrere Fahrzeuge, Fenstersims

Hintergrund in `docs/method-notes.md`.

- [ ] Aufnahme mit Kolonnen und Gegenverkehr von Hand auszählen (Video oder Strichliste, mindestens 50 Fahrzeuge) und mit der Zahl der Datensätze vergleichen: fehlende und erfundene Fahrzeuge notieren.
- [x] Mittlere Korrelation echter Spuren ansehen (`MotionFit.strength`): passt `trackMinStrength` = 0,15, oder gibt es Geisterspuren bzw. verworfene echte Spuren? (2026-11-23: passt, Autos 0,17 bis 0,25, sonst höchstens 0,085; verworfen wurden echte Spuren wegen `monotonicMinFraction`, jetzt 0,45)
- [ ] Anteil der Datensätze mit Grund „Ton nicht zuordenbar" und „Beschleunigung" bei dichtem Verkehr notieren.
- [ ] Grundpegel bei dichtem Verkehr: werden leise Fahrzeuge noch erkannt? Gegebenenfalls `noiseFloorPercentile` anpassen und hier festhalten.
- [ ] Fenstersims: b und Δ0 in Einbaulage kalibrieren und mit der Kalibrierung am Stativ vergleichen. Im Korrelogramm prüfen, ob eine gespiegelte Spur (Laibung) zu sehen ist.
- [ ] Fenstersims: langsame Fahrzeuge bei großem Schrägabstand, Anteil Klasse C „außerhalb des Suchbereichs" notieren (`kappaMin`).
- [ ] Live-Betrieb bei dichtem Verkehr: bleibt `dropped` bei 0? Sonst zählt die Live-Liste zu wenig, die Auswertung der gespeicherten Aufnahme ist dann maßgeblich.

## Tests

Automatische Tests entstehen hier nur, wenn echte Aufnahmen als Fixtures dazukommen (Regressionstests auf kurze echte Ausschnitte).

## Akzeptanzkriterien

- [ ] Alle Checklistenpunkte oben sind ausgefüllt oder begründet als nicht durchführbar markiert.
- [ ] `fvm flutter test tests/` läuft grün (inklusive neuer Fixture-Tests).
- [ ] `Roadmap/README.md` enthält die Ergebnisse der offenen Punkte aus PDF Abschnitt 10.

## Notizen zu diesem Task

**2026-11-16, Vorbereitung für den ersten Versuch am Fenster (ohne Kalibrierung):**

- Neue Messreihen nehmen standardmäßig mit dem Mikrofon auf, nicht mehr mit der Simulation.
- Startbildschirm ohne Standort: Knopf „Schnelltest-Standort anlegen“ (`quickTestSite()`: Spur → 5 m, Spur ← 8 m, Höhe 1,5 m, 50 km/h). Abstände später unter „Standorte“ korrigieren; die Geschwindigkeit skaliert linear mit dem angenommenen Abstand (v = κ·d), Erkennung und Zählung hängen nicht davon ab.
- Ohne Kalibrierung: b = 0,15 m, Δ0 = 0, Kanäle nicht getauscht. Liefert das Gerät die Kanäle vertauscht, erscheinen die Richtungen spiegelverkehrt (→ statt ←) und die Spuren werden vertauscht zugeordnet.
- Bildschirm bleibt während der Aufnahme an (`FLAG_KEEP_SCREEN_ON` im Kotlin-Plugin). App nicht wechseln: ohne Foreground-Service wird das Mikrofon im Hintergrund stummgeschaltet.
- Für den Gerätetest die **Release-APK** nehmen: Im Debug-Build läuft Dart im JIT-Modus, die Live-Auswertung (≈ 2 s pro Ereignis am PC) wäre deutlich langsamer und würde Ereignisse verwerfen (`verloren`).
- Die Checkliste oben ist damit noch nicht abgearbeitet; das braucht das Gerät und echte Vorbeifahrten.

**2026-11-17, USB-Mikrofon und Fortsetzen (Wunsch des Nutzers):**

- Startbildschirm der Messreihe: Auswahl „Mikrofon“ (eingebaut oder externes Gerät aus `getInputDevices`), ein externes Gerät mit zwei Kanälen wird vorausgewählt (`preferredInputDevice`). Die Messreihe nutzt die Kalibrierung dieses Eingabegeräts (`devices.input_device`), ohne sie b = 0,15 m.
- Gestoppte Messreihen lassen sich fortsetzen (Aufnahmebildschirm und Detailansicht, „Weiter aufnehmen“). Die WAV wird angehängt, jede Fortsetzung ist ein Abschnitt (`RecordingSegment`, DB-Schema 5, `metadata.json` → `segments`). Ob Android das USB-Gerät wirklich übernimmt, ist nur auf dem Gerät prüfbar (Checkliste oben).

**2026-11-23, erste echte Aufnahmen (Sammlung vom Fenstersims, Auswertung am PC):**

Aufnahme des Nutzers: Google Pixel 11, Eingabe „USB-Audio - Wireless Microphone“ (zwei Funkmikrofone, 15 cm), 2,5 m über der Fahrbahn, etwa 3 m zur Straße, 2 °C, Tempo-30-Zone. 17 Minuten, 29 Clips, markiert: 10 Auto, 19 kein Auto. Einzelheiten und Zahlen in `docs/method-notes.md`, Abschnitt „Erste echte Aufnahmen“.

- Das Funkmikrofon liefert echtes Stereo (beide Kanäle verschieden, saubere S-Kurven). Wirksamer Abstand aus den Vorbeifahrten: b = 14,2 cm, Δ0 = −6 µs.
- Ereigniserkennung: alle 10 Autos als Clip vorhanden; dazu 19 Ereignisse ohne Auto (Schwelle 10 dB), die die Auswertung bis auf eines als „keine Spur“ verwirft.
- Anteil A/B/C der 10 Autos: 0 / 9 / 1 (vor den Korrekturen 1 falsche A / 3 / 6).
- Anteil mit nutzbarem Ton (Doppler): 0 von 10. Motorordnungen liegen unter 300 Hz und ändern sich mit der Drehzahl stärker als der Doppler-Sprung.
- `trackMinStrength` = 0,15 passt (Autos 0,17 bis 0,25, sonst höchstens 0,085). `monotonicMinFraction` war zu streng und steht jetzt auf 0,45.
- Keine Spiegelspur der Laibung zu sehen. Die zweite Linie im Korrelogramm (±150 µs) ist ein Nebenmaximum der Korrelation, keine Reflexion.
- Geschwindigkeiten: 17,6 bis 35,4 km/h, Median 27 km/h, mit 4,4 m horizontal zur Spurmitte (Angabe des Nutzers, Schrägabstand 4,92 m). Mit den zuerst genannten 3 m (Fahrbahnrand) waren es 13 bis 27 km/h. Plausibel für Tempo 30, aber ohne Referenzfahrten nicht bestätigt.
- Neue Werkzeuge: `tool/evaluate_collection.dart`, Fixtures in `tests/fixtures/` mit `tests/data/real_recordings_test.dart`.
- Die App lernt b und Δ0 jetzt beim Auswerten einer Messreihe selbst (Wunsch des Nutzers, DB-Schema 6). Auf dem Gerät noch zu prüfen: Laufzeit der Auswertung mit Lernen, Anzeige der Karte „Mikrofonabstand aus den Vorbeifahrten“, Migration einer bestehenden Installation.
- Noch offen aus der Checkliste: alles, was das Gerät selbst betrifft (Audioquelle, Effekte, Live-Laufzeit), Referenzfahrten, dichter Verkehr.

## Abschluss-Checkliste

- [ ] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [ ] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [ ] `Roadmap/README.md` aktualisiert
- [ ] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

<!-- ERKENNTNISSE-OFFEN: Vor der Archivierung ausfüllen und diese Zeile löschen. -->

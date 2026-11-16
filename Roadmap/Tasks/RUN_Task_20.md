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

### Aus Task_05: Eignung und Kalibrierung

- [ ] Assistent vollständig durchlaufen; Ergebnis der vier Prüfungen notieren.
- [ ] b liegt im Bereich 0,10 bis 0,20 m; Werte für b und Δ0 notieren.
- [ ] Ergebnis "liefert das Gerät zwei unbearbeitete Kanäle?" in `Roadmap/README.md` eintragen.
- [ ] Optional: USB-Stereo-Interface über die Eingabegeräte-Auswahl testen.

### Aus Task_06: Sichtprüfung (erster Entscheidungspunkt der PDF)

- [ ] 20 bis 30 echte Vorbeifahrten aufnehmen, Korrelogramm und Spektrogramm im Viewer ansehen.
- [ ] Entscheidung interne vs. externe Mikrofone durch den Nutzer, in `Roadmap/README.md` festhalten.
- [ ] Kurze Ausschnitte (wenige Sekunden) als Fixtures nach `tests/fixtures/` legen und Regressionstests ergänzen.

### Aus Task_07 bis Task_11: Auswertung auf echten Daten

- [ ] Ereigniserkennung findet die visuell erkennbaren Einzelvorbeifahrten.
- [ ] Ergebnisliste einer echten Messreihe mit plausiblen Geschwindigkeiten.
- [ ] Anteil der Ereignisse mit nutzbarem Ton (Doppler) zählen, in `Roadmap/README.md` notieren.
- [ ] Anteil A/B/C auf echten Daten ermitteln, in `Roadmap/README.md` notieren.

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
- [ ] Mittlere Korrelation echter Spuren ansehen (`MotionFit.strength`): passt `trackMinStrength` = 0,15, oder gibt es Geisterspuren bzw. verworfene echte Spuren?
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

## Abschluss-Checkliste

- [ ] Alle Akzeptanzkriterien erfüllt, Tests liegen permanent in `tests/` und laufen grün
- [ ] Abschnitt "Erkenntnisse für Folge-Agenten" unten ausgefüllt
- [ ] `Roadmap/README.md` aktualisiert
- [ ] Datei ohne `RUN_` nach `Roadmap/Archiv/` verschoben

## Erkenntnisse für Folge-Agenten

<!-- ERKENNTNISSE-OFFEN: Vor der Archivierung ausfüllen und diese Zeile löschen. -->

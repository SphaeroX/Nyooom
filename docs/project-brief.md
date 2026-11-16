# Projektbild

> Wann lesen: wenn Ziel, Umfang oder Abgrenzung des Projekts unklar sind.

## Ziel und Zielgruppe

Nyooom schätzt die Geschwindigkeit einzeln vorbeifahrender Fahrzeuge allein aus der Zweikanal-Audioaufnahme eines Android-Smartphones, nach dem Verfahren in `technik.pdf` (Laufzeitdifferenz per GCC-PHAT, Doppler-Verschiebung, Fusion, Qualitätsklassen A/B/C). Das Ergebnis dient einer Statistik über eine Straße (Median, V85, Anteil über dem Limit). Zielgruppe sind der Entwickler selbst und Personen, die Verkehrsstatistiken erheben; Einsatz mit Smartphone auf Stativ am Straßenrand.

## Kernfunktionen

- Eignungsprüfung eines Geräts (echtes Stereo, keine Vorverarbeitung, Übersteuerung, Kanalzuordnung) und Kalibrierung von Mikrofonabstand b und Kanalversatz Δ0.
- Messreihen mit Standortdaten (Spurabstände, Höhe, Temperatur, Richtung → Spur) anlegen und als Stereo-WAV plus Metadaten aufnehmen.
- Live-Auswertung: Vorbeifahrten erkennen, Geschwindigkeit, Unsicherheit und Klasse pro Fahrzeug.
- Statistik getrennt nach Klasse A/B und Richtung, Anteil C, Korrektur der Messunsicherheit.
- Export als CSV/JSON.
- GPS-Referenzfahrten (Logger-Modus, GPX/CSV-Import) und Validierung gegen die Abnahmekriterien aus `technik.pdf` 8.

## Nicht-Ziele

- Nachweis einzelner Verstöße.
- iOS-Umsetzung (später möglich, Architektur hält sie offen).
- Cloud, Backend, Nutzerkonten.
- Separate Python-Auswertung am PC (bewusst gegen die Empfehlung der PDF entschieden; alles läuft in der App).

## Rahmenbedingungen

- Android ab 7 (API 24), ein Entwickler, Dokumentation auf Deutsch.
- Keine externen Dienste, keine Secrets.
- Rohaudio nur in der Entwicklungsphase; im Betrieb verlassen nur Ergebnisdatensätze die Auswertung.
- Die Messung funktioniert nur, wenn das Gerät zwei getrennte, unbearbeitete Mikrofonkanäle liefert; sonst ist ein externes USB-Stereomikrofon nötig.

## Offene Entscheidungen

- Zielgerätemodell.
- Reicht reines Dart für Echtzeit auf dem Gerät?
- Fachliche offene Punkte aus `technik.pdf` 10 (Anteil Fahrzeuge mit Ton, Fehler durch ausgedehnte Schallquelle, Frequenzabhängigkeit von b, E-Auto-Warnton).

Die Umsetzungsplanung steht in `Roadmap/` (siehe `Roadmap/README.md`).

---
Pflege: Bei Änderungen an Zielen oder Umfang diese Datei aktualisieren.

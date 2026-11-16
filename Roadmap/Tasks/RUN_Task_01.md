# Task_01: Durchstich: Stereo-Rohaufnahme

> ## ⚠️ PFLICHT – BEVOR DU IRGENDETWAS ANDERES TUST
>
> 1. **Lies als Allererstes die Datei `AGENTS.md` im übergeordneten Ordner `Roadmap/`** (von hier: `../AGENTS.md`) und befolge sie strikt.
> 2. **Deine allererste Aktion** ist, diese Datei in `RUN_Task_01.md` umzubenennen, um den Task als laufend zu markieren. Das passiert **noch bevor irgendein Code geschrieben** wird.

## Ziel

Das Flutter-Projekt existiert, ein eigenes Kotlin-Plugin nimmt unbearbeitetes 48-kHz-Stereo auf und streamt es an Dart, die App zeigt den Pegel beider Kanäle getrennt an und speichert eine Aufnahme als Stereo-WAV. Damit ist der kritischste technische Baustein (Rohaudio-Zugriff) früh geklärt und Stack, Projektstruktur und Testing sind einmal Ende zu Ende verbunden.

## Kontext & Abhängigkeiten

- **Voraussetzung:** Keine (erster Task). Flutter-SDK und Android-SDK müssen installiert sein; ein Android-Gerät (ab Android 7) für die manuelle Prüfung.
- **Relevantes Vorwissen:** `technik.pdf` Abschnitte 4.2 (Anforderungen an das Audiosignal) und 4.3 (Ansteuerung unter Android). `Roadmap/README.md`, Abschnitt "Taskübergreifende Entwicklungsinfos" (Stack-Entscheidungen).

## Umfang

**Gehört dazu:**

- Flutter-Projekt `nyooom` im Projekt-Root anlegen (Android als Zielplattform, iOS-Ordner darf existieren, wird aber nicht gepflegt).
- Projektstruktur festlegen: reine Dart-Logik (DSP, Modelle) getrennt von UI und Plattform-Code, z. B. `lib/core/`, `lib/audio/`, `lib/ui/`.
- Kotlin-Plugin (im App-Modul oder als lokales Plugin-Paket) mit MethodChannel (start/stop/Fähigkeiten) und EventChannel (PCM-Blöcke).
- AudioRecord mit `AudioSource.UNPROCESSED` falls `PROPERTY_SUPPORT_AUDIO_SOURCE_UNPROCESSED` gesetzt ist, sonst `VOICE_RECOGNITION`; 48000 Hz, `CHANNEL_IN_STEREO`, PCM 16 Bit (Float optional).
- AutomaticGainControl, NoiseSuppressor, AcousticEchoCanceler für die Session prüfen und deaktivieren; tatsächlich genutzte Quelle und Effektstatus an Dart melden.
- Mikrofon-Berechtigung zur Laufzeit anfragen.
- Dart-Seite: De-Interleaving in zwei Kanäle, Pegelanzeige (RMS/Peak in dBFS) pro Kanal, Clipping-Hinweis über 90 % Vollaussteuerung.
- WAV-Writer in reinem Dart (Stereo, 48 kHz, 16 Bit) und Speichern einer Aufnahme im App-Dokumentordner.

**Gehört nicht dazu:**

- Messreihen, Standortdaten, Datenbank (Task_04).
- Eignungsprüfung, Kalibrierung, Auswahl eines USB-Mikrofons (Task_05).
- Jegliche Signalauswertung (ab Task_02/03).
- Git, `.gitignore`, `docs/`, FVM (bereits durch `project-init` eingerichtet).

## Umsetzungsschritte

1. Flutter-Projekt mit dem Befehl aus `docs/architecture.md` (Abschnitt "Erster Implementierungsschritt") generieren (`fvm flutter create …`, Paket `de.nyooom.app`), `minSdkVersion` auf mindestens 24 setzen und die SDK-Constraint auf `^3.14.0` setzen.
2. Testkonfiguration so einrichten, dass `fvm flutter test tests/` läuft (Ordner `tests/` statt `test/`); den von `flutter create` erzeugten `test/`-Ordner entfernen.
3. Kotlin-Seite: Fähigkeiten abfragen (UNPROCESSED unterstützt?, Effekte vorhanden?, `getActiveMicrophones()` ab Android 9 als Info), Aufnahme in eigenem Thread mit Puffer, Blöcke als ByteArray über den EventChannel senden.
4. Dart-Seite: Dienstklasse `StereoRecorder` (Stream<StereoBlock>) und Konverter Interleaved-PCM → zwei Float-Kanäle.
5. Pegelberechnung pro Kanal als reine Dart-Funktion, UI mit zwei Pegelbalken, Start/Stopp und Anzeige von Audioquelle und Effektstatus.
6. WAV-Writer implementieren und Aufnahme-Button "Speichern" anbinden.
7. Tests schreiben (siehe unten) und `fvm flutter test tests/` grün bekommen.
8. Manuelle Geräte-Checkliste durchgehen und Ergebnis (Gerätemodell, Quelle, Effekte) im Abschnitt "Notizen" festhalten.

## Tests

Alle Tests dieses Tasks werden permanent in `tests/` im Hauptverzeichnis des Projekts abgelegt (siehe `AGENTS.md`).

- De-Interleaving: bekanntes Interleaved-Array ergibt die erwarteten Kanäle (16 Bit und Float).
- Pegel: Sinus mit Amplitude 0,5 ergibt ca. −9 dBFS RMS bzw. −6 dBFS Peak; Stille ergibt einen definierten Minimalwert; Clipping-Erkennung schlägt über 90 % an.
- WAV-Writer: Header-Felder (RIFF, fmt, Kanäle 2, Rate 48000, Bits 16, Datenlänge) stimmen; geschriebene und wieder gelesene Samples sind identisch (dazu einen minimalen WAV-Reader in Dart anlegen, den spätere Tasks nutzen).
- Plattform-Channel: Dart-Seite gegen einen gemockten MethodChannel/EventChannel testen (Start, Blöcke empfangen, Stopp, Fehler bei fehlender Berechtigung).
- Manuelle Geräte-Checkliste: App startet, Berechtigung wird angefragt, beide Pegel reagieren getrennt (Mikrofon oben bzw. unten zuhalten), gespeicherte WAV lässt sich am PC als Stereo öffnen.

## Akzeptanzkriterien

Der Task gilt erst als fertig, wenn alle Punkte erfüllt und durch Tests oder einen konkreten Befehl belegt sind:

- [ ] `fvm flutter test tests/` läuft grün und enthält die oben genannten Tests.
- [ ] `fvm flutter build apk --debug` und `fvm flutter analyze` laufen ohne Fehler.
- [ ] Auf einem echten Gerät zeigt die App zwei unabhängig reagierende Pegel und meldet die genutzte Audioquelle (UNPROCESSED oder Rückfall).
- [ ] Eine gespeicherte WAV-Datei ist Stereo, 48 kHz, 16 Bit; geprüft durch Test des WAV-Readers und manuell am PC.
- [ ] Tatsächlich entstandene Projektstruktur ist in `docs/architecture.md` nachgezogen, Abweichungen bei Testbefehlen in `docs/testing.md`.

## Offene Fragen / Annahmen

- Zielgerätemodell ist noch nicht festgelegt. Ergebnis der Gerätefähigkeiten (UNPROCESSED, Effekte) im Task festhalten.
- Paketname `de.nyooom.app` (festgelegt in `docs/conventions.md`).
- Annahme: Float-Encoding ist nicht nötig, 16 Bit genügt laut PDF 4.2.

## Notizen zu diesem Task

Taskspezifische Informationen während der Arbeit hier festhalten. Taskübergreifendes gehört in `Roadmap/README.md`.

**Stand 2026-11-16 (Agent):**

- Erledigt und belegt: Flutter-Projekt (`de.nyooom.app`, minSdk 24, SDK `^3.14.0`, `test/` entfernt), Kotlin-Plugin `NyooomAudioPlugin`, `StereoRecorder`, De-Interleaving, Pegel, WAV-Writer/-Reader, UI mit zwei Pegelbalken, Quelle/Effektstatus, WAV-Speichern.
- `fvm flutter test tests/`: 42 Tests grün. `fvm flutter analyze`: keine Probleme. `fvm dart format --output=none --set-exit-if-changed lib tests`: sauber. `fvm flutter build apk --debug`: erfolgreich.
- **Offen: manuelle Geräte-Checkliste.** Beim Arbeiten war kein Android-Gerät per adb verbunden. Deshalb bleibt der Task als `RUN_` liegen, bis jemand die App auf einem Gerät geprüft hat.

**Manuelle Geräte-Checkliste (auszufüllen):**

| Prüfung | Ergebnis |
|---|---|
| Gerätemodell / Android-Version | |
| App startet, Berechtigung wird angefragt | |
| Gemeldete Audioquelle (UNPROCESSED / Rückfall) | |
| Effektstatus AGC / NS / AEC | |
| Gemeldete Mikrofone (`getMicrophones`) | |
| Pegel reagieren getrennt (oberes bzw. unteres Mikrofon zuhalten); welcher Kanal = welches Mikrofon | |
| Gespeicherte WAV am PC: Stereo, 48 kHz, 16 Bit | |

WAV vom Gerät holen: `adb exec-out run-as de.nyooom.app ls files/recordings` bzw. `adb exec-out run-as de.nyooom.app cat files/recordings/<name>.wav > aufnahme.local.wav` (Pfad je nach `getApplicationDocumentsDirectory`, ggf. `app_flutter/recordings`).

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

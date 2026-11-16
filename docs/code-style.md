# Code-Styling und Formatierung

> Wann lesen: vor dem Schreiben, Ändern oder Formatieren von Code.

## Werkzeuge

- Formatter: `fvm dart format lib tests`
- Linter: `fvm flutter analyze` mit `flutter_lints`
- Konfiguration liegt in `analysis_options.yaml` (entsteht mit `flutter create` in Task_01); die Regeln dort sind maßgeblich und werden hier nicht wiederholt.
- Kotlin: Standard-Formatierung von Android Studio, kein zusätzlicher Linter.

## Verbindlich

- Physikalische Größen tragen die Einheit im Namen, wenn sie nicht SI-Basiseinheit sind: `speedKmh`, `delayUs`, `distanceM` ist erlaubt, intern wird in SI gerechnet (m, s, m/s, Hz). Umrechnung in km/h nur an der Ausgabegrenze (Datensatz, UI, Export).
- Symbole aus `technik.pdf` (κ, Δ, t0, u, b, c) werden ausgeschrieben benannt (`kappa`, `tdoa`, `t0`, `directionCosine`, `micSpacing`, `speedOfSound`); Formeln im Code mit Verweis auf den PDF-Abschnitt kommentieren (`// technik.pdf 3.4`).
- Keine Zahlenwerte aus `technik.pdf` 9.2 als Literale im Code; sie kommen aus dem Konfigurationsobjekt.
- Signalpuffer als `Float64List`/`Float32List`, nicht `List<double>`, in allen DSP-Pfaden.
- UI-Texte auf Deutsch; Bezeichner, Kommentare im Code und Commit-Nachrichten auf Englisch.

## Empfehlung

- Kleine, reine Funktionen in `lib/core/`; Zustand nur, wo das Streaming es verlangt (Ringpuffer, gleitende Perzentile).
- Ergebnisobjekte statt Exceptions für fachliche Fehlschläge (z. B. Klasse C mit Grund).

---
Pflege: Bei Änderungen an Stil- oder Tool-Regeln diese Datei sofort aktualisieren.

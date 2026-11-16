/// Machine-readable reasons for class B or C (technik.pdf 5.6), with the
/// German text shown in the app and exported as `grund`.
enum DowngradeReason {
  // Class C: event rejected.
  overlap('ueberlappung', 'Überlappung', true),
  residual('reststreuung', 'Reststreuung zu groß', true),
  notMonotonic('nicht_monoton', 'Spur nicht monoton', true),
  outOfRange('suchbereich', 'außerhalb des Suchbereichs', true),
  clipping('uebersteuerung', 'Übersteuerung', true),
  noTrack('keine_spur', 'keine Laufzeitspur', true),

  // Class B: Doppler not usable.
  noTone('kein_ton', 'kein Ton', false),
  acceleration('beschleunigung', 'Beschleunigung', false),
  distanceCheck('abstandspruefung', 'Abstandsprüfung', false);

  const DowngradeReason(this.code, this.text, this.isClassC);

  /// Value of the column `grund_code`.
  final String code;

  /// Value of the column `grund`.
  final String text;
  final bool isClassC;

  static DowngradeReason? fromCode(String? code) {
    for (final r in values) {
      if (r.code == code) return r;
    }
    return null;
  }
}

import 'reasons.dart';

/// Quality class of a measurement (technik.pdf 5.6).
enum QualityClass {
  a('A'),
  b('B'),
  c('C');

  const QualityClass(this.label);
  final String label;

  static QualityClass fromLabel(String label) =>
      values.firstWhere((v) => v.label == label);
}

/// Data record per vehicle pass (technik.pdf 9.1). Speeds in km/h, as in
/// the PDF table; internal computations stay in SI.
class PassRecord {
  const PassRecord({
    required this.zeitUtcMs,
    required this.offsetS,
    required this.richtung,
    required this.klasse,
    required this.v,
    required this.sigmaV,
    required this.vLaufzeit,
    required this.vDoppler,
    required this.kappa,
    required this.dEst,
    required this.nToene,
    required this.restLaufzeitUs,
    required this.pegel,
    required this.dauer,
    required this.reason,
    required this.laneIndex,
    required this.distanceUsedM,
    this.sigmaLaufzeit,
    this.sigmaDoppler,
  });

  /// Time of closest approach t0 (UTC, ms).
  final int zeitUtcMs;

  /// t0 (emission time) relative to the start of the recording in s.
  final double offsetS;

  /// +1 or −1 from the sign of κ.
  final int richtung;
  final QualityClass klasse;

  /// Result speed in km/h (null for class C).
  final double? v;
  final double? sigmaV;

  /// Speed from TDOA and lane distance in km/h.
  final double? vLaufzeit;

  /// Doppler speed in km/h, null without tone.
  final double? vDoppler;

  /// κ in 1/s (signed).
  final double? kappa;

  /// Distance from Doppler and κ in m, null without tone.
  final double? dEst;
  final int nToene;

  /// Residual of the TDOA fit in µs.
  final double? restLaufzeitUs;

  /// Level maximum above the noise floor in dB.
  final double pegel;

  /// Duration above half the peak level in s.
  final double dauer;

  /// Reason for class B or C.
  final DowngradeReason? reason;

  /// Lane used (index in the site) and its distance.
  final int? laneIndex;
  final double? distanceUsedM;

  /// Uncertainties of the single estimates in km/h (not part of 9.1).
  final double? sigmaLaufzeit;
  final double? sigmaDoppler;

  String? get grund => reason?.text;

  PassRecord copyWith({
    QualityClass? klasse,
    double? v,
    double? sigmaV,
    double? vLaufzeit,
    double? vDoppler,
    double? dEst,
    int? nToene,
    DowngradeReason? reason,
    bool clearReason = false,
    double? distanceUsedM,
    double? sigmaLaufzeit,
    double? sigmaDoppler,
  }) => PassRecord(
    zeitUtcMs: zeitUtcMs,
    offsetS: offsetS,
    richtung: richtung,
    klasse: klasse ?? this.klasse,
    v: v ?? this.v,
    sigmaV: sigmaV ?? this.sigmaV,
    vLaufzeit: vLaufzeit ?? this.vLaufzeit,
    vDoppler: vDoppler ?? this.vDoppler,
    kappa: kappa,
    dEst: dEst ?? this.dEst,
    nToene: nToene ?? this.nToene,
    restLaufzeitUs: restLaufzeitUs,
    pegel: pegel,
    dauer: dauer,
    reason: clearReason ? null : (reason ?? this.reason),
    laneIndex: laneIndex,
    distanceUsedM: distanceUsedM ?? this.distanceUsedM,
    sigmaLaufzeit: sigmaLaufzeit ?? this.sigmaLaufzeit,
    sigmaDoppler: sigmaDoppler ?? this.sigmaDoppler,
  );

  /// Field names of technik.pdf 9.1 (plus `grund_code` and helpers).
  Map<String, Object?> toJson() => {
    'zeit': DateTime.fromMillisecondsSinceEpoch(
      zeitUtcMs,
      isUtc: true,
    ).toIso8601String(),
    'zeit_ms': zeitUtcMs,
    'offset_s': offsetS,
    'richtung': richtung,
    'klasse': klasse.label,
    'v': v,
    'sigma_v': sigmaV,
    'v_laufzeit': vLaufzeit,
    'v_doppler': vDoppler,
    'kappa': kappa,
    'd_est': dEst,
    'n_toene': nToene,
    'rest_laufzeit': restLaufzeitUs,
    'pegel': pegel,
    'dauer': dauer,
    'grund': grund,
    'grund_code': reason?.code,
    'spur': laneIndex,
    'abstand': distanceUsedM,
    'sigma_laufzeit': sigmaLaufzeit,
    'sigma_doppler': sigmaDoppler,
  };

  factory PassRecord.fromJson(Map<String, Object?> j) {
    double? d(String k) => (j[k] as num?)?.toDouble();
    return PassRecord(
      zeitUtcMs: (j['zeit_ms'] as num).toInt(),
      offsetS: d('offset_s')!,
      richtung: (j['richtung'] as num).toInt(),
      klasse: QualityClass.fromLabel(j['klasse'] as String),
      v: d('v'),
      sigmaV: d('sigma_v'),
      vLaufzeit: d('v_laufzeit'),
      vDoppler: d('v_doppler'),
      kappa: d('kappa'),
      dEst: d('d_est'),
      nToene: (j['n_toene'] as num).toInt(),
      restLaufzeitUs: d('rest_laufzeit'),
      pegel: d('pegel')!,
      dauer: d('dauer')!,
      reason: DowngradeReason.fromCode(j['grund_code'] as String?),
      laneIndex: (j['spur'] as num?)?.toInt(),
      distanceUsedM: d('abstand'),
      sigmaLaufzeit: d('sigma_laufzeit'),
      sigmaDoppler: d('sigma_doppler'),
    );
  }
}

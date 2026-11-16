/// Central configuration object for all tunable parameters.
///
/// Holds the start values from technik.pdf 9.2 (and a few related limits).
/// Task_02 extends this object with the remaining 9.2 parameters; nothing
/// from 9.2 may appear as a literal elsewhere in the code.
class NyooomConfig {
  const NyooomConfig({this.sampleRate = 48000, this.clipThreshold = 0.9});

  /// Recording sample rate in Hz (technik.pdf 4.2, 9.2).
  final int sampleRate;

  /// Fraction of full scale above which a block counts as clipped
  /// (technik.pdf 4.4, check 3).
  final double clipThreshold;

  factory NyooomConfig.fromJson(Map<String, dynamic> json) {
    const defaults = NyooomConfig();
    return NyooomConfig(
      sampleRate: (json['sampleRate'] as num?)?.toInt() ?? defaults.sampleRate,
      clipThreshold:
          (json['clipThreshold'] as num?)?.toDouble() ?? defaults.clipThreshold,
    );
  }

  Map<String, dynamic> toJson() => {
    'sampleRate': sampleRate,
    'clipThreshold': clipThreshold,
  };
}

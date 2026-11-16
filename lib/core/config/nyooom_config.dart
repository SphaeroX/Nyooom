/// Central configuration object for all tunable parameters.
///
/// Holds the start values from technik.pdf 9.2 plus the related limits named
/// in sections 5.1 to 5.6 and 7.4. Nothing from 9.2 may appear as a literal
/// elsewhere in the code. The shipped copy lives in
/// `assets/nyooom_config.json`; a test keeps it equal to these defaults.
///
/// Units: SI unless the name says otherwise (`...Hz`, `...Db`, `...Kmh`).
class NyooomConfig {
  const NyooomConfig({
    this.sampleRate = 48000,
    this.clipThreshold = 0.9,
    this.highPassHz = 100,
    this.eventBandLowHz = 500,
    this.eventBandHighHz = 4000,
    this.eventLevelStepS = 0.05,
    this.eventLevelSmoothingS = 0.3,
    this.noiseFloorPercentile = 20,
    this.noiseFloorHistoryS = 60,
    this.eventThresholdDb = 10,
    this.eventWindowS = 4,
    this.overlapThresholdDb = 10,
    this.overlapMinDipDb = 1,
    this.eventDurationFraction = 0.5,
    this.gccBlockLength = 2048,
    this.gccHop = 512,
    this.gccBandLowHz = 300,
    this.gccBandHighHz = 8000,
    this.gccZeroPadding = 16,
    this.gccSearchFactor = 1.2,
    this.gccEpsilon = 1e-12,
    this.kappaMin = 0.5,
    this.kappaMax = 8,
    this.kappaGridStep = 0.05,
    this.t0SearchRangeS = 1,
    this.t0SearchStepS = 0.02,
    this.fitOutlierLimitS = 40e-6,
    this.spectrogramWindow = 4096,
    this.spectrogramHop = 512,
    this.spectrogramFftSize = 16384,
    this.toneBandLowHz = 150,
    this.toneBandHighHz = 8000,
    this.toneMinProminenceDb = 8,
    this.toneMinLengthS = 0.5,
    this.toneMaxJumpHz = 15,
    this.toneMedianWidthHz = 150,
    this.toneOffsetRangeS = 0.3,
    this.toneOffsetStepS = 0.05,
    this.dopplerSpeedMin = 3,
    this.dopplerSpeedMax = 25,
    this.dopplerSpeedStep = 0.1,
    this.sharpnessPeakFactor = 3,
    this.sharpnessMaxDirectionCosine = 0.95,
    this.accelerationCheckLimitKmh = 2,
    this.lateralSpreadM = 0.4,
    this.distanceCheckTolerance = 0.25,
    this.residualLimitS = 30e-6,
    this.monotonicMinFraction = 0.8,
    this.sourceHeightM = 0.3,
    this.selfCalibrationMinCount = 30,
    this.selfCalibrationWarnFraction = 0.2,
  });

  /// Recording sample rate in Hz (4.2, 9.2).
  final int sampleRate;

  /// Fraction of full scale above which a sample counts as clipped (4.4).
  final double clipThreshold;

  /// High-pass corner of the pre-processing (5.1).
  final double highPassHz;

  /// Band of the short-term level used for event detection (5.1).
  final double eventBandLowHz;
  final double eventBandHighHz;

  /// Step and smoothing of the short-term level (5.1).
  final double eventLevelStepS;
  final double eventLevelSmoothingS;

  /// Noise floor as this percentile (0..100) of the last [noiseFloorHistoryS].
  final double noiseFloorPercentile;
  final double noiseFloorHistoryS;

  /// Minimum level maximum above the noise floor (5.1).
  final double eventThresholdDb;

  /// Evaluation window from -this to +this around the level maximum (5.1).
  final double eventWindowS;

  /// A second maximum less than this below the first is an overlap (5.1).
  final double overlapThresholdDb;

  /// A second maximum only counts as a separate vehicle if the level dips
  /// at least this much between the two maxima (Task_07).
  final double overlapMinDipDb;

  /// `dauer` (9.1) is the time the level stays above this fraction of the
  /// peak excess over the noise floor ("halber Maximalpegel", Task_07).
  final double eventDurationFraction;

  /// GCC-PHAT block length and hop in samples (5.2).
  final int gccBlockLength;
  final int gccHop;

  /// GCC-PHAT band (5.2).
  final double gccBandLowHz;
  final double gccBandHighHz;

  /// Zero-padding factor of the inverse transform (5.2).
  final int gccZeroPadding;

  /// Delays are searched within +- this factor times b/c (5.2).
  final double gccSearchFactor;

  /// Regularisation of the PHAT normalisation (5.2).
  final double gccEpsilon;

  /// Search range of kappa = v/d in 1/s, both signs (5.3, 9.2).
  final double kappaMin;
  final double kappaMax;

  /// Grid step of the coarse kappa search in 1/s (5.3).
  final double kappaGridStep;

  /// Coarse t0 search: +- range around the level maximum, step (5.3).
  final double t0SearchRangeS;
  final double t0SearchStepS;

  /// Block maxima farther than this from the start curve are ignored (5.3).
  final double fitOutlierLimitS;

  /// Spectrogram window, hop and zero-padded FFT size in samples (5.4).
  final int spectrogramWindow;
  final int spectrogramHop;
  final int spectrogramFftSize;

  /// Band of the tone search (5.4).
  final double toneBandLowHz;
  final double toneBandHighHz;

  /// Minimum prominence of a tone above the running median (5.4).
  final double toneMinProminenceDb;

  /// Minimum length of a tone track (5.4).
  final double toneMinLengthS;

  /// Largest frequency jump between two frames of one tone track.
  final double toneMaxJumpHz;

  /// Width of the running median across frequency (5.4 step 2).
  final double toneMedianWidthHz;

  /// Time offsets between u(t) and the tone tracks, +-range and step (5.4).
  final double toneOffsetRangeS;
  final double toneOffsetStepS;

  /// Speed search of Doppler variant 2 in m/s (5.4).
  final double dopplerSpeedMin;
  final double dopplerSpeedMax;
  final double dopplerSpeedStep;

  /// Variant 2 needs a sharpness maximum above this factor times the
  /// median over all candidates (5.4).
  final double sharpnessPeakFactor;

  /// Variant 2 only uses the part with |u| up to this value (5.4).
  final double sharpnessMaxDirectionCosine;

  /// Doppler is rejected if the acceleration term changes v by more (5.4).
  final double accelerationCheckLimitKmh;

  /// Lateral spread of vehicles within the lane, sigma_d (5.5).
  final double lateralSpreadM;

  /// d_est must lie within +- this fraction of the lane distance (5.5).
  final double distanceCheckTolerance;

  /// Residual limit of the TDOA fit for class C (5.6).
  final double residualLimitS;

  /// Minimum fraction of block maxima that must follow the fitted S curve
  /// for the track to count as monotonic (5.6).
  final double monotonicMinFraction;

  /// Height of the sound source above the road (7.2).
  final double sourceHeightM;

  /// Self-calibration: class-A count per lane and warning limit (7.4).
  final int selfCalibrationMinCount;
  final double selfCalibrationWarnFraction;

  /// Acceleration check limit in m/s.
  double get accelerationCheckLimit => accelerationCheckLimitKmh / 3.6;

  factory NyooomConfig.fromJson(Map<String, dynamic> json) {
    const d = NyooomConfig();
    double f(String key, double fallback) =>
        (json[key] as num?)?.toDouble() ?? fallback;
    int i(String key, int fallback) => (json[key] as num?)?.toInt() ?? fallback;
    return NyooomConfig(
      sampleRate: i('sampleRate', d.sampleRate),
      clipThreshold: f('clipThreshold', d.clipThreshold),
      highPassHz: f('highPassHz', d.highPassHz),
      eventBandLowHz: f('eventBandLowHz', d.eventBandLowHz),
      eventBandHighHz: f('eventBandHighHz', d.eventBandHighHz),
      eventLevelStepS: f('eventLevelStepS', d.eventLevelStepS),
      eventLevelSmoothingS: f('eventLevelSmoothingS', d.eventLevelSmoothingS),
      noiseFloorPercentile: f('noiseFloorPercentile', d.noiseFloorPercentile),
      noiseFloorHistoryS: f('noiseFloorHistoryS', d.noiseFloorHistoryS),
      eventThresholdDb: f('eventThresholdDb', d.eventThresholdDb),
      eventWindowS: f('eventWindowS', d.eventWindowS),
      overlapThresholdDb: f('overlapThresholdDb', d.overlapThresholdDb),
      overlapMinDipDb: f('overlapMinDipDb', d.overlapMinDipDb),
      eventDurationFraction: f(
        'eventDurationFraction',
        d.eventDurationFraction,
      ),
      gccBlockLength: i('gccBlockLength', d.gccBlockLength),
      gccHop: i('gccHop', d.gccHop),
      gccBandLowHz: f('gccBandLowHz', d.gccBandLowHz),
      gccBandHighHz: f('gccBandHighHz', d.gccBandHighHz),
      gccZeroPadding: i('gccZeroPadding', d.gccZeroPadding),
      gccSearchFactor: f('gccSearchFactor', d.gccSearchFactor),
      gccEpsilon: f('gccEpsilon', d.gccEpsilon),
      kappaMin: f('kappaMin', d.kappaMin),
      kappaMax: f('kappaMax', d.kappaMax),
      kappaGridStep: f('kappaGridStep', d.kappaGridStep),
      t0SearchRangeS: f('t0SearchRangeS', d.t0SearchRangeS),
      t0SearchStepS: f('t0SearchStepS', d.t0SearchStepS),
      fitOutlierLimitS: f('fitOutlierLimitS', d.fitOutlierLimitS),
      spectrogramWindow: i('spectrogramWindow', d.spectrogramWindow),
      spectrogramHop: i('spectrogramHop', d.spectrogramHop),
      spectrogramFftSize: i('spectrogramFftSize', d.spectrogramFftSize),
      toneBandLowHz: f('toneBandLowHz', d.toneBandLowHz),
      toneBandHighHz: f('toneBandHighHz', d.toneBandHighHz),
      toneMinProminenceDb: f('toneMinProminenceDb', d.toneMinProminenceDb),
      toneMinLengthS: f('toneMinLengthS', d.toneMinLengthS),
      toneMaxJumpHz: f('toneMaxJumpHz', d.toneMaxJumpHz),
      toneMedianWidthHz: f('toneMedianWidthHz', d.toneMedianWidthHz),
      toneOffsetRangeS: f('toneOffsetRangeS', d.toneOffsetRangeS),
      toneOffsetStepS: f('toneOffsetStepS', d.toneOffsetStepS),
      dopplerSpeedMin: f('dopplerSpeedMin', d.dopplerSpeedMin),
      dopplerSpeedMax: f('dopplerSpeedMax', d.dopplerSpeedMax),
      dopplerSpeedStep: f('dopplerSpeedStep', d.dopplerSpeedStep),
      sharpnessPeakFactor: f('sharpnessPeakFactor', d.sharpnessPeakFactor),
      sharpnessMaxDirectionCosine: f(
        'sharpnessMaxDirectionCosine',
        d.sharpnessMaxDirectionCosine,
      ),
      accelerationCheckLimitKmh: f(
        'accelerationCheckLimitKmh',
        d.accelerationCheckLimitKmh,
      ),
      lateralSpreadM: f('lateralSpreadM', d.lateralSpreadM),
      distanceCheckTolerance: f(
        'distanceCheckTolerance',
        d.distanceCheckTolerance,
      ),
      residualLimitS: f('residualLimitS', d.residualLimitS),
      monotonicMinFraction: f('monotonicMinFraction', d.monotonicMinFraction),
      sourceHeightM: f('sourceHeightM', d.sourceHeightM),
      selfCalibrationMinCount: i(
        'selfCalibrationMinCount',
        d.selfCalibrationMinCount,
      ),
      selfCalibrationWarnFraction: f(
        'selfCalibrationWarnFraction',
        d.selfCalibrationWarnFraction,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'sampleRate': sampleRate,
    'clipThreshold': clipThreshold,
    'highPassHz': highPassHz,
    'eventBandLowHz': eventBandLowHz,
    'eventBandHighHz': eventBandHighHz,
    'eventLevelStepS': eventLevelStepS,
    'eventLevelSmoothingS': eventLevelSmoothingS,
    'noiseFloorPercentile': noiseFloorPercentile,
    'noiseFloorHistoryS': noiseFloorHistoryS,
    'eventThresholdDb': eventThresholdDb,
    'eventWindowS': eventWindowS,
    'overlapThresholdDb': overlapThresholdDb,
    'overlapMinDipDb': overlapMinDipDb,
    'eventDurationFraction': eventDurationFraction,
    'gccBlockLength': gccBlockLength,
    'gccHop': gccHop,
    'gccBandLowHz': gccBandLowHz,
    'gccBandHighHz': gccBandHighHz,
    'gccZeroPadding': gccZeroPadding,
    'gccSearchFactor': gccSearchFactor,
    'gccEpsilon': gccEpsilon,
    'kappaMin': kappaMin,
    'kappaMax': kappaMax,
    'kappaGridStep': kappaGridStep,
    't0SearchRangeS': t0SearchRangeS,
    't0SearchStepS': t0SearchStepS,
    'fitOutlierLimitS': fitOutlierLimitS,
    'spectrogramWindow': spectrogramWindow,
    'spectrogramHop': spectrogramHop,
    'spectrogramFftSize': spectrogramFftSize,
    'toneBandLowHz': toneBandLowHz,
    'toneBandHighHz': toneBandHighHz,
    'toneMinProminenceDb': toneMinProminenceDb,
    'toneMinLengthS': toneMinLengthS,
    'toneMaxJumpHz': toneMaxJumpHz,
    'toneMedianWidthHz': toneMedianWidthHz,
    'toneOffsetRangeS': toneOffsetRangeS,
    'toneOffsetStepS': toneOffsetStepS,
    'dopplerSpeedMin': dopplerSpeedMin,
    'dopplerSpeedMax': dopplerSpeedMax,
    'dopplerSpeedStep': dopplerSpeedStep,
    'sharpnessPeakFactor': sharpnessPeakFactor,
    'sharpnessMaxDirectionCosine': sharpnessMaxDirectionCosine,
    'accelerationCheckLimitKmh': accelerationCheckLimitKmh,
    'lateralSpreadM': lateralSpreadM,
    'distanceCheckTolerance': distanceCheckTolerance,
    'residualLimitS': residualLimitS,
    'monotonicMinFraction': monotonicMinFraction,
    'sourceHeightM': sourceHeightM,
    'selfCalibrationMinCount': selfCalibrationMinCount,
    'selfCalibrationWarnFraction': selfCalibrationWarnFraction,
  };
}

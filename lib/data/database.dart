import 'package:drift/drift.dart';

part 'database.g.dart';

/// A phone (model) plus the input device used (internal or USB interface).
@DataClassName('DeviceRow')
class Devices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get model => text()();
  TextColumn get inputDevice => text().withDefault(const Constant('intern'))();
}

/// Calibration of b and Δ0 for a device (technik.pdf 7.1).
@DataClassName('CalibrationRow')
class Calibrations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deviceId =>
      integer().references(Devices, #id, onDelete: KeyAction.cascade)();
  RealColumn get micSpacingM => real()();
  RealColumn get channelOffsetS => real()();
  RealColumn get temperatureC => real()();
  BoolColumn get swapChannels => boolean().withDefault(const Constant(false))();
  IntColumn get createdAtUtcMs => integer()();

  /// Results of the suitability checks (technik.pdf 4.4) as JSON.
  TextColumn get checksJson => text().nullable()();
}

@DataClassName('SiteRow')
class Sites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get micHeightM => real()();
  RealColumn get speedLimitKmh => real()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  /// Compass bearing of the +x direction in degrees (schema 4).
  RealColumn get plusXBearingDeg =>
      real().named('plus_x_bearing_deg').nullable()();
}

@DataClassName('LaneRow')
class Lanes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get siteId =>
      integer().references(Sites, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  RealColumn get horizontalDistanceM => real()();
  IntColumn get direction => integer()();
}

@DataClassName('SeriesRow')
class MeasurementSeries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get siteId =>
      integer().references(Sites, #id, onDelete: KeyAction.cascade)();
  IntColumn get deviceId => integer().nullable().references(
    Devices,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get calibrationId => integer().nullable().references(
    Calibrations,
    #id,
    onDelete: KeyAction.setNull,
  )();
  RealColumn get temperatureC => real()();
  RealColumn get speedOfSound => real()();
  RealColumn get sourceHeightM => real()();
  IntColumn get startedAtUtcMs => integer()();
  IntColumn get endedAtUtcMs => integer().nullable()();
  TextColumn get directory => text()();
  BoolColumn get saveRawAudio => boolean().withDefault(const Constant(true))();
  BoolColumn get simulated => boolean().withDefault(const Constant(false))();
  TextColumn get configJson => text()();

  /// Recording parts of a continued series as JSON (schema 5); null for
  /// one continuous recording.
  TextColumn get segmentsJson => text().nullable()();

  /// Effective microphone spacing in m, channel offset in s and number of
  /// passes they were learned from (schema 6); null = calibration is used.
  RealColumn get learnedMicSpacingM => real().nullable()();
  RealColumn get learnedChannelOffsetS => real().nullable()();
  IntColumn get learnedPassCount => integer().nullable()();
}

/// One vehicle pass; columns named as in technik.pdf 9.1.
@DataClassName('PassRow')
class Passes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get seriesId => integer().references(
    MeasurementSeries,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// Time of closest approach (UTC, ms).
  IntColumn get zeit => integer()();

  /// Time of closest approach relative to the recording start in s.
  RealColumn get offsetS => real()();
  IntColumn get richtung => integer()();
  TextColumn get klasse => text()();
  RealColumn get v => real().nullable()();
  RealColumn get sigmaV => real().named('sigma_v').nullable()();
  RealColumn get vLaufzeit => real().named('v_laufzeit').nullable()();
  RealColumn get vDoppler => real().named('v_doppler').nullable()();
  RealColumn get kappa => real().nullable()();
  RealColumn get dEst => real().named('d_est').nullable()();
  IntColumn get nToene => integer().named('n_toene')();
  RealColumn get restLaufzeit => real().named('rest_laufzeit').nullable()();
  RealColumn get pegel => real()();
  RealColumn get dauer => real()();
  TextColumn get grund => text().nullable()();

  /// Machine-readable reason code (docs/conventions.md).
  TextColumn get grundCode => text().named('grund_code').nullable()();
  IntColumn get laneIndex => integer().nullable()();
  RealColumn get distanceUsedM => real().nullable()();

  /// Uncertainties of the single estimates in km/h (schema 2).
  RealColumn get sigmaLaufzeit => real().named('sigma_laufzeit').nullable()();
  RealColumn get sigmaDoppler => real().named('sigma_doppler').nullable()();
}

/// GPS reference drive (technik.pdf 8.1, schema 3).
@DataClassName('ReferenceTrackRow')
class ReferenceTracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// `logger`, `gpx` or `csv`.
  TextColumn get source => text()();
  IntColumn get siteId => integer().nullable().references(
    Sites,
    #id,
    onDelete: KeyAction.setNull,
  )();
  IntColumn get createdAtUtcMs => integer()();
}

@DataClassName('ReferencePointRow')
class ReferencePoints extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId =>
      integer().references(ReferenceTracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get timeUtcMs => integer()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get speedMs => real().nullable()();
  RealColumn get accuracyM => real().nullable()();
  RealColumn get speedAccuracy => real().nullable()();
  BoolColumn get speedDerived => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(
  tables: [
    Devices,
    Calibrations,
    Sites,
    Lanes,
    MeasurementSeries,
    Passes,
    ReferenceTracks,
    ReferencePoints,
  ],
)
class NyooomDatabase extends _$NyooomDatabase {
  NyooomDatabase(super.executor);

  /// Schema history: 1 = Task_04; 2 = Task_09 (passes.sigma_laufzeit,
  /// passes.sigma_doppler); 3 = Task_15 (reference_tracks,
  /// reference_points); 4 = Task_16 (sites.plus_x_bearing_deg);
  /// 5 = continued series (measurement_series.segments_json);
  /// 6 = spacing learned from the passes
  /// (measurement_series.learned_mic_spacing_m, learned_channel_offset_s,
  /// learned_pass_count).
  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(passes, passes.sigmaLaufzeit);
        await m.addColumn(passes, passes.sigmaDoppler);
      }
      if (from < 3) {
        await m.createTable(referenceTracks);
        await m.createTable(referencePoints);
      }
      if (from < 4 && !await _hasColumn('sites', 'plus_x_bearing_deg')) {
        await m.addColumn(sites, sites.plusXBearingDeg);
      }
      if (from < 5 &&
          !await _hasColumn('measurement_series', 'segments_json')) {
        await m.addColumn(measurementSeries, measurementSeries.segmentsJson);
      }
      if (from < 6) {
        for (final column in [
          measurementSeries.learnedMicSpacingM,
          measurementSeries.learnedChannelOffsetS,
          measurementSeries.learnedPassCount,
        ]) {
          if (!await _hasColumn('measurement_series', column.name)) {
            await m.addColumn(measurementSeries, column);
          }
        }
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<bool> _hasColumn(String table, String column) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.any((r) => r.read<String>('name') == column);
  }
}

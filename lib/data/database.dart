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
}

@DriftDatabase(
  tables: [Devices, Calibrations, Sites, Lanes, MeasurementSeries, Passes],
)
class NyooomDatabase extends _$NyooomDatabase {
  NyooomDatabase(super.executor);

  /// Schema history: 1 = Task_04.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

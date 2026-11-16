import 'package:drift/drift.dart';

import '../core/model/acoustics.dart';
import '../core/site/site.dart';
import 'database.dart';

/// A site loaded from the database.
class StoredSite {
  const StoredSite(this.id, this.spec);
  final int id;
  final SiteSpec spec;
}

/// A measurement series with its site, as shown in lists.
class StoredSeries {
  const StoredSeries({
    required this.row,
    required this.site,
    required this.slantDistances,
  });

  final SeriesRow row;
  final StoredSite site;

  /// Slant distance per lane of [site], same order as its lanes.
  final List<double> slantDistances;

  int get id => row.id;
  String get siteName => site.spec.name;
  double get speedOfSound => row.speedOfSound;
  double get temperatureC => row.temperatureC;
  int get startedAtUtcMs => row.startedAtUtcMs;
  int? get endedAtUtcMs => row.endedAtUtcMs;
  String get directory => row.directory;

  /// Duration in s, null while recording.
  double? get durationS {
    final end = row.endedAtUtcMs;
    return end == null ? null : (end - row.startedAtUtcMs) / 1000;
  }
}

/// Data access for devices, sites and measurement series.
class NyooomRepository {
  NyooomRepository(this.db);

  final NyooomDatabase db;

  Future<int> createSite(SiteSpec spec) => db.transaction(() async {
    final id = await db
        .into(db.sites)
        .insert(
          SitesCompanion.insert(
            name: spec.name.trim(),
            micHeightM: spec.micHeight,
            speedLimitKmh: spec.speedLimitKmh,
            latitude: Value(spec.latitude),
            longitude: Value(spec.longitude),
          ),
        );
    await _insertLanes(id, spec.lanes);
    return id;
  });

  Future<void> updateSite(int id, SiteSpec spec) => db.transaction(() async {
    await (db.update(db.sites)..where((s) => s.id.equals(id))).write(
      SitesCompanion(
        name: Value(spec.name.trim()),
        micHeightM: Value(spec.micHeight),
        speedLimitKmh: Value(spec.speedLimitKmh),
        latitude: Value(spec.latitude),
        longitude: Value(spec.longitude),
      ),
    );
    await (db.delete(db.lanes)..where((l) => l.siteId.equals(id))).go();
    await _insertLanes(id, spec.lanes);
  });

  Future<void> _insertLanes(int siteId, List<LaneSpec> lanes) async {
    for (var i = 0; i < lanes.length; i++) {
      await db
          .into(db.lanes)
          .insert(
            LanesCompanion.insert(
              siteId: siteId,
              position: i,
              horizontalDistanceM: lanes[i].horizontalDistance,
              direction: lanes[i].direction,
            ),
          );
    }
  }

  Future<List<StoredSite>> sites() async {
    final rows = await (db.select(
      db.sites,
    )..orderBy([(s) => OrderingTerm.asc(s.name)])).get();
    return [for (final r in rows) await _toSite(r)];
  }

  Future<StoredSite?> site(int id) async {
    final row = await (db.select(
      db.sites,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toSite(row);
  }

  Future<StoredSite> _toSite(SiteRow row) async {
    final lanes =
        await (db.select(db.lanes)
              ..where((l) => l.siteId.equals(row.id))
              ..orderBy([(l) => OrderingTerm.asc(l.position)]))
            .get();
    return StoredSite(
      row.id,
      SiteSpec(
        name: row.name,
        lanes: [
          for (final l in lanes)
            LaneSpec(
              horizontalDistance: l.horizontalDistanceM,
              direction: l.direction,
            ),
        ],
        micHeight: row.micHeightM,
        speedLimitKmh: row.speedLimitKmh,
        latitude: row.latitude,
        longitude: row.longitude,
      ),
    );
  }

  Future<void> deleteSite(int id) =>
      (db.delete(db.sites)..where((s) => s.id.equals(id))).go();

  /// Id of the device row for [model] and [inputDevice], created on demand.
  Future<int> ensureDevice(
    String model, {
    String inputDevice = 'intern',
  }) async {
    final existing =
        await (db.select(db.devices)..where(
              (d) => d.model.equals(model) & d.inputDevice.equals(inputDevice),
            ))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    return db
        .into(db.devices)
        .insert(
          DevicesCompanion.insert(
            model: model,
            inputDevice: Value(inputDevice),
          ),
        );
  }

  /// Creates a series; c follows from the temperature (technik.pdf 7.3).
  Future<int> createSeries({
    required int siteId,
    int? deviceId,
    int? calibrationId,
    required double temperatureC,
    required int startedAtUtcMs,
    required String directory,
    required double sourceHeight,
    required String configJson,
    bool saveRawAudio = true,
    bool simulated = false,
  }) => db
      .into(db.measurementSeries)
      .insert(
        MeasurementSeriesCompanion.insert(
          siteId: siteId,
          deviceId: Value(deviceId),
          calibrationId: Value(calibrationId),
          temperatureC: temperatureC,
          speedOfSound: speedOfSound(temperatureC),
          sourceHeightM: sourceHeight,
          startedAtUtcMs: startedAtUtcMs,
          directory: directory,
          saveRawAudio: Value(saveRawAudio),
          simulated: Value(simulated),
          configJson: configJson,
        ),
      );

  Future<void> setSeriesDirectory(int id, String directory) =>
      (db.update(db.measurementSeries)..where((s) => s.id.equals(id))).write(
        MeasurementSeriesCompanion(directory: Value(directory)),
      );

  Future<void> finishSeries(int id, {required int endedAtUtcMs}) =>
      (db.update(db.measurementSeries)..where((s) => s.id.equals(id))).write(
        MeasurementSeriesCompanion(endedAtUtcMs: Value(endedAtUtcMs)),
      );

  Future<StoredSeries?> series(int id) async {
    final row = await (db.select(
      db.measurementSeries,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toSeries(row);
  }

  Future<List<StoredSeries>> allSeries() async {
    final rows = await (db.select(
      db.measurementSeries,
    )..orderBy([(s) => OrderingTerm.desc(s.startedAtUtcMs)])).get();
    return [for (final r in rows) await _toSeries(r)];
  }

  Future<StoredSeries> _toSeries(SeriesRow row) async {
    final site = (await this.site(row.siteId))!;
    return StoredSeries(
      row: row,
      site: site,
      slantDistances: [
        for (final lane in site.spec.lanes)
          site.spec.slantDistance(lane, sourceHeight: row.sourceHeightM),
      ],
    );
  }

  Future<void> deleteSeries(int id) =>
      (db.delete(db.measurementSeries)..where((s) => s.id.equals(id))).go();

  /// Most recent calibration of a device, or null.
  Future<CalibrationRow?> latestCalibration(int deviceId) =>
      (db.select(db.calibrations)
            ..where((c) => c.deviceId.equals(deviceId))
            ..orderBy([(c) => OrderingTerm.desc(c.createdAtUtcMs)])
            ..limit(1))
          .getSingleOrNull();

  Future<CalibrationRow?> calibration(int id) => (db.select(
    db.calibrations,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> addCalibration(CalibrationsCompanion calibration) =>
      db.into(db.calibrations).insert(calibration);

  Future<List<DeviceRow>> devices() => db.select(db.devices).get();
}

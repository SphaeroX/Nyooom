import 'package:drift/drift.dart';

import '../core/calibration/plateau_calibration.dart';
import '../core/calibration/self_calibration.dart';
import '../core/config/nyooom_config.dart';
import '../core/model/acoustics.dart';
import '../core/pipeline/analysis_setup.dart';
import '../core/pipeline/pass_record.dart';
import '../core/pipeline/reasons.dart';
import '../core/reference/reference_track.dart';
import '../core/series/recording_segment.dart';
import '../core/series/temperature_log.dart';
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

  /// Continuous recording parts; one for a series that was never
  /// continued.
  List<RecordingSegment> get segments {
    final stored = segmentsFromJson(row.segmentsJson);
    return stored.isNotEmpty
        ? stored
        : [RecordingSegment(offsetS: 0, startedAtUtcMs: row.startedAtUtcMs)];
  }

  /// Temperature readings over the recording, starting with the start
  /// value; empty if the start temperature held throughout.
  List<TemperatureReading> get temperatureLog =>
      temperatureLogFromJson(row.temperatureLogJson);

  /// Recorded duration in s without pauses, null while recording.
  double? get durationS =>
      recordedDurationS(segments, endedAtUtcMs: row.endedAtUtcMs);
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
            plusXBearingDeg: Value(spec.plusXBearingDeg),
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
        plusXBearingDeg: Value(spec.plusXBearingDeg),
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
        plusXBearingDeg: row.plusXBearingDeg,
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

  /// Input device name (`intern` or USB device) the series recorded with.
  Future<String> inputDeviceOf(int seriesId) async {
    final row = (await series(seriesId))?.row;
    final deviceId = row?.deviceId;
    if (deviceId == null) return 'intern';
    final device = await (db.select(
      db.devices,
    )..where((d) => d.id.equals(deviceId))).getSingleOrNull();
    return device?.inputDevice ?? 'intern';
  }

  /// Reopens a finished series: the recording continues at [offsetS] of
  /// its signal, at wall-clock time [resumedAtUtcMs].
  Future<void> resumeSeries(
    int id, {
    required double offsetS,
    required int resumedAtUtcMs,
  }) async {
    final current = (await series(id))!;
    final segments = [
      ...current.segments,
      RecordingSegment(offsetS: offsetS, startedAtUtcMs: resumedAtUtcMs),
    ];
    await (db.update(
      db.measurementSeries,
    )..where((s) => s.id.equals(id))).write(
      MeasurementSeriesCompanion(
        endedAtUtcMs: const Value(null),
        segmentsJson: Value(segmentsToJson(segments)),
      ),
    );
  }

  /// Stores a new temperature of series [id] (automatic update). The first
  /// update also stores the start temperature at position 0; an unchanged
  /// temperature is not stored again.
  Future<void> addTemperatureReading(int id, TemperatureReading reading) async {
    final current = (await series(id))!;
    final stored = current.temperatureLog;
    final log = stored.isNotEmpty
        ? stored
        : [
            TemperatureReading(
              offsetS: 0,
              temperatureC: current.temperatureC,
              utcMs: current.startedAtUtcMs,
              source: TemperatureReading.sourceStart,
            ),
          ];
    final updated = appendTemperatureReading(log, reading);
    if (stored.isNotEmpty && identical(updated, stored)) return;
    await (db.update(
      db.measurementSeries,
    )..where((s) => s.id.equals(id))).write(
      MeasurementSeriesCompanion(
        temperatureLogJson: Value(temperatureLogToJson(updated)),
      ),
    );
  }

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

  /// b and Δ0 learned from the passes of series [id], or null.
  Future<LearnedSpacing?> learnedSpacing(int id) async {
    final row = (await series(id))?.row;
    final spacing = row?.learnedMicSpacingM;
    if (row == null || spacing == null) return null;
    return LearnedSpacing(
      micSpacing: spacing,
      channelOffset: row.learnedChannelOffsetS ?? 0,
      passCount: row.learnedPassCount ?? 0,
    );
  }

  /// Stores the learned b and Δ0 of series [id]; null goes back to the
  /// calibration.
  Future<void> setLearnedSpacing(int id, LearnedSpacing? learned) =>
      (db.update(db.measurementSeries)..where((s) => s.id.equals(id))).write(
        MeasurementSeriesCompanion(
          learnedMicSpacingM: Value(learned?.micSpacing),
          learnedChannelOffsetS: Value(learned?.channelOffset),
          learnedPassCount: Value(learned?.passCount),
        ),
      );

  /// Constants for evaluating series [id]: calibration (or defaults), c and
  /// lane geometry. b and Δ0 learned from the passes of the series replace
  /// the calibration unless [learnedSpacing] is false.
  Future<AnalysisSetup?> analysisSetup(
    int id, {
    bool learnedSpacing = true,
  }) async {
    final series = await this.series(id);
    if (series == null) return null;
    final calId = series.row.calibrationId;
    final cal = calId == null ? null : await calibration(calId);
    final learned = learnedSpacing ? await this.learnedSpacing(id) : null;
    return AnalysisSetup(
      micSpacing:
          learned?.micSpacing ??
          cal?.micSpacingM ??
          AnalysisSetup.defaultMicSpacing,
      channelOffset: learned?.channelOffset ?? cal?.channelOffsetS ?? 0,
      swapChannels: cal?.swapChannels ?? false,
      speedOfSound: series.speedOfSound,
      speedLimitKmh: series.site.spec.speedLimitKmh,
      startedAtUtcMs: series.startedAtUtcMs,
      segments: series.segments,
      temperatureLog: series.temperatureLog.isEmpty
          ? null
          : series.temperatureLog,
      lanes: [
        for (var i = 0; i < series.site.spec.lanes.length; i++)
          LaneGeometry(
            index: i,
            direction: series.site.spec.lanes[i].direction,
            slantDistance: series.slantDistances[i],
          ),
      ],
    );
  }

  /// Replaces all pass records of a series (re-evaluation).
  Future<void> replacePasses(int seriesId, List<PassRecord> records) =>
      db.transaction(() async {
        await (db.delete(
          db.passes,
        )..where((p) => p.seriesId.equals(seriesId))).go();
        await db.batch((b) {
          b.insertAll(db.passes, [
            for (final r in records) passCompanion(seriesId, r),
          ]);
        });
      });

  Future<void> addPass(int seriesId, PassRecord record) =>
      db.into(db.passes).insert(passCompanion(seriesId, record));

  Future<List<PassRecord>> passes(int seriesId) async {
    final rows =
        await (db.select(db.passes)
              ..where((p) => p.seriesId.equals(seriesId))
              ..orderBy([(p) => OrderingTerm.asc(p.zeit)]))
            .get();
    return rows.map(passFromRow).toList();
  }

  /// All pass records of all series of a site.
  Future<List<PassRecord>> passesForSite(int siteId) async {
    final query = db.select(db.passes).join([
      innerJoin(
        db.measurementSeries,
        db.measurementSeries.id.equalsExp(db.passes.seriesId),
      ),
    ])..where(db.measurementSeries.siteId.equals(siteId));
    query.orderBy([OrderingTerm.asc(db.passes.zeit)]);
    final rows = await query.get();
    return [for (final r in rows) passFromRow(r.readTable(db.passes))];
  }

  /// Analysis setup with the self-calibrated lane distances of the site
  /// (technik.pdf 7.4) and the learning state per lane.
  Future<({AnalysisSetup setup, List<LaneLearning> learning})?> learnedSetup(
    int seriesId,
    NyooomConfig config, {
    bool learnedSpacing = true,
  }) async {
    final setup = await analysisSetup(seriesId, learnedSpacing: learnedSpacing);
    final series = await this.series(seriesId);
    if (setup == null || series == null) return null;
    final learning = learnLaneDistances(
      await passesForSite(series.site.id),
      lanes: setup.lanes,
      config: config,
    );
    return (setup: withLearnedDistances(setup, learning), learning: learning);
  }

  /// Recomputes all records of all series of [siteId] with the effective
  /// lane distances; returns the number of changed records.
  Future<int> recomputeSiteWithLearning(int siteId, NyooomConfig config) async {
    final seriesRows = await (db.select(
      db.measurementSeries,
    )..where((s) => s.siteId.equals(siteId))).get();
    if (seriesRows.isEmpty) return 0;
    final learned = (await learnedSetup(seriesRows.first.id, config))!;
    var changed = 0;
    for (final row in seriesRows) {
      final records = await passes(row.id);
      final updated = [
        for (final r in records)
          () {
            final lane = learned.setup.lanes
                .where((l) => l.index == r.laneIndex)
                .firstOrNull;
            if (lane == null || r.distanceUsedM == lane.slantDistance) return r;
            changed++;
            return recomputeWithDistance(r, lane.slantDistance, config);
          }(),
      ];
      await replacePasses(row.id, updated);
    }
    return changed;
  }

  /// Stores a reference drive; returns its id.
  Future<int> addReferenceTrack(ReferenceTrack track, {int? siteId}) =>
      db.transaction(() async {
        final id = await db
            .into(db.referenceTracks)
            .insert(
              ReferenceTracksCompanion.insert(
                name: track.name,
                source: track.source.name,
                siteId: Value(siteId),
                createdAtUtcMs: DateTime.now().toUtc().millisecondsSinceEpoch,
              ),
            );
        await db.batch((b) {
          b.insertAll(db.referencePoints, [
            for (final p in track.points)
              ReferencePointsCompanion.insert(
                trackId: id,
                timeUtcMs: p.timeUtcMs,
                lat: p.lat,
                lon: p.lon,
                speedMs: Value(p.speed),
                accuracyM: Value(p.accuracyM),
                speedAccuracy: Value(p.speedAccuracy),
                speedDerived: Value(p.speedDerived),
              ),
          ]);
        });
        return id;
      });

  Future<List<ReferenceTrackRow>> referenceTracks() => (db.select(
    db.referenceTracks,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAtUtcMs)])).get();

  Future<ReferenceTrack?> referenceTrack(int id) async {
    final row = await (db.select(
      db.referenceTracks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    final points =
        await (db.select(db.referencePoints)
              ..where((p) => p.trackId.equals(id))
              ..orderBy([(p) => OrderingTerm.asc(p.timeUtcMs)]))
            .get();
    return ReferenceTrack(
      name: row.name,
      source: ReferenceSource.values.byName(row.source),
      points: [
        for (final p in points)
          ReferencePoint(
            timeUtcMs: p.timeUtcMs,
            lat: p.lat,
            lon: p.lon,
            speed: p.speedMs,
            accuracyM: p.accuracyM,
            speedAccuracy: p.speedAccuracy,
            speedDerived: p.speedDerived,
          ),
      ],
    );
  }

  Future<void> deleteReferenceTrack(int id) =>
      (db.delete(db.referenceTracks)..where((t) => t.id.equals(id))).go();

  static PassesCompanion passCompanion(int seriesId, PassRecord r) =>
      PassesCompanion.insert(
        seriesId: seriesId,
        zeit: r.zeitUtcMs,
        offsetS: r.offsetS,
        richtung: r.richtung,
        klasse: r.klasse.label,
        v: Value(r.v),
        sigmaV: Value(r.sigmaV),
        vLaufzeit: Value(r.vLaufzeit),
        vDoppler: Value(r.vDoppler),
        kappa: Value(r.kappa),
        dEst: Value(r.dEst),
        nToene: r.nToene,
        restLaufzeit: Value(r.restLaufzeitUs),
        pegel: r.pegel,
        dauer: r.dauer,
        grund: Value(r.grund),
        grundCode: Value(r.reason?.code),
        laneIndex: Value(r.laneIndex),
        distanceUsedM: Value(r.distanceUsedM),
        sigmaLaufzeit: Value(r.sigmaLaufzeit),
        sigmaDoppler: Value(r.sigmaDoppler),
      );

  static PassRecord passFromRow(PassRow p) => PassRecord(
    zeitUtcMs: p.zeit,
    offsetS: p.offsetS,
    richtung: p.richtung,
    klasse: QualityClass.fromLabel(p.klasse),
    v: p.v,
    sigmaV: p.sigmaV,
    vLaufzeit: p.vLaufzeit,
    vDoppler: p.vDoppler,
    kappa: p.kappa,
    dEst: p.dEst,
    nToene: p.nToene,
    restLaufzeitUs: p.restLaufzeit,
    pegel: p.pegel,
    dauer: p.dauer,
    reason: DowngradeReason.fromCode(p.grundCode),
    laneIndex: p.laneIndex,
    distanceUsedM: p.distanceUsedM,
    sigmaLaufzeit: p.sigmaLaufzeit,
    sigmaDoppler: p.sigmaDoppler,
  );
}

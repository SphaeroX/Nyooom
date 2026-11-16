import 'dart:io';

import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../audio/simulated_stereo_recorder.dart';
import '../audio/stereo_recorder.dart';
import '../core/sim/traffic.dart';
import '../data/database.dart';
import '../data/repository.dart';
import '../data/series_storage.dart';
import 'recorder/recorder_controller.dart';

export 'recorder/recorder_controller.dart'
    show capabilitiesProvider, configProvider, stereoRecorderProvider;

/// App database (SQLite file `nyooom` in the app support directory).
final databaseProvider = Provider<NyooomDatabase>((ref) {
  final db = NyooomDatabase(driftDatabase(name: 'nyooom'));
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<NyooomRepository>(
  (ref) => NyooomRepository(ref.watch(databaseProvider)),
);

final appDirectoryProvider = FutureProvider<Directory>(
  (ref) => getApplicationDocumentsDirectory(),
);

final seriesStorageProvider = FutureProvider<SeriesStorage>(
  (ref) async => SeriesStorage(await ref.watch(appDirectoryProvider.future)),
);

/// Creates the audio source of a series: microphones or simulated traffic.
typedef RecorderFactory = StereoRecorder Function({
  required bool simulate,
  required List<TrafficLane> lanes,
});

final recorderFactoryProvider = Provider<RecorderFactory>(
  (ref) =>
      ({required bool simulate, required List<TrafficLane> lanes}) => simulate
      ? SimulatedStereoRecorder(
          lanes: lanes,
          seed: DateTime.now().millisecondsSinceEpoch & 0xffff,
        )
      : ref.read(stereoRecorderProvider),
);

/// Whether new series use the simulation by default. Off: on a phone the
/// microphones are the normal source (Task_20).
final simulationDefaultProvider = NotifierProvider<SimulationDefault, bool>(
  SimulationDefault.new,
);

class SimulationDefault extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final sitesProvider = FutureProvider<List<StoredSite>>(
  (ref) => ref.watch(repositoryProvider).sites(),
);

final seriesListProvider = FutureProvider<List<StoredSeries>>(
  (ref) => ref.watch(repositoryProvider).allSeries(),
);

/// Size in bytes of the files of a series.
final seriesSizeProvider = FutureProvider.family<int, int>((ref, id) async {
  final storage = await ref.watch(seriesStorageProvider.future);
  return storage.sizeBytes(id);
});

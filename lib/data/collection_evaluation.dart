import 'dart:convert';
import 'dart:io';

import '../audio/wav.dart';
import '../core/calibration/plateau_calibration.dart';
import '../core/collect/collection_manifest.dart';
import '../core/config/nyooom_config.dart';
import '../core/events/event_detector.dart';
import '../core/pipeline/analysis_setup.dart';
import '../core/pipeline/pass_record.dart';
import '../core/signal/pcm.dart';
import 'collection_storage.dart';
import 'event_pipeline.dart';

/// Result of evaluating one clip of a collection.
class ClipEvaluation {
  const ClipEvaluation({
    required this.clip,
    required this.records,
    this.plateau,
  });

  final ClipEntry clip;

  /// Records of the complete pipeline; `offsetS` counts from the start of
  /// the clip.
  final List<PassRecord> records;

  /// Effective microphone spacing and offset read from the clip, null
  /// without a valid track or without plateaus.
  final PlateauEstimate? plateau;

  /// First record with a speed (class A or B).
  PassRecord? get vehicle {
    for (final r in records) {
      if (r.klasse != QualityClass.c) return r;
    }
    return null;
  }

  bool get vehicleFound => vehicle != null;
}

/// A labelled collection run through the evaluation.
class CollectionEvaluation {
  const CollectionEvaluation({required this.manifest, required this.clips});

  final CollectionManifest manifest;
  final List<ClipEvaluation> clips;

  Iterable<ClipEvaluation> _labelled(ClipLabel label) =>
      clips.where((c) => c.clip.label == label);

  /// Clips labelled "auto", and how many of them gave a speed.
  int get vehicleClips => _labelled(ClipLabel.vehicle).length;
  int get vehiclesFound =>
      _labelled(ClipLabel.vehicle).where((c) => c.vehicleFound).length;

  /// Clips labelled "kein_auto", and how many of them gave a speed anyway.
  int get noVehicleClips => _labelled(ClipLabel.noVehicle).length;
  int get falseVehicles =>
      _labelled(ClipLabel.noVehicle).where((c) => c.vehicleFound).length;

  /// Median of the spacing and offset estimates of all clips with a track.
  PlateauEstimate? get plateau => medianPlateauEstimate([
    for (final c in clips)
      if (c.plateau != null) c.plateau!,
  ]);
}

/// Evaluates one clip as the app evaluates an event window: the level
/// maximum sits where the collector found it, the window is the whole clip.
ClipEvaluation evaluateClip(
  StereoBlock signal,
  ClipEntry clip, {
  required NyooomConfig config,
  required AnalysisSetup setup,
}) {
  final event = PassEvent(
    peakTimeS: clip.peakTimeS - clip.startS,
    peakLevelDb: clip.peakLevelDb,
    floorDb: clip.floorDb,
    durationS: clip.eventDurationS,
    windowStartS: 0,
    windowEndS: signal.length / config.sampleRate,
    overlap: clip.overlap,
    truncated: false,
  );
  final tracks = EventPipeline(
    config: config,
    setup: setup,
  ).evaluateTracks(signal, event, windowStartS: 0);

  PlateauEstimate? plateau;
  for (final track in tracks) {
    if (track.analysis.fit?.reason != null) continue;
    plateau = estimateTrackPlateaus(
      track.analysis,
      setup: setup,
      config: config,
    );
    break;
  }
  return ClipEvaluation(
    clip: clip,
    records: [for (final track in tracks) track.record],
    plateau: plateau,
  );
}

/// Evaluates all clips of an exported collection ([directory] holds
/// `collection.json` and the clips) with the given device and site
/// constants.
CollectionEvaluation evaluateCollection(
  Directory directory, {
  required NyooomConfig config,
  required AnalysisSetup setup,
}) {
  final manifestFile = File('${directory.path}/collection.json');
  if (!manifestFile.existsSync()) {
    throw FileSystemException('collection.json fehlt', manifestFile.path);
  }
  final manifest = CollectionManifest.fromJson(
    (jsonDecode(manifestFile.readAsStringSync()) as Map)
        .cast<String, dynamic>(),
  );
  final clips = <ClipEvaluation>[];
  for (final clip in manifest.clips) {
    final wav = decodeWav(
      File('${directory.path}/${clip.file}').readAsBytesSync(),
    );
    if (wav.channels != 2) {
      throw FormatException('${clip.file}: kein Stereo');
    }
    clips.add(
      evaluateClip(
        deinterleavePcm16(wav.samples),
        clip,
        config: config,
        setup: setup,
      ),
    );
  }
  return CollectionEvaluation(manifest: manifest, clips: clips);
}

/// Reads [clip] of collection [collectionId] and evaluates it.
Future<ClipEvaluation> evaluateStoredClip(
  CollectionStorage storage,
  int collectionId,
  ClipEntry clip, {
  required NyooomConfig config,
  required AnalysisSetup setup,
}) async {
  final wav = decodeWav(
    await storage.clipFile(collectionId, clip.file).readAsBytes(),
  );
  if (wav.channels != 2) throw FormatException('${clip.file}: kein Stereo');
  return evaluateClip(
    deinterleavePcm16(wav.samples),
    clip,
    config: config,
    setup: setup,
  );
}

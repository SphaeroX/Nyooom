// Runs a labelled collection (export of the tab "Sammeln": collection.json
// plus clips) through the evaluation and compares the result with the
// labels.
//
//   fvm dart run tool/evaluate_collection.dart <ordner>
//       [--abstand 3.0]      horizontaler Abstand zur Spurmitte in m
//       [--hoehe 1.5]        Mikrofonhöhe über der Fahrbahn in m
//       [--b 0.15]           Mikrofonabstand in m
//       [--delta0 0]         Kanalversatz in µs
//       [--temperatur 20]    Lufttemperatur in °C
//       [--b-schaetzen]      b und Δ0 aus den Vorbeifahrten lernen und
//                            damit noch einmal auswerten
import 'dart:io';

import 'package:nyooom/core/collect/collection_manifest.dart';
import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/model/acoustics.dart';
import 'package:nyooom/core/pipeline/analysis_setup.dart';
import 'package:nyooom/data/collection_evaluation.dart';

void main(List<String> args) {
  if (args.isEmpty || args.first.startsWith('--')) {
    stderr.writeln(
      'Aufruf: fvm dart run tool/evaluate_collection.dart <ordner> '
      '[--abstand m] [--hoehe m] [--b m] [--delta0 µs] [--temperatur °C] '
      '[--b-schaetzen]',
    );
    exitCode = 64;
    return;
  }
  double option(String name, double fallback) {
    final i = args.indexOf('--$name');
    return i < 0 || i + 1 >= args.length ? fallback : double.parse(args[i + 1]);
  }

  const config = NyooomConfig();
  final directory = Directory(args.first);
  final distance = slantDistance(
    option('abstand', 3),
    option('hoehe', 1.5) - config.sourceHeightM,
  );
  final c = speedOfSound(option('temperatur', 20));
  AnalysisSetup setup(double micSpacing, double channelOffset) => AnalysisSetup(
    micSpacing: micSpacing,
    channelOffset: channelOffset,
    swapChannels: false,
    speedOfSound: c,
    // One lane for both directions: the collection does not know the site.
    lanes: [LaneGeometry(index: 0, direction: 0, slantDistance: distance)],
    speedLimitKmh: 0,
    startedAtUtcMs: 0,
  );

  var micSpacing = option('b', AnalysisSetup.defaultMicSpacing);
  var channelOffset = option('delta0', 0) * 1e-6;
  var result = evaluateCollection(
    directory,
    config: config,
    setup: setup(micSpacing, channelOffset),
  );
  if (args.contains('--b-schaetzen')) {
    // Two rounds: the first estimate still carries the error of the fit
    // made with the assumed b.
    for (var round = 0; round < 2; round++) {
      final plateau = result.plateau;
      if (plateau == null) break;
      micSpacing = plateau.micSpacing;
      channelOffset = plateau.channelOffset;
      result = evaluateCollection(
        directory,
        config: config,
        setup: setup(micSpacing, channelOffset),
      );
    }
  }

  stdout.writeln(
    'Schrägabstand ${distance.toStringAsFixed(2)} m, '
    'b ${(micSpacing * 100).toStringAsFixed(1)} cm, '
    'Δ0 ${(channelOffset * 1e6).toStringAsFixed(1)} µs, '
    'c ${c.toStringAsFixed(1)} m/s',
  );
  stdout.writeln(
    'datei;label;pegel_db;klasse;richtung;v_kmh;sigma_kmh;v_doppler_kmh;'
    'kappa;t0_s;rest_us;grund;b_cm;delta0_us',
  );
  String f(double? v, [int digits = 1]) =>
      v == null ? '' : v.toStringAsFixed(digits);
  for (final clip in result.clips) {
    final record = clip.vehicle ?? clip.records.firstOrNull;
    stdout.writeln(
      [
        clip.clip.file,
        clip.clip.label.key,
        f(clip.clip.levelAboveFloorDb),
        record?.klasse.label ?? '',
        record == null || record.richtung == 0 ? '' : '${record.richtung}',
        f(record?.v),
        f(record?.sigmaV),
        f(record?.vDoppler),
        f(record?.kappa, 2),
        f(record?.offsetS, 2),
        f(record?.restLaufzeitUs),
        record?.reason?.code ?? '',
        f(clip.plateau == null ? null : clip.plateau!.micSpacing * 100),
        f(clip.plateau == null ? null : clip.plateau!.channelOffset * 1e6),
      ].join(';'),
    );
  }

  final speeds = [
    for (final clip in result.clips)
      if (clip.clip.label == ClipLabel.vehicle && clip.vehicle?.v != null)
        clip.vehicle!.v!,
  ]..sort();
  final doppler = result.clips
      .where(
        (c) => c.clip.label == ClipLabel.vehicle && c.vehicle?.vDoppler != null,
      )
      .length;
  stdout.writeln('');
  stdout.writeln(
    'Autos mit Geschwindigkeit: ${result.vehiclesFound} von '
    '${result.vehicleClips}',
  );
  stdout.writeln('davon mit Doppler-Wert: $doppler');
  stdout.writeln(
    'Kein Auto, trotzdem Geschwindigkeit: ${result.falseVehicles} von '
    '${result.noVehicleClips}',
  );
  if (speeds.isNotEmpty) {
    stdout.writeln(
      'Geschwindigkeit: ${f(speeds.first)} bis ${f(speeds.last)} km/h, '
      'Median ${f(speeds[speeds.length ~/ 2])} km/h',
    );
  }
  final plateau = result.plateau;
  if (plateau != null) {
    stdout.writeln(
      'Aus den Vorbeifahrten: b = '
      '${(plateau.micSpacing * 100).toStringAsFixed(1)} cm, '
      'Δ0 = ${(plateau.channelOffset * 1e6).toStringAsFixed(1)} µs',
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/model/acoustics.dart';
import '../../core/reference/gpx.dart';
import '../../core/reference/reference_csv.dart';
import '../../core/reference/reference_logger.dart';
import '../../core/reference/reference_track.dart';
import '../../data/database.dart';
import '../providers.dart';
import '../series/series_screens.dart' show formatDate, formatDuration;
import '../sites/site_screens.dart' show confirmDelete;

final referenceTracksProvider = FutureProvider<List<ReferenceTrackRow>>(
  (ref) => ref.watch(repositoryProvider).referenceTracks(),
);

final referenceTrackProvider = FutureProvider.family<ReferenceTrack?, int>(
  (ref, id) => ref.watch(repositoryProvider).referenceTrack(id),
);

/// GPS fixes with the highest accuracy, 1 Hz (replaceable in tests).
final positionStreamProvider = Provider<Stream<PositionSample> Function()>(
  (ref) => () async* {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Standort-Berechtigung fehlt.');
    }
    yield* Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 1),
      ),
    ).map(
      (p) => PositionSample(
        timeUtcMs: p.timestamp.toUtc().millisecondsSinceEpoch,
        lat: p.latitude,
        lon: p.longitude,
        speed: p.speed >= 0 ? p.speed : null,
        accuracyM: p.accuracy,
        speedAccuracy: p.speedAccuracy,
      ),
    );
  },
);

/// "Referenz" tab: GPS reference drives (technik.pdf 8.1).
class ReferenceListScreen extends ConsumerWidget {
  const ReferenceListScreen({super.key});

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) return;
    final file = picked.single;
    final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
    final name = file.name;
    ReferenceTrack track;
    var errors = 0;
    if (name.toLowerCase().endsWith('.gpx') || text.contains('<gpx')) {
      track = parseGpx(text, fallbackName: name);
    } else {
      final r = parseReferenceCsv(text, name: name);
      track = r.track;
      errors = r.errors.length;
    }
    if (track.points.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Keine Messpunkte gefunden.')),
        );
      }
      return;
    }
    await ref.read(repositoryProvider).addReferenceTrack(track);
    ref.invalidate(referenceTracksProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${track.points.length} Punkte importiert'
            '${errors > 0 ? ', $errors fehlerhafte Zeilen übersprungen' : ''}.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(referenceTracksProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referenzfahrten'),
        actions: [
          IconButton(
            tooltip: 'GPX/CSV importieren',
            onPressed: () => _import(context, ref),
            icon: const Icon(Icons.file_open_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const LoggerScreen())),
        icon: const Icon(Icons.gps_fixed),
        label: const Text('GPS-Logger'),
      ),
      body: tracks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (list) => list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Noch keine Referenzfahrt. Im Fahrzeug den GPS-Logger '
                    'starten (zweites Smartphone) oder eine GPX/CSV-Datei '
                    'eines GPS-Loggers importieren.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                children: [
                  for (final t in list)
                    ListTile(
                      leading: Icon(
                        t.source == 'logger'
                            ? Icons.gps_fixed
                            : Icons.file_present_outlined,
                      ),
                      title: Text(t.name),
                      subtitle: Text(
                        '${t.source.toUpperCase()} · '
                        '${formatDate(t.createdAtUtcMs)}',
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ReferenceTrackScreen(trackId: t.id),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// Logger mode in the car.
class LoggerScreen extends ConsumerStatefulWidget {
  const LoggerScreen({super.key});

  @override
  ConsumerState<LoggerScreen> createState() => _LoggerScreenState();
}

class _LoggerScreenState extends ConsumerState<LoggerScreen> {
  ReferenceLogger? _logger;
  Timer? _tick;
  final _name = TextEditingController(text: 'Referenzfahrt');
  String? _error;
  int? _clockOffsetMs;

  @override
  void dispose() {
    _tick?.cancel();
    _name.dispose();
    super.dispose();
  }

  void _start() {
    final stream = ref
        .read(positionStreamProvider)()
        .handleError((Object e) => setState(() => _error = '$e'))
        .map((p) {
          _clockOffsetMs =
              DateTime.now().toUtc().millisecondsSinceEpoch - p.timeUtcMs;
          return p;
        });
    final logger = ReferenceLogger(stream)..start();
    _tick = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => setState(() {}),
    );
    setState(() {
      _logger = logger;
      _error = null;
    });
  }

  Future<void> _stop() async {
    final logger = _logger!;
    _tick?.cancel();
    final track = await logger.stop(name: _name.text.trim());
    if (track.points.isNotEmpty) {
      await ref.read(repositoryProvider).addReferenceTrack(track);
      ref.invalidate(referenceTracksProvider);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final logger = _logger;
    final last = logger?.last;
    return Scaffold(
      appBar: AppBar(title: const Text('GPS-Logger')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Im Fahrzeug mit Tempomat oder Begrenzer fahren (technik.pdf '
            '8.1). Uhrzeit beider Geräte über Netzwerkzeit synchronisieren; '
            'die Zuordnung zur Messung läuft über die Uhrzeit.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name der Fahrt'),
          ),
          const SizedBox(height: 16),
          if (logger == null)
            FilledButton.icon(
              key: const Key('start-logger'),
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Aufzeichnung starten'),
            )
          else ...[
            Text(
              last?.speed == null
                  ? 'Warte auf GPS …'
                  : '${toKmh(last!.speed!).toStringAsFixed(1)} km/h',
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center,
            ),
            Text('${logger.count} Punkte', textAlign: TextAlign.center),
            if (last?.accuracyM != null)
              Text(
                'Genauigkeit ${last!.accuracyM!.toStringAsFixed(0)} m',
                textAlign: TextAlign.center,
              ),
            if (_clockOffsetMs != null)
              Text(
                'Geräteuhr minus GPS-Zeit: '
                '${(_clockOffsetMs! / 1000).toStringAsFixed(1)} s',
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const Key('stop-logger'),
              onPressed: _stop,
              icon: const Icon(Icons.stop),
              label: const Text('Beenden und speichern'),
            ),
          ],
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

/// Speed over time of one reference drive.
class ReferenceTrackScreen extends ConsumerWidget {
  const ReferenceTrackScreen({super.key, required this.trackId});

  final int trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(referenceTrackProvider(trackId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referenzfahrt'),
        actions: [
          IconButton(
            tooltip: 'Löschen',
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              if (!await confirmDelete(context, 'Referenzfahrt löschen?')) {
                return;
              }
              await ref.read(repositoryProvider).deleteReferenceTrack(trackId);
              ref.invalidate(referenceTracksProvider);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: track.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (t) => t == null
            ? const Center(child: Text('Nicht gefunden.'))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(t.name, style: Theme.of(context).textTheme.titleLarge),
                  Text(
                    '${t.points.length} Punkte · '
                    '${formatDate(t.startUtcMs!)} · Dauer '
                    '${formatDuration((t.endUtcMs! - t.startUtcMs!) / 1000)}'
                    '${t.points.any((p) => p.speedDerived) ? ' · Geschwindigkeit aus Positionen' : ''}',
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: CustomPaint(
                      painter: SpeedTracePainter(
                        t,
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.onSurface,
                      ),
                      size: Size.infinite,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Line chart of the GPS speed in km/h over time.
class SpeedTracePainter extends CustomPainter {
  SpeedTracePainter(this.track, this.color, this.axis);
  final ReferenceTrack track;
  final Color color, axis;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = track.points.where((p) => p.speed != null).toList();
    if (pts.length < 2) return;
    final t0 = pts.first.timeUtcMs, t1 = pts.last.timeUtcMs;
    final vMax = math.max(
      10.0,
      pts.map((p) => toKmh(p.speed!)).reduce(math.max),
    );
    final path = Path();
    for (var i = 0; i < pts.length; i++) {
      final x = (pts[i].timeUtcMs - t0) / math.max(1, t1 - t0) * size.width;
      final y = size.height - toKmh(pts[i].speed!) / vMax * (size.height - 14);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final label = TextPainter(
      text: TextSpan(
        text: '${vMax.round()} km/h',
        style: TextStyle(color: axis, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(SpeedTracePainter old) => old.track != track;
}

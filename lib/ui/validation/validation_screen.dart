import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/pipeline/pass_record.dart';
import '../../core/validation/validation.dart';
import '../../core/validation/validation_csv.dart';
import '../evaluation/pass_widgets.dart';
import '../export/export_buttons.dart';
import '../providers.dart';

/// Everything the validation screen shows for one series.
class ValidationData {
  const ValidationData({
    required this.hasPosition,
    required this.plusXBearingDeg,
    required this.trackCount,
    this.match,
    this.report,
  });

  final bool hasPosition;
  final double? plusXBearingDeg;
  final int trackCount;
  final MatchResult? match;
  final ValidationReport? report;
}

final validationProvider = FutureProvider.family<ValidationData, int>((
  ref,
  seriesId,
) async {
  final repo = ref.watch(repositoryProvider);
  final config = ref.watch(configProvider);
  final series = (await repo.series(seriesId))!;
  final site = series.site.spec;
  final tracks = await repo.referenceTracks();
  if (site.latitude == null || site.longitude == null) {
    return ValidationData(
      hasPosition: false,
      plusXBearingDeg: site.plusXBearingDeg,
      trackCount: tracks.length,
    );
  }
  final passages = <ReferencePassage>[];
  for (final row in tracks) {
    final track = await repo.referenceTrack(row.id);
    if (track == null) continue;
    passages.addAll(
      closestApproaches(
        track,
        siteLat: site.latitude!,
        siteLon: site.longitude!,
        config: config,
      ),
    );
  }
  final start = series.startedAtUtcMs;
  final end = series.endedAtUtcMs ?? DateTime.now().millisecondsSinceEpoch;
  final inSeries =
      passages.where((p) => p.timeUtcMs >= start && p.timeUtcMs <= end).toList()
        ..sort((a, b) => a.timeUtcMs.compareTo(b.timeUtcMs));
  final match = matchReferences(
    inSeries,
    await repo.passes(seriesId),
    config: config,
  );
  return ValidationData(
    hasPosition: true,
    plusXBearingDeg: site.plusXBearingDeg,
    trackCount: tracks.length,
    match: match,
    report: ValidationReport.from(
      match.matches,
      config: config,
      plusXBearingDeg: site.plusXBearingDeg,
    ),
  );
});

/// Validation against GPS reference drives (technik.pdf 8): traffic light per
/// acceptance criterion, scatter of error over reference speed.
class ValidationScreen extends ConsumerWidget {
  const ValidationScreen({super.key, required this.seriesId});

  final int seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(validationProvider(seriesId));
    return Scaffold(
      appBar: AppBar(title: const Text('Validierung')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (d) => ValidationView(data: d, seriesId: seriesId),
      ),
    );
  }
}

class ValidationView extends ConsumerWidget {
  const ValidationView({super.key, required this.data, required this.seriesId});

  final ValidationData data;
  final int seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    if (!data.hasPosition) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Für die Zuordnung braucht der Standort eine Position (Breite/Länge). '
          'Bitte im Standort eintragen, am besten mit "Aktuelle Position '
          'übernehmen" am Messort.',
        ),
      );
    }
    final report = data.report!;
    final match = data.match!;
    final config = ref.watch(configProvider);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          '${match.matches.length} Referenzvorbeifahrten zugeordnet, '
          '${match.unmatchedReferences.length} ohne Messung, '
          '${match.unmatchedRecords.length} Messungen ohne Referenz '
          '(${data.trackCount} Referenzfahrten insgesamt).',
        ),
        if (data.plusXBearingDeg == null)
          const Text(
            'Ohne Kompassrichtung am Standort lässt sich die Fahrtrichtung '
            'nicht prüfen.',
          ),
        const SizedBox(height: 8),
        Text('Abnahmekriterien', style: theme.textTheme.titleMedium),
        for (final a in report.acceptance(config))
          ListTile(
            dense: true,
            leading: Icon(
              Icons.circle,
              color: a.passed == null
                  ? theme.colorScheme.outline
                  : a.passed!
                  ? Colors.green
                  : theme.colorScheme.error,
            ),
            title: Text(a.criterion.label),
            subtitle: Text(a.value),
          ),
        const SizedBox(height: 8),
        Text(
          'Fehler über Referenzgeschwindigkeit',
          style: theme.textTheme.titleSmall,
        ),
        SizedBox(
          height: 200,
          child: CustomPaint(
            painter: _ScatterPainter(
              match.matches,
              theme.colorScheme.onSurface,
              Colors.green.shade600,
              Colors.blue.shade600,
            ),
            size: Size.infinite,
          ),
        ),
        const Text('grün = Klasse A, blau = Klasse B; Linie = 0 km/h'),
        const SizedBox(height: 8),
        Text('Je Stufe', style: theme.textTheme.titleSmall),
        for (final e in report.byStep.entries)
          Text(
            '${e.key} km/h: n = ${e.value.count}, Mittel '
            '${e.value.meanError?.toStringAsFixed(2) ?? '–'}, σ '
            '${e.value.sd?.toStringAsFixed(2) ?? '–'} km/h',
          ),
        for (final e in report.byClass.entries)
          Text(
            'Klasse ${e.key.label}: n = ${e.value.count}, Mittel '
            '${e.value.meanError?.toStringAsFixed(2) ?? '–'}, σ '
            '${e.value.sd?.toStringAsFixed(2) ?? '–'} km/h',
          ),
        for (final e in report.byDirection.entries)
          Text(
            'Richtung ${arrow(e.key)}: n = ${e.value.count}, Mittel '
            '${e.value.meanError?.toStringAsFixed(2) ?? '–'} km/h',
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: match.matches.isEmpty
              ? null
              : () async {
                  final dir = await getTemporaryDirectory();
                  final file = File(
                    '${dir.path}/nyooom_validierung_$seriesId.csv',
                  );
                  await file.writeAsString(
                    validationToCsv(
                      match.matches,
                      plusXBearingDeg: data.plusXBearingDeg,
                    ),
                  );
                  await ref.read(fileSharerProvider)([
                    file,
                  ], 'Nyooom Validierung $seriesId');
                },
          icon: const Icon(Icons.ios_share),
          label: const Text('Validierung als CSV teilen'),
        ),
      ],
    );
  }
}

class _ScatterPainter extends CustomPainter {
  _ScatterPainter(this.matches, this.axis, this.colorA, this.colorB);
  final List<ValidationMatch> matches;
  final Color axis, colorA, colorB;

  @override
  void paint(Canvas canvas, Size size) {
    final pts = matches.where((m) => m.errorKmh != null).toList();
    if (pts.isEmpty) return;
    final xs = pts.map((m) => m.reference.referenceKmh);
    final xMin = xs.reduce(math.min) - 5, xMax = xs.reduce(math.max) + 5;
    final eMax = math.max(
      5.0,
      pts.map((m) => m.errorKmh!.abs()).reduce(math.max),
    );
    Offset at(double x, double e) => Offset(
      (x - xMin) / (xMax - xMin) * size.width,
      size.height / 2 - e / eMax * (size.height / 2 - 4),
    );
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()..color = axis,
    );
    for (final m in pts) {
      canvas.drawCircle(
        at(m.reference.referenceKmh, m.errorKmh!),
        4,
        Paint()..color = m.record.klasse == QualityClass.a ? colorA : colorB,
      );
    }
    final label = TextPainter(
      text: TextSpan(
        text:
            '±${eMax.toStringAsFixed(0)} km/h, '
            '${xMin.round()}–${xMax.round()} km/h',
        style: TextStyle(color: axis, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(_ScatterPainter old) => old.matches != matches;
}

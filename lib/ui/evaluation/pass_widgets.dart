import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/model/passby_model.dart';
import '../../core/pipeline/pass_record.dart';
import '../../data/repository.dart';
import '../inspection/inspection_screen.dart';
import '../providers.dart';
import '../export/export_buttons.dart';
import '../stats/statistics_screen.dart';
import '../validation/validation_screen.dart';
import 'evaluation_controller.dart';
import 'self_calibration_card.dart';

String formatTime(int utcMs) {
  final t = DateTime.fromMillisecondsSinceEpoch(utcMs).toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}

String arrow(int direction) => direction > 0
    ? '→'
    : direction < 0
    ? '←'
    : '·';

Color classColor(BuildContext context, QualityClass c) => switch (c) {
  QualityClass.a => Colors.green.shade600,
  QualityClass.b => Colors.blue.shade600,
  QualityClass.c => Theme.of(context).colorScheme.outline,
};

/// Coloured badge with the quality class.
class ClassBadge extends StatelessWidget {
  const ClassBadge(this.klasse, {super.key});
  final QualityClass klasse;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 16,
    backgroundColor: classColor(context, klasse),
    child: Text(
      klasse.label,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
  );
}

/// One row of a result list: time, direction, v ± σ, class, reason.
class PassTile extends StatelessWidget {
  const PassTile({super.key, required this.record, this.onTap});

  final PassRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final speed = r.v == null
        ? (r.vLaufzeit == null ? '–' : '(${r.vLaufzeit!.toStringAsFixed(1)})')
        : '${r.v!.toStringAsFixed(1)} ± ${r.sigmaV!.toStringAsFixed(1)}';
    return ListTile(
      leading: ClassBadge(r.klasse),
      title: Text('${arrow(r.richtung)}  $speed km/h'),
      subtitle: Text(
        '${formatTime(r.zeitUtcMs)}'
        '${r.grund == null ? '' : ' · ${r.grund}'}',
      ),
      onTap: onTap,
    );
  }
}

/// Count of A/B/C records.
class ClassCounts extends StatelessWidget {
  const ClassCounts(this.records, {super.key});
  final List<PassRecord> records;

  @override
  Widget build(BuildContext context) {
    int n(QualityClass c) => records.where((r) => r.klasse == c).length;
    return Wrap(
      spacing: 8,
      children: [
        for (final c in QualityClass.values)
          Chip(avatar: ClassBadge(c), label: Text('${n(c)}')),
      ],
    );
  }
}

/// "Auswertung" section of the series detail screen.
class EvaluationSection extends ConsumerWidget {
  const EvaluationSection({super.key, required this.series});

  final StoredSeries series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eval = ref.watch(evaluationProvider(series.id));
    final passes = ref.watch(passesProvider(series.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text('Auswertung', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FilledButton.icon(
          key: const Key('evaluate-series'),
          onPressed: eval.running
              ? null
              : () => ref.read(evaluationProvider(series.id).notifier).run(),
          icon: const Icon(Icons.speed),
          label: Text(eval.running ? 'Wertet aus …' : 'Messreihe auswerten'),
        ),
        if (eval.running) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: eval.fraction),
          Text(eval.phase),
        ],
        if (eval.error != null)
          Text(
            eval.error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => StatisticsScreen(
                title: 'Statistik der Messreihe',
                records: passesProvider(series.id),
                limitKmh: series.site.spec.speedLimitKmh,
              ),
            ),
          ),
          icon: const Icon(Icons.bar_chart),
          label: const Text('Statistik'),
        ),
        const SizedBox(height: 8),
        SelfCalibrationCard(series: series),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ValidationScreen(seriesId: series.id),
            ),
          ),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Validierung mit Referenzfahrten'),
        ),
        const SizedBox(height: 8),
        ExportButtons(seriesId: series.id),
        passes.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('Fehler: $e'),
          data: (list) => PassList(
            records: list,
            onTap: (r) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    PassDetailScreen(seriesId: series.id, record: r),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Result list with class counts.
class PassList extends StatelessWidget {
  const PassList({super.key, required this.records, this.onTap});

  final List<PassRecord> records;
  final void Function(PassRecord)? onTap;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Noch keine Vorbeifahrten ausgewertet.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        ClassCounts(records),
        for (final r in records)
          PassTile(record: r, onTap: onTap == null ? null : () => onTap!(r)),
      ],
    );
  }
}

/// All fields of one record (technik.pdf 9.1) and the correlogram with the
/// fitted model curve.
class PassDetailScreen extends ConsumerWidget {
  const PassDetailScreen({
    super.key,
    required this.seriesId,
    required this.record,
  });

  final int seriesId;
  final PassRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = record;
    String f(double? v, [int digits = 1]) =>
        v == null ? '–' : v.toStringAsFixed(digits);
    final rows = <(String, String)>[
      ('Zeit (t0)', formatTime(r.zeitUtcMs)),
      ('Richtung', '${arrow(r.richtung)} (${r.richtung})'),
      ('Klasse', r.klasse.label),
      ('Grund', r.grund ?? '–'),
      ('v', '${f(r.v)} km/h'),
      ('σ_v', '${f(r.sigmaV)} km/h'),
      ('v Laufzeit', '${f(r.vLaufzeit)} ± ${f(r.sigmaLaufzeit)} km/h'),
      ('v Doppler', '${f(r.vDoppler)} ± ${f(r.sigmaDoppler)} km/h'),
      ('κ', '${f(r.kappa, 3)} 1/s'),
      ('d_est', '${f(r.dEst, 2)} m'),
      ('Abstand verwendet', '${f(r.distanceUsedM, 2)} m'),
      ('Tonspuren', '${r.nToene}'),
      ('Reststreuung', '${f(r.restLaufzeitUs)} µs'),
      ('Pegel über Grund', '${f(r.pegel)} dB'),
      ('Dauer', '${f(r.dauer, 2)} s'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Vorbeifahrt')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Table(
            columnWidths: const {0: IntrinsicColumnWidth()},
            children: [
              for (final (k, v) in rows)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16, bottom: 4),
                      child: Text(k),
                    ),
                    Text(v),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (r.kappa != null)
            OutlinedButton.icon(
              onPressed: () async {
                final setup = await ref
                    .read(repositoryProvider)
                    .analysisSetup(seriesId);
                if (setup == null || !context.mounted) return;
                final d =
                    r.distanceUsedM ??
                    (setup.laneFor(r.richtung) ?? setup.lanes.first)
                        .slantDistance;
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InspectionScreen(
                      seriesId: seriesId,
                      initialStartS: r.offsetS - 4,
                      fixedModel: PassByModel(
                        speed: r.kappa! * d,
                        distance: d,
                        t0: r.offsetS,
                        micSpacing: setup.micSpacing,
                        speedOfSound: setup.speedOfSound,
                        channelOffset: setup.channelOffset,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.insights),
              label: const Text('Korrelogramm mit Modellkurve'),
            ),
        ],
      ),
    );
  }
}

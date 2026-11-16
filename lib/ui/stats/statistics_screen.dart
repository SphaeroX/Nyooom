import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/pipeline/pass_record.dart';
import '../../core/stats/statistics.dart';
import '../evaluation/pass_widgets.dart';

/// Statistics of a series or site: key figures separated by class A, B and
/// A+B, by direction, lane and hour, class-C share with reasons, histogram.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({
    super.key,
    required this.title,
    required this.records,
    required this.limitKmh,
  });

  final String title;
  final FutureProvider<List<PassRecord>> records;
  final double limitKmh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(records);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (list) => StatisticsView(records: list, limitKmh: limitKmh),
      ),
    );
  }
}

class StatisticsView extends StatelessWidget {
  const StatisticsView({
    super.key,
    required this.records,
    required this.limitKmh,
  });

  final List<PassRecord> records;
  final double limitKmh;

  @override
  Widget build(BuildContext context) {
    final report = StatisticsReport.from(records, limitKmh: limitKmh);
    final theme = Theme.of(context);
    if (report.total == 0) {
      return const Center(child: Text('Keine ausgewerteten Vorbeifahrten.'));
    }
    final c = report.classC;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          '${report.total} Ereignisse, Tempolimit ${limitKmh.round()} km/h',
          style: theme.textTheme.titleMedium,
        ),
        ClassCounts(records),
        const SizedBox(height: 8),
        Text('Gesamt', style: theme.textTheme.titleSmall),
        _ClassTable(report.overall),
        const SizedBox(height: 8),
        Text(
          'Klasse C (verworfen): ${c.count} '
          '(${((c.share ?? 0) * 100).toStringAsFixed(0)} %)',
          style: theme.textTheme.titleSmall,
        ),
        for (final e in c.reasons.entries) Text('· ${e.key.text}: ${e.value}'),
        const SizedBox(height: 12),
        Text('Geschwindigkeitsverteilung', style: theme.textTheme.titleSmall),
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _HistogramPainter(
              speedHistogram(records, binWidthKmh: 2),
              limitKmh,
              Colors.green.shade600,
              Colors.blue.shade600,
              theme.colorScheme.onSurface,
            ),
            size: Size.infinite,
          ),
        ),
        const Text('grün = Klasse A, blau = Klasse B, Linie = Tempolimit'),
        for (final e in report.byDirection.entries) ...[
          const SizedBox(height: 12),
          Text('Richtung ${arrow(e.key)}', style: theme.textTheme.titleSmall),
          _ClassTable(e.value),
        ],
        if (report.byHour.length > 1)
          for (final e in report.byHour.entries) ...[
            const SizedBox(height: 12),
            Text(
              '${e.key}:00 bis ${e.key + 1}:00 Uhr',
              style: theme.textTheme.titleSmall,
            ),
            _ClassTable(e.value),
          ],
        const SizedBox(height: 12),
        Text(
          'V85 korr.: V85 einer Normalverteilung mit um die Messunsicherheit '
          'bereinigter Streuung (technik.pdf 8.3).',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ClassTable extends StatelessWidget {
  const _ClassTable(this.stats);
  final ClassStats stats;

  @override
  Widget build(BuildContext context) {
    String f(double? v) => v == null ? '–' : v.toStringAsFixed(1);
    String pct(double? v) =>
        v == null ? '–' : '${(v * 100).toStringAsFixed(0)} %';
    TableRow row(String label, SpeedStats s) => TableRow(
      children: [
        Text(label),
        Text('${s.count}'),
        Text(f(s.median)),
        Text(f(s.v85)),
        Text(f(s.v85Corrected)),
        Text(f(s.mean)),
        Text(f(s.sd)),
        Text(pct(s.overLimitShare)),
      ],
    );
    final header = [
      'Kl.',
      'n',
      'Median',
      'V85',
      'V85 korr.',
      'Mittel',
      'σ',
      '> Limit',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: [
          TableRow(
            children: [
              for (final h in header)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    h,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          row('A', stats.a),
          row('B', stats.b),
          row('A+B', stats.ab),
        ],
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  _HistogramPainter(this.bins, this.limit, this.colorA, this.colorB, this.axis);
  final List<HistogramBin> bins;
  final double limit;
  final Color colorA, colorB, axis;

  @override
  void paint(Canvas canvas, Size size) {
    if (bins.isEmpty) return;
    final maxCount = bins.map((b) => b.a + b.b).reduce(math.max);
    final width = size.width / bins.length;
    final from = bins.first.fromKmh;
    final binWidth = bins.length > 1 ? bins[1].fromKmh - from : 2.0;
    for (var i = 0; i < bins.length; i++) {
      final b = bins[i];
      final hb = b.b / maxCount * (size.height - 16);
      final ha = b.a / maxCount * (size.height - 16);
      final x = i * width;
      canvas.drawRect(
        Rect.fromLTWH(x + 1, size.height - 16 - hb, width - 2, hb),
        Paint()..color = colorB,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + 1, size.height - 16 - hb - ha, width - 2, ha),
        Paint()..color = colorA,
      );
      if (i % 5 == 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: b.fromKmh.round().toString(),
            style: TextStyle(color: axis, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x, size.height - 14));
      }
    }
    final lx = (limit - from) / binWidth * width;
    if (lx >= 0 && lx <= size.width) {
      canvas.drawLine(
        Offset(lx, 0),
        Offset(lx, size.height - 16),
        Paint()
          ..color = axis
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(_HistogramPainter old) => old.bins != bins;
}

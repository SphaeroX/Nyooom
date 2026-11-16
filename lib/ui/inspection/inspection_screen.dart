import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../audio/wav.dart';
import '../../core/inspection/inspection.dart';
import '../../core/model/passby_model.dart';
import '../providers.dart';
import '../common/rgba_image_view.dart';
import '../sites/site_form.dart' show parseDecimal;

/// Arguments of [inspectionProvider].
typedef InspectionRequest = ({int seriesId, double startS, double durationS});

/// Recording length of a series in s (from the WAV header), null without WAV.
final seriesWavDurationProvider = FutureProvider.family<double?, int>((
  ref,
  id,
) async {
  final storage = await ref.watch(seriesStorageProvider.future);
  final file = storage.wavFile(id);
  if (!await file.exists()) return null;
  return (await readWavInfo(file)).durationS;
});

/// Loads an excerpt and computes level, correlogram and spectrogram in a
/// background isolate.
final inspectionProvider =
    FutureProvider.family<InspectionData, InspectionRequest>((ref, r) async {
      final storage = await ref.watch(seriesStorageProvider.future);
      final setup = (await ref
          .watch(repositoryProvider)
          .analysisSetup(r.seriesId))!;
      final config = ref.watch(configProvider);
      final path = storage.wavFile(r.seriesId).path;
      return Isolate.run(() async {
        final file = await readWavStereoRange(
          File(path),
          startS: r.startS,
          durationS: r.durationS,
        );
        final signal = setup.swapChannels ? file.swapped : file;
        return computeInspection(
          signal,
          startS: r.startS,
          config: config,
          micSpacing: setup.micSpacing,
          speedOfSound: setup.speedOfSound,
        );
      });
    });

/// Visual inspection of a recording (technik.pdf 10, step 2): level,
/// correlogram (S-shaped TDOA track) and spectrogram (Doppler of tones).
class InspectionScreen extends ConsumerStatefulWidget {
  const InspectionScreen({
    super.key,
    required this.seriesId,
    this.initialStartS = 0,
    this.fixedModel,
  });

  final int seriesId;

  /// Start of the first excerpt in s.
  final double initialStartS;

  /// Fitted model of a pass (absolute times), drawn over the correlogram.
  final PassByModel? fixedModel;

  @override
  ConsumerState<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends ConsumerState<InspectionScreen> {
  late double _startS = widget.initialStartS;
  double _windowS = 8;
  bool _showModel = false;
  final _kappa = TextEditingController(text: '2');
  final _t0 = TextEditingController(text: '4');

  @override
  void dispose() {
    _kappa.dispose();
    _t0.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duration = ref.watch(seriesWavDurationProvider(widget.seriesId));
    return Scaffold(
      appBar: AppBar(title: const Text('Sichtprüfung')),
      body: duration.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (total) => total == null
            ? const Center(child: Text('Keine Rohaufnahme gespeichert.'))
            : _content(total),
      ),
    );
  }

  Widget _content(double total) {
    final window = math.min(_windowS, total);
    final maxStart = math.max(0.0, total - window);
    final start = _startS.clamp(0.0, maxStart);
    final request = (
      seriesId: widget.seriesId,
      startS: start,
      durationS: window,
    );
    final data = ref.watch(inspectionProvider(request));
    final setup = ref.watch(_setupProvider(widget.seriesId)).value;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'Ausschnitt ${start.toStringAsFixed(1)} bis '
          '${(start + window).toStringAsFixed(1)} s von '
          '${total.toStringAsFixed(1)} s',
        ),
        if (maxStart > 0)
          Slider(
            value: start,
            max: maxStart,
            onChanged: (v) => setState(() => _startS = v),
          ),
        SegmentedButton<double>(
          segments: const [
            ButtonSegment(value: 4, label: Text('4 s')),
            ButtonSegment(value: 8, label: Text('8 s')),
            ButtonSegment(value: 16, label: Text('16 s')),
          ],
          selected: {_windowS},
          onSelectionChanged: (s) => setState(() => _windowS = s.first),
        ),
        const SizedBox(height: 8),
        data.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Fehler: $e'),
          data: (d) => _plots(d, setup),
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Modellkurve Δ(t) einblenden'),
          value: _showModel,
          onChanged: (v) => setState(() => _showModel = v),
        ),
        if (_showModel)
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _kappa,
                  decoration: const InputDecoration(
                    labelText: 'κ = v/d (1/s, Vorzeichen = Richtung)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _t0,
                  decoration: const InputDecoration(
                    labelText: 't0 im Ausschnitt (s)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _plots(InspectionData d, _Setup? setup) {
    final theme = Theme.of(context);
    PassByModel? model = widget.fixedModel;
    var modelOffset = model == null ? 0.0 : d.startS;
    final kappa = parseDecimal(_kappa.text);
    final t0 = parseDecimal(_t0.text);
    if (_showModel && setup != null && kappa != null && t0 != null) {
      // κ fixes the shape; the distance only enters through r/c.
      model = PassByModel(
        speed: kappa * setup.distance,
        distance: setup.distance,
        t0: t0,
        micSpacing: setup.micSpacing,
        speedOfSound: setup.speedOfSound,
        channelOffset: setup.channelOffset,
      );
      modelOffset = 0;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pegel (dB)', style: theme.textTheme.labelLarge),
        SizedBox(
          height: 80,
          width: double.infinity,
          child: CustomPaint(
            painter: _LinePainter(
              d.levelTimes,
              d.levelDb,
              d.durationS,
              theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Korrelogramm: Verzögerung ±'
          '${(d.correlogram.maxLag * 1e6).round()} µs über Zeit',
          style: theme.textTheme.labelLarge,
        ),
        RgbaImageView(
          image: d.correlogramImage,
          overlay: model == null
              ? null
              : _ModelPainter(
                  model,
                  d.correlogram.times,
                  d.correlogram.maxLag,
                  modelOffset,
                ),
        ),
        const SizedBox(height: 8),
        Text(
          'Spektrogramm: ${d.spectrogram.lowHz.round()} bis '
          '${d.spectrogram.highHz.round()} Hz über Zeit',
          style: theme.textTheme.labelLarge,
        ),
        RgbaImageView(image: d.spectrogramImage, height: 220),
      ],
    );
  }
}

class _Setup {
  const _Setup(
    this.micSpacing,
    this.speedOfSound,
    this.channelOffset,
    this.distance,
  );
  final double micSpacing, speedOfSound, channelOffset, distance;
}

final _setupProvider = FutureProvider.family<_Setup?, int>((ref, id) async {
  final s = await ref.watch(repositoryProvider).analysisSetup(id);
  if (s == null) return null;
  return _Setup(
    s.micSpacing,
    s.speedOfSound,
    s.channelOffset,
    s.lanes.isEmpty ? 5 : s.lanes.first.slantDistance,
  );
});

class _LinePainter extends CustomPainter {
  _LinePainter(this.x, this.y, this.xMax, this.color);
  final List<double> x, y;
  final double xMax;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (y.isEmpty) return;
    final lo = y.reduce(math.min), hi = y.reduce(math.max);
    final span = hi - lo == 0 ? 1 : hi - lo;
    final path = Path();
    for (var i = 0; i < x.length; i++) {
      final p = Offset(
        x[i] / xMax * size.width,
        size.height - (y[i] - lo) / span * size.height,
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.y != y || old.color != color;
}

class _ModelPainter extends CustomPainter {
  _ModelPainter(this.model, this.times, this.maxLag, this.timeOffset);
  final PassByModel model;
  final List<double> times;
  final double maxLag;

  /// Added to the excerpt times before evaluating the model.
  final double timeOffset;

  @override
  void paint(Canvas canvas, Size size) {
    if (times.isEmpty) return;
    final path = Path();
    for (var i = 0; i < times.length; i++) {
      final lag = model.tdoa(times[i] + timeOffset);
      final p = Offset(
        (i + 0.5) / times.length * size.width,
        size.height * (0.5 - lag / (2 * maxLag)),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_ModelPainter old) => true;
}

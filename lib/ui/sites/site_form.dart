import 'package:material_ui/material_ui.dart';

import '../../core/site/site.dart';

/// Parses user input with comma or point as decimal separator.
double? parseDecimal(String text) =>
    double.tryParse(text.trim().replaceAll(',', '.'));

/// Form for a measuring site (technik.pdf 4.1, 7.2).
class SiteForm extends StatefulWidget {
  const SiteForm({
    super.key,
    this.initial,
    required this.onSubmit,
    this.header,
    this.onLocate,
  });

  final SiteSpec? initial;

  /// Returns the current GPS position (lat, lon) for the position fields.
  final Future<(double, double)?> Function()? onLocate;

  /// Optional widget above the form (e.g. a statistics button).
  final Widget? header;
  final ValueChanged<SiteSpec> onSubmit;

  @override
  State<SiteForm> createState() => _SiteFormState();
}

class _LaneControllers {
  _LaneControllers(double distance, this.direction)
    : distance = TextEditingController(text: distance.toString());
  final TextEditingController distance;
  int direction;
}

class _SiteFormState extends State<SiteForm> {
  late final TextEditingController _name;
  late final TextEditingController _micHeight;
  late final TextEditingController _speedLimit;
  late final List<_LaneControllers> _lanes;
  late final TextEditingController _lat, _lon, _bearing;
  bool _triedSave = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _name = TextEditingController(text: s?.name ?? '');
    _micHeight = TextEditingController(text: '${s?.micHeight ?? 1.2}');
    _speedLimit = TextEditingController(text: '${s?.speedLimitKmh ?? 50.0}');
    String opt(double? v) => v == null ? '' : '$v';
    _lat = TextEditingController(text: opt(s?.latitude));
    _lon = TextEditingController(text: opt(s?.longitude));
    _bearing = TextEditingController(text: opt(s?.plusXBearingDeg));
    _lanes = [
      for (final l
          in s?.lanes ?? const [LaneSpec(horizontalDistance: 4, direction: 1)])
        _LaneControllers(l.horizontalDistance, l.direction),
    ];
  }

  @override
  void dispose() {
    _name.dispose();
    _micHeight.dispose();
    _speedLimit.dispose();
    _lat.dispose();
    _lon.dispose();
    _bearing.dispose();
    for (final l in _lanes) {
      l.distance.dispose();
    }
    super.dispose();
  }

  SiteSpec get _spec => SiteSpec(
    name: _name.text,
    lanes: [
      for (final l in _lanes)
        LaneSpec(
          horizontalDistance: parseDecimal(l.distance.text) ?? double.nan,
          direction: l.direction,
        ),
    ],
    micHeight: parseDecimal(_micHeight.text) ?? double.nan,
    speedLimitKmh: parseDecimal(_speedLimit.text) ?? double.nan,
    latitude: _optional(_lat.text),
    longitude: _optional(_lon.text),
    plusXBearingDeg: _optional(_bearing.text),
  );

  /// Empty = not given; unparsable = NaN (reported by the validation).
  static double? _optional(String text) =>
      text.trim().isEmpty ? null : (parseDecimal(text) ?? double.nan);

  void _save() {
    final spec = _spec;
    setState(() => _triedSave = true);
    if (validateSite(spec).any((i) => i.isError)) return;
    widget.onSubmit(spec);
  }

  @override
  Widget build(BuildContext context) {
    final issues = validateSite(_spec);
    final visible = issues.where((i) => !i.isError || _triedSave).toList();
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.header != null) ...[
            widget.header!,
            const SizedBox(height: 12),
          ],
          TextField(
            key: const Key('site-name'),
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name des Standorts'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('mic-height'),
                  controller: _micHeight,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Mikrofonhöhe (m)',
                    helperText: 'empfohlen 1,0 bis 1,5 m',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  key: const Key('speed-limit'),
                  controller: _speedLimit,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Tempolimit (km/h)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Fahrspuren', style: Theme.of(context).textTheme.titleMedium),
          const Text(
            'Horizontaler Abstand vom Smartphone zur Spurmitte und die '
            'Fahrtrichtung auf dieser Spur (Blick vom Gerät zur Straße). '
            '⇄ für eine schmale Gasse, die in beide Richtungen auf derselben '
            'Spur befahren wird.',
          ),
          for (var i = 0; i < _lanes.length; i++) _laneRow(i),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('add-lane'),
              onPressed: () => setState(() {
                final used = _lanes.map((l) => l.direction).toSet();
                _lanes.add(
                  _LaneControllers(
                    _lanes.isEmpty ? 4 : 7,
                    used.contains(1) ? -1 : 1,
                  ),
                );
              }),
              icon: const Icon(Icons.add),
              label: const Text('Spur hinzufügen'),
            ),
          ),
          for (final issue in visible)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                issue.lane == null
                    ? issue.message
                    : 'Spur ${issue.lane! + 1}: ${issue.message}',
                style: TextStyle(
                  color: issue.isError ? scheme.error : Colors.orange.shade800,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Position (optional, für GPS-Referenzfahrten)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('site-lat'),
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Breite (°)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('site-lon'),
                  controller: _lon,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Länge (°)'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (widget.onLocate != null)
                IconButton(
                  tooltip: 'Aktuelle Position übernehmen',
                  icon: const Icon(Icons.my_location),
                  onPressed: () async {
                    final p = await widget.onLocate!();
                    if (p == null || !mounted) return;
                    setState(() {
                      _lat.text = p.$1.toStringAsFixed(6);
                      _lon.text = p.$2.toStringAsFixed(6);
                    });
                  },
                ),
            ],
          ),
          TextField(
            key: const Key('site-bearing'),
            controller: _bearing,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Kompassrichtung von → in Grad (0 = Nord, 90 = Ost)',
              helperText: 'Wohin fahren Fahrzeuge der Richtung →?',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('save-site'),
            onPressed: _save,
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Widget _laneRow(int i) {
    final lane = _lanes[i];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: Key('lane-distance-$i'),
              controller: lane.distance,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Spur ${i + 1}: Abstand (m)',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<int>(
            key: Key('lane-direction-$i'),
            segments: const [
              ButtonSegment(
                value: 1,
                label: Text('→'),
                tooltip: 'nach rechts (+x)',
              ),
              ButtonSegment(
                value: -1,
                label: Text('←'),
                tooltip: 'nach links (−x)',
              ),
              ButtonSegment(
                value: LaneSpec.twoWay,
                label: Text('⇄'),
                tooltip: 'beidseitig befahren (z. B. Seitengasse)',
              ),
            ],
            selected: {lane.direction},
            onSelectionChanged: (s) => setState(() => lane.direction = s.first),
          ),
          if (_lanes.length > 1)
            IconButton(
              tooltip: 'Spur entfernen',
              onPressed: () =>
                  setState(() => _lanes.removeAt(i).distance.dispose()),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }
}

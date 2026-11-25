import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/outdoor_temperature.dart';

/// Outdoor temperature from GPS position and weather service.
final outdoorTemperatureServiceProvider = Provider<OutdoorTemperatureService>(
  (ref) => GpsOutdoorTemperatureService(),
);

/// How often a running series fetches the temperature again (Open-Meteo
/// updates its current values every 15 min).
final temperatureRefreshIntervalProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 15),
);

/// Button next to a temperature field: fetches the outdoor temperature at
/// the GPS position and hands it to [onTemperature]; errors go to
/// [onError].
class GpsTemperatureButton extends ConsumerStatefulWidget {
  const GpsTemperatureButton({
    super.key,
    required this.onTemperature,
    required this.onError,
  });

  final void Function(OutdoorTemperature temperature) onTemperature;
  final void Function(String message) onError;

  @override
  ConsumerState<GpsTemperatureButton> createState() =>
      _GpsTemperatureButtonState();
}

class _GpsTemperatureButtonState extends ConsumerState<GpsTemperatureButton> {
  bool _busy = false;

  Future<void> _fetch() async {
    setState(() => _busy = true);
    try {
      final t = await ref.read(outdoorTemperatureServiceProvider).current();
      if (mounted) widget.onTemperature(t);
    } on OutdoorTemperatureException catch (e) {
      if (mounted) widget.onError(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _busy
      ? const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      : IconButton(
          tooltip: 'Außentemperatur per GPS ermitteln',
          icon: const Icon(Icons.my_location),
          onPressed: _fetch,
        );
}

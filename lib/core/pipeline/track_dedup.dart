import '../config/nyooom_config.dart';
import 'pass_record.dart';

/// Removes repeated reports of one vehicle.
///
/// With secondary events the windows of neighbouring events overlap, so the
/// same S curve can be fitted from two windows. Two tracks of the same
/// direction whose closest approach lies within
/// [NyooomConfig.duplicateWindowS] are one vehicle: at 0.5 s and 30 km/h two
/// cars in one lane would be 4 m apart, less than a car length. The same
/// rule removes side lobes of the correlation and reflections from a wall
/// parallel to the road, which also run in the direction of the vehicle.
///
/// Records must arrive in the order of the events; the first valid report
/// wins. Rejected events (class C) never hide a valid measurement.
class TrackDeduplicator {
  TrackDeduplicator({required this.config});

  final NyooomConfig config;
  final List<({double t0, int direction})> _measured = [];

  /// False if [record] repeats a vehicle that was already reported.
  bool accept(PassRecord record) {
    if (record.richtung == 0 || record.kappa == null) return true;
    final t0 = record.offsetS;
    for (final m in _measured) {
      if (m.direction == record.richtung &&
          (m.t0 - t0).abs() < config.duplicateWindowS) {
        return false;
      }
    }
    if (record.klasse != QualityClass.c) {
      _measured.add((t0: t0, direction: record.richtung));
      // Events arrive in time order: older entries cannot match any more.
      _measured.removeWhere((m) => m.t0 < t0 - 4 * config.eventWindowS);
    }
    return true;
  }
}

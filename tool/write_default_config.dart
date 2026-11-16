// Writes assets/nyooom_config.json from the defaults in NyooomConfig.
// Run after changing a default: fvm dart run tool/write_default_config.dart
import 'dart:convert';
import 'dart:io';

import 'package:nyooom/core/config/nyooom_config.dart';

void main() {
  const encoder = JsonEncoder.withIndent('  ');
  File(
    'assets/nyooom_config.json',
  ).writeAsStringSync('${encoder.convert(const NyooomConfig().toJson())}\n');
}

import 'dart:convert';
import 'dart:io';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:test/test.dart';

void main() {
  group('NyooomConfig (technik.pdf 9.2)', () {
    test('defaults follow the start values of 9.2', () {
      const c = NyooomConfig();
      expect(c.highPassHz, 100);
      expect(c.eventBandLowHz, 500);
      expect(c.eventBandHighHz, 4000);
      expect(c.eventThresholdDb, 10);
      expect(c.eventWindowS, 4);
      expect(c.gccBlockLength, 2048);
      expect(c.gccHop, 512);
      expect(c.gccBandLowHz, 300);
      expect(c.gccBandHighHz, 8000);
      expect(c.gccZeroPadding, 16);
      expect(c.kappaMin, 0.5);
      expect(c.kappaMax, 8);
      expect(c.fitOutlierLimitS, 40e-6);
      expect(c.spectrogramWindow, 4096);
      expect(c.spectrogramHop, 512);
      expect(c.spectrogramFftSize, 16384);
      expect(c.toneBandLowHz, 150);
      expect(c.toneBandHighHz, 8000);
      expect(c.toneMinProminenceDb, 8);
      expect(c.toneMinLengthS, 0.5);
      expect(c.dopplerSpeedMin, 3);
      expect(c.dopplerSpeedMax, 25);
      expect(c.dopplerSpeedStep, 0.1);
      expect(c.accelerationCheckLimitKmh, 2);
      expect(c.lateralSpreadM, 0.4);
      expect(c.distanceCheckTolerance, 0.25);
      expect(c.residualLimitS, 30e-6);
      expect(c.sourceHeightM, 0.3);
    });

    test('defaults of the related values from 5.1, 5.2, 5.3, 5.4 and 7.4', () {
      const c = NyooomConfig();
      expect(c.eventLevelStepS, 0.05);
      expect(c.eventLevelSmoothingS, 0.3);
      expect(c.noiseFloorPercentile, 20);
      expect(c.noiseFloorHistoryS, 60);
      expect(c.overlapThresholdDb, 10);
      expect(c.gccSearchFactor, 1.2);
      expect(c.t0SearchRangeS, 1);
      expect(c.t0SearchStepS, 0.02);
      expect(c.toneOffsetRangeS, 0.3);
      expect(c.sharpnessPeakFactor, 3);
      expect(c.sharpnessMaxDirectionCosine, 0.95);
      expect(c.selfCalibrationMinCount, 30);
      expect(c.selfCalibrationWarnFraction, 0.2);
    });

    test('JSON round trip keeps every value', () {
      final json = const NyooomConfig().toJson();
      final changed = json.map(
        (k, v) => MapEntry(k, v is int ? v + 1 : (v as double) * 1.5),
      );
      final restored = NyooomConfig.fromJson(changed);
      expect(restored.toJson(), changed);
    });

    test('the shipped default file equals the defaults in code', () {
      final file = File('assets/nyooom_config.json');
      final decoded = jsonDecode(file.readAsStringSync());
      expect(
        NyooomConfig.fromJson(decoded as Map<String, dynamic>).toJson(),
        const NyooomConfig().toJson(),
      );
      expect(
        (decoded).keys.toSet(),
        const NyooomConfig().toJson().keys.toSet(),
      );
    });
  });
}

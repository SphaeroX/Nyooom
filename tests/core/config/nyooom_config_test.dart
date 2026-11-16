import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:test/test.dart';

void main() {
  group('NyooomConfig', () {
    test('defaults follow technik.pdf 9.2 and 4.4', () {
      const config = NyooomConfig();
      expect(config.sampleRate, 48000); // technik.pdf 9.2
      expect(config.clipThreshold, 0.9); // technik.pdf 4.4, check 3
    });

    test('round-trips through JSON', () {
      const config = NyooomConfig(sampleRate: 44100, clipThreshold: 0.8);
      final restored = NyooomConfig.fromJson(config.toJson());
      expect(restored.sampleRate, 44100);
      expect(restored.clipThreshold, 0.8);
    });

    test('missing JSON keys fall back to defaults', () {
      final restored = NyooomConfig.fromJson(const {});
      expect(restored.sampleRate, const NyooomConfig().sampleRate);
      expect(restored.clipThreshold, const NyooomConfig().clipThreshold);
    });
  });
}

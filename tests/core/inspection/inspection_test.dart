import 'dart:typed_data';

import 'package:nyooom/core/config/nyooom_config.dart';
import 'package:nyooom/core/inspection/heatmap.dart';
import 'package:nyooom/core/inspection/inspection.dart';
import 'package:nyooom/core/sim/scenarios.dart';
import 'package:test/test.dart';

void main() {
  const config = NyooomConfig();

  test('heatmap has the expected size and maps min/max to the scale ends', () {
    final values = Float64List.fromList([0, 1, 2, 3, 4, 5]);
    final image = heatmapRgba(values, rows: 2, columns: 3, min: 0, max: 5);
    expect(image.width, 2); // time runs along x
    expect(image.height, 3); // value axis along y, top = last column
    expect(image.rgba.length, 2 * 3 * 4);
    expect(image.pixel(0, 2), colorScale(0)); // row 0, column 0 at the bottom
    expect(image.pixel(1, 0), colorScale(1)); // row 1, column 2 at the top
    expect(image.pixel(0, 2)[3], 255);
  });

  test('brightest correlogram pixel per column follows the model', () {
    final rec = Scenarios.render(
      Scenarios.combustion(speedKmh: 50, distance: 4, t0: 2),
      durationS: 4,
    );
    final truth = rec.truths.single;
    final data = computeInspection(
      rec.signal,
      startS: 0,
      config: config,
      micSpacing: truth.micSpacing,
      speedOfSound: truth.speedOfSound,
    );
    final c = data.correlogram;
    final image = data.correlogramImage;
    expect(image.width, c.rowCount);
    expect(image.height, c.lagCount);
    for (var r = 0; r < c.rowCount; r++) {
      if ((c.times[r] - truth.receptionT0).abs() > 0.8) continue;
      var best = 0, bestLum = -1;
      for (var y = 0; y < image.height; y++) {
        final p = image.pixel(r, y);
        final lum = p[0] + p[1] + p[2];
        if (lum > bestLum) {
          bestLum = lum;
          best = y;
        }
      }
      final lag = c.lagAt(c.lagCount - 1 - best);
      expect(lag, closeTo(truth.model.tdoa(c.times[r]), 15e-6));
    }
  });

  test('level track and spectrogram cover the excerpt', () {
    final rec = Scenarios.render(
      Scenarios.electric(speedKmh: 30, distance: 5, t0: 1.5),
      durationS: 3,
    );
    final data = computeInspection(
      rec.signal,
      startS: 10,
      config: config,
      micSpacing: 0.15,
      speedOfSound: 343,
    );
    expect(data.startS, 10);
    expect(data.levelTimes.first, closeTo(0, 0.05));
    expect(data.levelTimes.last, closeTo(3, 0.06));
    // Level peaks near the pass.
    var best = 0;
    for (var i = 0; i < data.levelDb.length; i++) {
      if (data.levelDb[i] > data.levelDb[best]) best = i;
    }
    expect(data.levelTimes[best], closeTo(1.5, 0.3));
    expect(data.spectrogramImage.width, data.spectrogram.rowCount);
  });
}

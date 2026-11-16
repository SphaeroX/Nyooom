import 'dart:math' as math;
import 'dart:typed_data';

/// RGBA image (8 bit per channel, row-major from the top).
class RgbaImage {
  const RgbaImage(this.width, this.height, this.rgba);
  final int width;
  final int height;
  final Uint8List rgba;

  List<int> pixel(int x, int y) {
    final o = (y * width + x) * 4;
    return [rgba[o], rgba[o + 1], rgba[o + 2], rgba[o + 3]];
  }
}

/// Colour of [v] in 0..1 on a dark-blue → teal → yellow scale (similar to
/// viridis, readable in light and dark themes).
List<int> colorScale(double v) {
  const stops = [
    [68, 1, 84],
    [59, 82, 139],
    [33, 145, 140],
    [94, 201, 98],
    [253, 231, 37],
  ];
  final x = v.clamp(0.0, 1.0) * (stops.length - 1);
  final i = math.min(x.floor(), stops.length - 2);
  final f = x - i;
  return [
    for (var c = 0; c < 3; c++)
      (stops[i][c] + (stops[i + 1][c] - stops[i][c]) * f).round(),
    255,
  ];
}

/// Renders a row-major matrix (rows = time, columns = value axis) as an
/// image with time along x and the value axis upwards (last column on top).
RgbaImage heatmapRgba(
  Float64List values, {
  required int rows,
  required int columns,
  required double min,
  required double max,
}) {
  final rgba = Uint8List(rows * columns * 4);
  final span = max - min == 0 ? 1.0 : max - min;
  for (var r = 0; r < rows; r++) {
    for (var c = 0; c < columns; c++) {
      final color = colorScale((values[r * columns + c] - min) / span);
      final y = columns - 1 - c;
      final o = (y * rows + r) * 4;
      rgba[o] = color[0];
      rgba[o + 1] = color[1];
      rgba[o + 2] = color[2];
      rgba[o + 3] = 255;
    }
  }
  return RgbaImage(rows, columns, rgba);
}

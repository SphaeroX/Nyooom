import 'dart:math' as math;
import 'dart:typed_data';

/// Half width of the windowed-sinc interpolator in samples.
const int fractionalDelayHalfWidth = 16;

const int _tableResolution = 1024;
const double _kaiserBeta = 8;

/// Kaiser-windowed sinc kernel, tabulated over [-H, H] with
/// [_tableResolution] points per sample.
final Float64List _kernelTable = () {
  const h = fractionalDelayHalfWidth;
  final table = Float64List(2 * h * _tableResolution + 2);
  final norm = _besselI0(_kaiserBeta);
  for (var i = 0; i < table.length; i++) {
    final x = i / _tableResolution - h;
    final ratio = x / h;
    if (ratio.abs() >= 1) continue;
    final window = _besselI0(_kaiserBeta * math.sqrt(1 - ratio * ratio)) / norm;
    final sinc = x == 0 ? 1.0 : math.sin(math.pi * x) / (math.pi * x);
    table[i] = sinc * window;
  }
  return table;
}();

double _besselI0(double x) {
  var sum = 1.0, term = 1.0;
  for (var k = 1; k < 50; k++) {
    term *= (x / (2 * k)) * (x / (2 * k));
    sum += term;
    if (term < 1e-17 * sum) break;
  }
  return sum;
}

double _kernel(double x) {
  final pos = (x + fractionalDelayHalfWidth) * _tableResolution;
  final i = pos.floor();
  if (i < 0 || i >= _kernelTable.length - 1) return 0;
  final w = pos - i;
  return _kernelTable[i] * (1 - w) + _kernelTable[i + 1] * w;
}

/// Value of the band-limited signal [x] at fractional sample position
/// [position], using a Kaiser-windowed sinc interpolator. Samples outside
/// the signal count as zero.
///
/// Accurate to about 1e-3 for content below 0.34 of the sample rate.
double fractionalSample(Float64List x, double position) {
  final n0 = position.floor();
  final frac = position - n0;
  if (frac == 0) {
    return n0 >= 0 && n0 < x.length ? x[n0] : 0;
  }
  const h = fractionalDelayHalfWidth;
  final from = math.max(0, n0 - h + 1);
  final to = math.min(x.length - 1, n0 + h);
  var acc = 0.0;
  for (var k = from; k <= to; k++) {
    acc += x[k] * _kernel(position - k);
  }
  return acc;
}

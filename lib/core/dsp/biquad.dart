import 'dart:math' as math;
import 'dart:typed_data';

/// Q of a second-order Butterworth section.
const double butterworthQ = 0.7071067811865476;

/// Second-order IIR section (RBJ audio EQ cookbook, bilinear transform),
/// direct form I. Keeps its state between blocks.
class Biquad {
  Biquad._(this.b0, this.b1, this.b2, this.a1, this.a2, this.sampleRate);

  /// Butterworth high-pass.
  factory Biquad.highPass(
    double sampleRate,
    double cornerHz, {
    double q = butterworthQ,
  }) {
    final w = 2 * math.pi * cornerHz / sampleRate;
    final alpha = math.sin(w) / (2 * q);
    final cw = math.cos(w);
    final a0 = 1 + alpha;
    return Biquad._(
      (1 + cw) / 2 / a0,
      -(1 + cw) / a0,
      (1 + cw) / 2 / a0,
      -2 * cw / a0,
      (1 - alpha) / a0,
      sampleRate,
    );
  }

  /// Butterworth low-pass.
  factory Biquad.lowPass(
    double sampleRate,
    double cornerHz, {
    double q = butterworthQ,
  }) {
    final w = 2 * math.pi * cornerHz / sampleRate;
    final alpha = math.sin(w) / (2 * q);
    final cw = math.cos(w);
    final a0 = 1 + alpha;
    return Biquad._(
      (1 - cw) / 2 / a0,
      (1 - cw) / a0,
      (1 - cw) / 2 / a0,
      -2 * cw / a0,
      (1 - alpha) / a0,
      sampleRate,
    );
  }

  final double b0, b1, b2, a1, a2;
  final double sampleRate;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  double process(double x) {
    final y = b0 * x + b1 * _x1 + b2 * _x2 - a1 * _y1 - a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }

  Float64List processBlock(Float64List x) {
    final y = Float64List(x.length);
    for (var i = 0; i < x.length; i++) {
      y[i] = process(x[i]);
    }
    return y;
  }

  void reset() {
    _x1 = _x2 = _y1 = _y2 = 0;
  }

  /// Magnitude of the transfer function at [frequencyHz].
  double gainAt(double frequencyHz) {
    final w = 2 * math.pi * frequencyHz / sampleRate;
    // H(e^jw) = (b0 + b1 z^-1 + b2 z^-2) / (1 + a1 z^-1 + a2 z^-2)
    final c1 = math.cos(w), s1 = math.sin(w);
    final c2 = math.cos(2 * w), s2 = math.sin(2 * w);
    final nr = b0 + b1 * c1 + b2 * c2, ni = -(b1 * s1 + b2 * s2);
    final dr = 1 + a1 * c1 + a2 * c2, di = -(a1 * s1 + a2 * s2);
    return math.sqrt((nr * nr + ni * ni) / (dr * dr + di * di));
  }
}

/// Cascade of [Biquad] sections.
class BiquadChain {
  BiquadChain(this.sections);

  /// Band-pass from a Butterworth high-pass and low-pass section.
  factory BiquadChain.bandPass(
    double sampleRate,
    double lowHz,
    double highHz,
  ) => BiquadChain([
    Biquad.highPass(sampleRate, lowHz),
    Biquad.lowPass(sampleRate, highHz),
  ]);

  final List<Biquad> sections;

  double process(double x) {
    var y = x;
    for (final s in sections) {
      y = s.process(y);
    }
    return y;
  }

  Float64List processBlock(Float64List x) {
    final y = Float64List(x.length);
    for (var i = 0; i < x.length; i++) {
      y[i] = process(x[i]);
    }
    return y;
  }

  void reset() {
    for (final s in sections) {
      s.reset();
    }
  }

  double gainAt(double frequencyHz) =>
      sections.fold(1.0, (g, s) => g * s.gainAt(frequencyHz));
}

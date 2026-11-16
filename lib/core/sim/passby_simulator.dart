import 'dart:math' as math;
import 'dart:typed_data';

import '../dsp/biquad.dart';
import '../dsp/fractional_delay.dart';
import '../model/passby_model.dart';
import '../signal/pcm.dart';

/// Kind of simulated vehicle.
enum VehicleKind { combustion, electric }

/// One tone of the emitted signal (engine harmonic or warning sound).
class ToneSpec {
  const ToneSpec(this.frequency, this.amplitude);

  /// Emitted frequency f0 in Hz at the reference speed.
  final double frequency;

  /// Peak amplitude at 1 m.
  final double amplitude;
}

/// One simulated vehicle pass.
///
/// Geometry (technik.pdf 3.1): the noise source moves along x with
/// x(te) = v·τ + a·τ²/2, τ = te − t0, at slant distance [distance]. The tone
/// source runs [toneLeadS] ahead of it (engine in front, technik.pdf 6.1).
class VehiclePass {
  const VehiclePass({
    required this.speed,
    required this.distance,
    required this.t0,
    this.kind = VehicleKind.combustion,
    this.acceleration = 0,
    this.noiseRms = 0.1,
    this.tones = const [],
    this.toneLeadS = 0,
    this.tonePitchFollowsSpeed = true,
  });

  /// Signed speed at t0 in m/s (positive in +x direction).
  final double speed;

  /// Slant distance d in m.
  final double distance;

  /// Emission time of closest approach of the noise source in s.
  final double t0;

  final VehicleKind kind;

  /// Signed acceleration along x in m/s².
  final double acceleration;

  /// RMS of the broadband (tyre) noise at 1 m.
  final double noiseRms;

  final List<ToneSpec> tones;

  /// Time by which the tone source passes earlier than the noise source.
  final double toneLeadS;

  /// Engine tones rise with speed (fixed gear) instead of staying constant.
  final bool tonePitchFollowsSpeed;

  /// Total RMS of the source at 1 m.
  double get sourceRms => math.sqrt(
    noiseRms * noiseRms +
        tones.fold(0.0, (s, t) => s + t.amplitude * t.amplitude / 2),
  );

  double positionAt(double emissionTime) {
    final tau = emissionTime - t0;
    return speed * tau + 0.5 * acceleration * tau * tau;
  }

  double velocityAt(double emissionTime) =>
      speed + acceleration * (emissionTime - t0);
}

/// Background RMS so that the source at closest approach is [snrDb] above it.
double backgroundRmsForSnr(VehiclePass pass, double snrDb) =>
    pass.sourceRms / pass.distance / math.pow(10, snrDb / 20);

/// Recording setup of the simulation.
class SimulationSetup {
  const SimulationSetup({
    this.sampleRate = 48000,
    required this.micSpacing,
    required this.speedOfSound,
    this.channelOffset = 0,
    this.backgroundRms = 0,
    this.seed = 1,
  });

  final int sampleRate;

  /// Effective microphone spacing b in m. The left channel is the
  /// microphone at x = −b/2, the right channel the one at x = +b/2, so the
  /// TDOA (left minus right arrival) is +b/c·u (technik.pdf 3.2).
  final double micSpacing;

  final double speedOfSound;

  /// Extra delay Δ0 of the left channel in s.
  final double channelOffset;

  /// RMS of the independent white background noise per channel.
  final double backgroundRms;

  final int seed;
}

/// True values of one simulated pass.
class GroundTruth {
  const GroundTruth({
    required this.pass,
    required this.micSpacing,
    required this.speedOfSound,
    required this.channelOffset,
  });

  final VehiclePass pass;
  final double micSpacing;
  final double speedOfSound;
  final double channelOffset;

  VehicleKind get kind => pass.kind;
  double get speed => pass.speed;
  double get distance => pass.distance;
  double get t0 => pass.t0;
  double get acceleration => pass.acceleration;
  double get toneLeadS => pass.toneLeadS;
  int get direction => pass.speed >= 0 ? 1 : -1;
  double get kappa => pass.speed / pass.distance;
  List<double> get toneFrequencies =>
      pass.tones.map((t) => t.frequency).toList();

  /// Reception time of the closest approach.
  double get receptionT0 => pass.t0 + pass.distance / speedOfSound;

  /// Constant-speed model of the noise source.
  PassByModel get model => PassByModel(
    speed: pass.speed,
    distance: pass.distance,
    t0: pass.t0,
    micSpacing: micSpacing,
    speedOfSound: speedOfSound,
    channelOffset: channelOffset,
  );

  /// Constant-speed model of the tone source.
  PassByModel get toneModel => PassByModel(
    speed: pass.speed,
    distance: pass.distance,
    t0: pass.t0 - pass.toneLeadS,
    micSpacing: micSpacing,
    speedOfSound: speedOfSound,
    channelOffset: channelOffset,
  );
}

/// Result of [PassBySimulator.render].
class SimulatedRecording {
  const SimulatedRecording({
    required this.signal,
    required this.truths,
    required this.sampleRate,
  });

  final StereoBlock signal;
  final List<GroundTruth> truths;
  final int sampleRate;
}

/// Generates synthetic stereo vehicle passes with known ground truth.
///
/// Each microphone receives the emitted signal at t = te + r_mic(te)/c with
/// 1/r attenuation. Broadband noise is resampled with a windowed-sinc
/// fractional delay, tones are evaluated analytically, so the Doppler shift
/// and sub-sample delays arise from the geometry alone.
class PassBySimulator {
  PassBySimulator(this.setup);

  final SimulationSetup setup;

  SimulatedRecording render(double durationS, List<VehiclePass> passes) {
    final fs = setup.sampleRate.toDouble();
    final n = (durationS * fs).round();
    final left = Float64List(n);
    final right = Float64List(n);
    final random = math.Random(setup.seed);

    for (final pass in passes) {
      // Noise buffer on the emission-time grid, shared by both channels.
      final c = setup.speedOfSound;
      final rMax = [
        -1.0,
        durationS + 1,
      ].map((t) => _range(pass, t, 0) + setup.micSpacing).reduce(math.max);
      final teStart = -(rMax / c) - 0.1;
      final teEnd = durationS + 0.1;
      final noise = pass.noiseRms > 0
          ? _shapedNoise(((teEnd - teStart) * fs).ceil(), pass.noiseRms, random)
          : null;
      _renderChannel(pass, left, -setup.micSpacing / 2, noise, teStart, true);
      _renderChannel(pass, right, setup.micSpacing / 2, noise, teStart, false);
    }

    if (setup.backgroundRms > 0) {
      final bg = math.Random(setup.seed * 7919 + 17);
      for (var i = 0; i < n; i++) {
        left[i] += setup.backgroundRms * _gauss(bg);
        right[i] += setup.backgroundRms * _gauss(bg);
      }
    }

    return SimulatedRecording(
      signal: StereoBlock(left, right),
      truths: [
        for (final p in passes)
          GroundTruth(
            pass: p,
            micSpacing: setup.micSpacing,
            speedOfSound: setup.speedOfSound,
            channelOffset: setup.channelOffset,
          ),
      ],
      sampleRate: setup.sampleRate,
    );
  }

  void _renderChannel(
    VehiclePass pass,
    Float64List out,
    double micPosition,
    Float64List? noise,
    double teStart,
    bool isLeft,
  ) {
    final fs = setup.sampleRate.toDouble();
    final c = setup.speedOfSound;
    final channelDelay = isLeft ? setup.channelOffset : 0.0;

    var teNoise = -pass.distance / c;
    var teTone = teNoise;
    final toneSource = _ShiftedPass(pass, pass.toneLeadS);
    for (var i = 0; i < out.length; i++) {
      final t = i / fs - channelDelay;
      var sample = 0.0;
      if (noise != null) {
        teNoise = _solve(
          t,
          teNoise,
          pass.positionAt,
          pass.velocityAt,
          pass.distance,
          micPosition,
          c,
        );
        final r = _range(pass, teNoise, micPosition);
        sample += fractionalSample(noise, (teNoise - teStart) * fs) / r;
      }
      if (pass.tones.isNotEmpty) {
        teTone = _solve(
          t,
          teTone,
          toneSource.positionAt,
          toneSource.velocityAt,
          pass.distance,
          micPosition,
          c,
        );
        final x = toneSource.positionAt(teTone) - micPosition;
        final r = math.sqrt(x * x + pass.distance * pass.distance);
        // Phase of the emitted tone: with the pitch following the speed the
        // instantaneous frequency is f0·v(te)/v(t0).
        final cycles = pass.tonePitchFollowsSpeed && pass.speed != 0
            ? toneSource.positionAt(teTone) / pass.speed
            : teTone;
        for (final tone in pass.tones) {
          sample +=
              tone.amplitude *
              math.sin(2 * math.pi * tone.frequency * cycles) /
              r;
        }
      }
      out[i] += sample;
    }
  }

  static double _range(VehiclePass pass, double te, double micPosition) {
    final x = pass.positionAt(te) - micPosition;
    return math.sqrt(x * x + pass.distance * pass.distance);
  }

  static double _solve(
    double t,
    double guess,
    double Function(double) position,
    double Function(double) velocity,
    double distance,
    double micPosition,
    double c,
  ) {
    var te = guess;
    for (var k = 0; k < 20; k++) {
      final x = position(te) - micPosition;
      final r = math.sqrt(x * x + distance * distance);
      final g = te + r / c - t;
      final dg = 1 + x * velocity(te) / (r * c);
      final step = g / dg;
      te -= step;
      if (step.abs() < 1e-12) break;
    }
    return te;
  }

  Float64List _shapedNoise(int length, double rms, math.Random random) {
    final fs = setup.sampleRate.toDouble();
    final x = Float64List(length);
    for (var i = 0; i < length; i++) {
      x[i] = _gauss(random);
    }
    // Band-limit to 0.2·fs so the sinc interpolation stays exact.
    final lp = BiquadChain([
      Biquad.lowPass(fs, 0.2 * fs),
      Biquad.lowPass(fs, 0.2 * fs),
    ]);
    final y = lp.processBlock(x);
    var acc = 0.0;
    for (final v in y) {
      acc += v * v;
    }
    final scale = rms / math.sqrt(acc / length);
    for (var i = 0; i < length; i++) {
      y[i] *= scale;
    }
    return y;
  }

  static double _gauss(math.Random random) {
    final u1 = 1 - random.nextDouble();
    final u2 = random.nextDouble();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }
}

class _ShiftedPass {
  _ShiftedPass(this.pass, this.lead);
  final VehiclePass pass;
  final double lead;
  double positionAt(double te) => pass.positionAt(te + lead);
  double velocityAt(double te) => pass.velocityAt(te + lead);
}

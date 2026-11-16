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
    this.noiseSeed,
    this.audibleSpanS,
  });

  /// If set, the source fades out (raised cosine over the last second)
  /// when |te − t0| approaches this span, so a vehicle has a finite
  /// audible life (used by the traffic simulation).
  final double? audibleSpanS;

  /// Source gain at emission time [emissionTime] (1 without [audibleSpanS]).
  double envelopeAt(double emissionTime) {
    final span = audibleSpanS;
    if (span == null) return 1;
    final d = (emissionTime - t0).abs();
    if (d <= span - 1) return 1;
    if (d >= span) return 0;
    return 0.5 * (1 + math.cos(math.pi * (d - (span - 1))));
  }

  /// Seed of the tyre noise; defaults to the index in the rendered list.
  final int? noiseSeed;

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

  /// Renders [durationS] seconds starting at absolute time [startTime].
  ///
  /// All random parts are derived from the absolute sample index, so
  /// consecutive chunks join seamlessly (used by the live simulation).
  SimulatedRecording render(
    double durationS,
    List<VehiclePass> passes, {
    double startTime = 0,
  }) {
    final fs = setup.sampleRate.toDouble();
    final n = (durationS * fs).round();
    final left = Float64List(n);
    final right = Float64List(n);

    for (var p = 0; p < passes.length; p++) {
      final pass = passes[p];
      // Noise buffer on the absolute emission-time grid k/fs, shared by both
      // channels.
      final c = setup.speedOfSound;
      final rMax = [
        startTime - 1,
        startTime + durationS + 1,
      ].map((t) => _range(pass, t, 0) + setup.micSpacing).reduce(math.max);
      final kStart = ((startTime - rMax / c - 0.1) * fs).floor();
      final kEnd = ((startTime + durationS + 0.1) * fs).ceil();
      final noise = pass.noiseRms > 0
          ? _shapedNoise(
              kStart,
              kEnd - kStart,
              pass.noiseRms,
              setup.seed * 1000003 + (pass.noiseSeed ?? p),
            )
          : null;
      final teStart = kStart / fs;
      _renderChannel(
        pass,
        left,
        -setup.micSpacing / 2,
        noise,
        teStart,
        startTime,
        true,
      );
      _renderChannel(
        pass,
        right,
        setup.micSpacing / 2,
        noise,
        teStart,
        startTime,
        false,
      );
    }

    if (setup.backgroundRms > 0) {
      final k0 = (startTime * fs).round();
      for (var i = 0; i < n; i++) {
        left[i] += setup.backgroundRms * _hashGauss(setup.seed, 1, k0 + i);
        right[i] += setup.backgroundRms * _hashGauss(setup.seed, 2, k0 + i);
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
    double startTime,
    bool isLeft,
  ) {
    final fs = setup.sampleRate.toDouble();
    final c = setup.speedOfSound;
    final channelDelay = isLeft ? setup.channelOffset : 0.0;

    final firstT = startTime - channelDelay;
    var teNoise = firstT - _range(pass, firstT, micPosition) / c;
    var teTone = teNoise;
    final toneSource = _ShiftedPass(pass, pass.toneLeadS);
    for (var i = 0; i < out.length; i++) {
      final t = startTime + i / fs - channelDelay;
      // Skip samples long after the vehicle faded out (the margin covers
      // the sound travel time).
      final span = pass.audibleSpanS;
      if (span != null && (t - pass.t0).abs() > span + 2) continue;
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
        sample +=
            pass.envelopeAt(teNoise) *
            fractionalSample(noise, (teNoise - teStart) * fs) /
            r;
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
        final envelope = pass.envelopeAt(teTone + pass.toneLeadS);
        for (final tone in pass.tones) {
          sample +=
              envelope *
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

  /// Band-limited Gaussian noise for absolute samples [first]..first+length.
  Float64List _shapedNoise(int first, int length, double rms, int seed) {
    final fs = setup.sampleRate.toDouble();
    // Band-limit to 0.2·fs so the sinc interpolation stays exact. The IIR
    // filter starts [_warmUp] samples early so its state no longer depends
    // on where the chunk begins.
    final lp = _noiseFilter(fs);
    for (var k = first - _warmUp; k < first; k++) {
      lp.process(_hashGauss(seed, 0, k));
    }
    final scale = rms / math.sqrt(_noiseFilterEnergy(fs));
    final y = Float64List(length);
    for (var i = 0; i < length; i++) {
      y[i] = lp.process(_hashGauss(seed, 0, first + i)) * scale;
    }
    return y;
  }

  static const int _warmUp = 4096;

  static BiquadChain _noiseFilter(double fs) =>
      BiquadChain([Biquad.lowPass(fs, 0.2 * fs), Biquad.lowPass(fs, 0.2 * fs)]);

  static final Map<double, double> _energyCache = {};

  /// Output variance of [_noiseFilter] for unit-variance white input.
  static double _noiseFilterEnergy(double fs) =>
      _energyCache.putIfAbsent(fs, () {
        final f = _noiseFilter(fs);
        var energy = 0.0;
        for (var i = 0; i < 4096; i++) {
          final h = f.process(i == 0 ? 1 : 0);
          energy += h * h;
        }
        return energy;
      });

  /// Standard normal value for (seed, stream, index), stateless.
  static double _hashGauss(int seed, int stream, int index) {
    final u1 =
        (_mix(_mix(index ^ (seed * 0x9e3779b9)) + stream * 2) + 0.5) /
        4294967296.0;
    final u2 =
        (_mix(_mix(index ^ (seed * 0x9e3779b9)) + stream * 2 + 1) + 0.5) /
        4294967296.0;
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }

  /// 32-bit avalanche mix (MurmurHash3 finaliser).
  static int _mix(int value) {
    var x = value & 0xffffffff;
    x ^= x >> 16;
    x = (x * 0x85ebca6b) & 0xffffffff;
    x ^= x >> 13;
    x = (x * 0xc2b2ae35) & 0xffffffff;
    x ^= x >> 16;
    return x;
  }
}

class _ShiftedPass {
  _ShiftedPass(this.pass, this.lead);
  final VehiclePass pass;
  final double lead;
  double positionAt(double te) => pass.positionAt(te + lead);
  double velocityAt(double te) => pass.velocityAt(te + lead);
}

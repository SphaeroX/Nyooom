import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../core/signal/pcm.dart';
import '../core/sim/scenarios.dart';
import '../core/sim/traffic.dart';
import 'stereo_recorder.dart';

/// Recorder that streams synthetic traffic instead of the microphones.
///
/// Lets the app run without a suitable phone (emulator, development).
/// Chunks are rendered in a background isolate one step ahead; with
/// [realTime] the blocks are paced like a real recording.
class SimulatedStereoRecorder implements StereoRecorder {
  SimulatedStereoRecorder({
    required List<TrafficLane> lanes,
    int seed = 1,
    this.realTime = true,
    this.chunkS = 1,
    this.blockFrames = 960,
    double micSpacing = Scenarios.defaultMicSpacing,
    double temperatureC = Scenarios.defaultTemperatureC,
    double channelOffset = 0,
    double backgroundRms = 0.002,
  }) : traffic = TrafficGenerator(lanes: lanes, seed: seed),
       setup = Scenarios.setup(
         micSpacing: micSpacing,
         temperatureC: temperatureC,
         channelOffset: channelOffset,
         backgroundRms: backgroundRms,
         seed: seed,
       );

  /// Device model reported by [capabilities].
  static const deviceModel = 'Simulation';

  final TrafficGenerator traffic;
  SimulationSetup setup;

  /// Sets the air temperature of the simulation (before [start]), so that
  /// c matches the temperature entered for the series.
  void setTemperature(double temperatureC) {
    setup = Scenarios.setup(
      micSpacing: setup.micSpacing,
      temperatureC: temperatureC,
      channelOffset: setup.channelOffset,
      backgroundRms: setup.backgroundRms,
      seed: setup.seed,
      sampleRate: setup.sampleRate,
    );
  }

  final bool realTime;
  final double chunkS;
  final int blockFrames;

  final _controller = StreamController<Uint8List>.broadcast();
  bool _running = false;
  double _emittedS = 0;

  /// Seconds of signal emitted since [start].
  double get emittedS => _emittedS;

  /// Ground truth of the vehicles whose closest approach was emitted.
  List<GroundTruth> get pastTruths => [
    for (final p in traffic.passesBetween(0, _emittedS))
      GroundTruth(
        pass: p,
        micSpacing: setup.micSpacing,
        speedOfSound: setup.speedOfSound,
        channelOffset: setup.channelOffset,
      ),
  ];

  @override
  Future<AudioCapabilities> capabilities() async => const AudioCapabilities(
    unprocessedSupported: true,
    agcAvailable: false,
    nsAvailable: false,
    aecAvailable: false,
    deviceModel: deviceModel,
    sdkInt: 0,
    microphones: ['simulated left (x = -b/2)', 'simulated right (x = +b/2)'],
  );

  @override
  Future<List<InputDevice>> inputDevices() async => const [
    InputDevice(id: 0, name: 'Simulation', type: 0, isExternal: false),
  ];

  @override
  Future<RecordingInfo> start({
    required int sampleRate,
    int? inputDeviceId,
  }) async {
    if (_running) throw StateError('already running');
    _running = true;
    _emittedS = 0;
    unawaited(_run());
    return RecordingInfo(
      audioSource: AudioSourceKind.simulated,
      sampleRate: setup.sampleRate,
      channels: 2,
      effects: const {
        'agc': EffectState.unavailable,
        'ns': EffectState.unavailable,
        'aec': EffectState.unavailable,
      },
    );
  }

  @override
  Future<void> stop() async {
    _running = false;
  }

  @override
  Stream<Uint8List> get pcmBlocks => _controller.stream;

  @override
  Stream<StereoBlock> get blocks => pcmBlocks.map(deinterleavePcm16Bytes);

  Future<Uint8List> _renderChunk(int index) {
    final start = index * chunkS;
    final passes = traffic.passesAffecting(start, start + chunkS);
    final setup = this.setup;
    final duration = chunkS;
    return Isolate.run(() {
      final rec = PassBySimulator(setup)
          .render(duration, passes, startTime: start);
      return interleavePcm16(rec.signal).buffer.asUint8List();
    });
  }

  Future<void> _run() async {
    final clock = Stopwatch()..start();
    var index = 0;
    var next = _renderChunk(index);
    final bytesPerBlock = blockFrames * 4;
    final blockS = blockFrames / setup.sampleRate;
    while (_running) {
      final chunk = await next;
      index++;
      next = _renderChunk(index);
      for (var o = 0; o < chunk.length && _running; o += bytesPerBlock) {
        final end = o + bytesPerBlock < chunk.length
            ? o + bytesPerBlock
            : chunk.length;
        if (realTime) {
          final due = Duration(
            microseconds: ((_emittedS + blockS) * 1e6).round(),
          );
          final wait = due - clock.elapsed;
          if (wait > Duration.zero) await Future<void>.delayed(wait);
        }
        if (!_running) break;
        _controller.add(Uint8List.sublistView(chunk, o, end));
        _emittedS += (end - o) / 4 / setup.sampleRate;
      }
      if (!realTime) await Future<void>.delayed(Duration.zero);
    }
  }
}

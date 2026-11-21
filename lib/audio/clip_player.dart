import 'dart:async';

import 'package:flutter/services.dart';

/// Plays a recorded clip (WAV file) for listening.
abstract interface class ClipPlayer {
  Future<void> play(String path);
  Future<void> stop();

  /// One event whenever a clip has played to its end.
  Stream<void> get completions;
}

/// Playback through `NyooomAudioPlugin` (Android `MediaPlayer`), on its own
/// method channel so its callback does not replace the recorder's.
class PlatformClipPlayer implements ClipPlayer {
  PlatformClipPlayer({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'de.nyooom/playback';

  /// Call from the platform when a clip has played to its end.
  static const completedMethod = 'playbackCompleted';

  final MethodChannel _channel;
  final _completions = StreamController<void>.broadcast();
  bool _handlerSet = false;

  @override
  Future<void> play(String path) =>
      _channel.invokeMethod<void>('playFile', {'path': path});

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stopPlayback');

  @override
  Stream<void> get completions {
    if (!_handlerSet) {
      _handlerSet = true;
      _channel.setMethodCallHandler((call) async {
        if (call.method == completedMethod) _completions.add(null);
        return null;
      });
    }
    return _completions.stream;
  }
}

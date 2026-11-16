import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../audio/stereo_recorder.dart';
import '../../core/signal/level.dart';
import 'recorder_controller.dart';

/// Raw stereo recording: live level per channel and WAV saving.
class RecorderScreen extends ConsumerWidget {
  const RecorderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recorderControllerProvider);
    final controller = ref.read(recorderControllerProvider.notifier);
    final caps = ref.watch(capabilitiesProvider);
    final clipPercent = (ref.watch(configProvider).clipThreshold * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Nyooom – Stereo-Aufnahme')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            caps.when(
              data: (c) => Text(
                'Gerät: ${c.deviceModel} (API ${c.sdkInt})\n'
                'Unbearbeitete Quelle unterstützt: ${c.unprocessedSupported ? 'ja' : 'nein'}\n'
                'Effekte vorhanden: AGC ${_yesNo(c.agcAvailable)}, '
                'NS ${_yesNo(c.nsAvailable)}, AEC ${_yesNo(c.aecAvailable)}'
                '${c.microphones.isEmpty ? '' : '\nMikrofone: ${c.microphones.join(', ')}'}',
              ),
              loading: () => const Text('Gerätefähigkeiten werden gelesen …'),
              error: (e, _) => Text('Gerätefähigkeiten unbekannt: $e'),
            ),
            const SizedBox(height: 16),
            if (state.info != null) _SessionInfo(info: state.info!),
            const SizedBox(height: 16),
            _LevelMeter(
              label: 'Kanal 1 (links)',
              level: state.left,
              clipSeen: state.leftClipSeen,
              clipPercent: clipPercent,
            ),
            const SizedBox(height: 12),
            _LevelMeter(
              label: 'Kanal 2 (rechts)',
              level: state.right,
              clipSeen: state.rightClipSeen,
              clipPercent: clipPercent,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: state.running ? controller.stop : controller.start,
                  child: Text(state.running ? 'Stopp' : 'Start'),
                ),
                OutlinedButton(
                  onPressed: !state.running
                      ? null
                      : state.saving
                      ? controller.stopSaving
                      : controller.startSaving,
                  child: Text(
                    state.saving ? 'Aufnahme speichern' : 'Aufnahme starten',
                  ),
                ),
              ],
            ),
            if (state.saving)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('WAV-Aufnahme läuft …'),
              ),
            if (state.savedPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Gespeichert: ${state.savedPath}'),
              ),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _yesNo(bool value) => value ? 'ja' : 'nein';
}

class _SessionInfo extends StatelessWidget {
  const _SessionInfo({required this.info});

  final RecordingInfo info;

  static String _effect(EffectState? state) => switch (state) {
    EffectState.disabled => 'aus',
    EffectState.enabled => 'AN (nicht abschaltbar)',
    EffectState.unavailable || null => 'nicht vorhanden',
  };

  @override
  Widget build(BuildContext context) {
    final fallback = info.audioSource != AudioSourceKind.unprocessed;
    return Text(
      'Audioquelle: ${info.audioSource.platformName}'
      '${fallback ? ' (Rückfall)' : ''}\n'
      '${info.sampleRate} Hz, ${info.channels} Kanäle\n'
      'AGC: ${_effect(info.effects['agc'])} · '
      'NS: ${_effect(info.effects['ns'])} · '
      'AEC: ${_effect(info.effects['aec'])}',
    );
  }
}

class _LevelMeter extends StatelessWidget {
  const _LevelMeter({
    required this.label,
    required this.level,
    required this.clipSeen,
    required this.clipPercent,
  });

  final String label;
  final ChannelLevel level;
  final bool clipSeen;
  final int clipPercent;

  /// Display range of the bar; below this the bar is empty.
  static const double _barFloorDbfs = -60;

  @override
  Widget build(BuildContext context) {
    final fraction = ((level.rmsDbfs - _barFloorDbfs) / -_barFloorDbfs).clamp(
      0.0,
      1.0,
    );
    final errorColor = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: RMS ${_format(level.rmsDbfs)} · '
          'Peak ${_format(level.peakDbfs)}',
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: fraction,
          minHeight: 12,
          color: level.clipping ? errorColor : null,
        ),
        if (clipSeen)
          Text(
            'Übersteuerung (> $clipPercent % Vollaussteuerung)',
            style: TextStyle(color: errorColor),
          ),
      ],
    );
  }

  static String _format(double dbfs) =>
      dbfs <= silenceDbfs ? '−∞ dBFS' : '${dbfs.toStringAsFixed(1)} dBFS';
}

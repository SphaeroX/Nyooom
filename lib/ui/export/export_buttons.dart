import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/series_export.dart';
import '../providers.dart';

/// Shares files through the Android share sheet (replaceable in tests).
typedef FileSharer = Future<void> Function(List<File> files, String subject);

final fileSharerProvider = Provider<FileSharer>(
  (ref) => (files, subject) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [for (final f in files) XFile(f.path)],
        subject: subject,
      ),
    );
  },
);

/// Export of a series as CSV/JSON or as ZIP with raw audio (Task_14).
class ExportButtons extends ConsumerStatefulWidget {
  const ExportButtons({super.key, required this.seriesId});

  final int seriesId;

  @override
  ConsumerState<ExportButtons> createState() => _ExportButtonsState();
}

class _ExportButtonsState extends ConsumerState<ExportButtons> {
  bool _busy = false;
  String? _error;

  Future<void> _export({required bool zip}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final temp = await getTemporaryDirectory();
      final result = await exportSeries(
        repo: ref.read(repositoryProvider),
        storage: await ref.read(seriesStorageProvider.future),
        seriesId: widget.seriesId,
        target: Directory(
          '${temp.path}/exports/messreihe_${widget.seriesId}_'
          '${DateTime.now().millisecondsSinceEpoch}',
        ),
        config: ref.read(configProvider),
        zipWithAudio: zip,
      );
      await ref.read(fileSharerProvider)(
        zip ? [result.zip!] : result.files,
        'Nyooom Messreihe ${widget.seriesId}',
      );
    } catch (e) {
      if (mounted) setState(() => _error = 'Export fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _export(zip: false),
              icon: const Icon(Icons.ios_share),
              label: const Text('CSV + JSON teilen'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _export(zip: true),
              icon: const Icon(Icons.folder_zip_outlined),
              label: const Text('ZIP mit Rohaudio'),
            ),
          ],
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}

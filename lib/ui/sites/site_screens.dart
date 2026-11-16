import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/site/site.dart';
import '../../data/repository.dart';
import '../providers.dart';
import 'site_form.dart';

/// List of measuring sites.
class SiteListScreen extends ConsumerWidget {
  const SiteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sites = ref.watch(sitesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Standorte')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SiteEditScreen())),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Neuer Standort'),
      ),
      body: sites.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (list) => list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Noch kein Standort. Lege einen Standort mit den '
                    'Abständen der Fahrspuren an, bevor du misst.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView(
                children: [
                  for (final s in list)
                    ListTile(
                      leading: const Icon(Icons.place_outlined),
                      title: Text(s.spec.name),
                      subtitle: Text(_laneSummary(s.spec)),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SiteEditScreen(site: s),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

String _laneSummary(SiteSpec s) {
  final lanes = s.lanes
      .map(
        (l) =>
            '${l.direction > 0 ? '→' : '←'} '
            '${l.horizontalDistance.toStringAsFixed(1)} m',
      )
      .join(', ');
  return '$lanes · Höhe ${s.micHeight.toStringAsFixed(2)} m · '
      '${s.speedLimitKmh.round()} km/h';
}

/// Create or edit a site.
class SiteEditScreen extends ConsumerWidget {
  const SiteEditScreen({super.key, this.site});

  final StoredSite? site;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = site;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          existing == null ? 'Neuer Standort' : 'Standort bearbeiten',
        ),
        actions: [
          if (existing != null)
            IconButton(
              tooltip: 'Standort löschen',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await confirmDelete(
                  context,
                  'Standort „${existing.spec.name}“ mit allen Messreihen '
                  'löschen?',
                );
                if (!ok) return;
                await ref.read(repositoryProvider).deleteSite(existing.id);
                ref.invalidate(sitesProvider);
                ref.invalidate(seriesListProvider);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: SiteForm(
        initial: existing?.spec,
        onSubmit: (spec) async {
          final repo = ref.read(repositoryProvider);
          if (existing == null) {
            await repo.createSite(spec);
          } else {
            await repo.updateSite(existing.id, spec);
          }
          ref.invalidate(sitesProvider);
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
  }
}

/// Asks before deleting; returns true on confirmation.
Future<bool> confirmDelete(BuildContext context, String question) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Löschen?'),
      content: Text(question),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Löschen'),
        ),
      ],
    ),
  );
  return result ?? false;
}

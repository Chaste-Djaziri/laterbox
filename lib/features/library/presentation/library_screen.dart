import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../enrichment/domain/content_type.dart';
import '../../collections/presentation/collection_providers.dart';
import 'library_providers.dart';
import 'library_section_screen.dart';

/// The Library hub: All / Favorites / Archived rows plus a grid of
/// collections. Tapping anything drills into a filtered item list.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(allItemsProvider);
    final kept = ref.watch(keptProvider);
    final favorites = ref.watch(favoritesProvider);
    final archived = ref.watch(archivedProvider);
    final collections = ref.watch(collectionCountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Library',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.6),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 104),
          children: [
            Text(
              'Library',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1.1,
              ),
            ),
            const SizedBox(height: 16),
            _SectionTile(
              icon: Icons.inventory_2_outlined,
              title: 'All Items',
              count: all.value?.length ?? 0,
              onTap: () => _openSection(
                context,
                title: 'All Items',
                provider: allItemsProvider,
              ),
            ),
            _SectionTile(
              icon: Icons.check_circle_outline_rounded,
              title: 'Kept',
              count: kept.value?.length ?? 0,
              onTap: () => _openSection(
                context,
                title: 'Kept',
                provider: keptProvider,
              ),
            ),
            _SectionTile(
              icon: Icons.star_outline_rounded,
              title: 'Favorites',
              count: favorites.value?.length ?? 0,
              onTap: () => _openSection(
                context,
                title: 'Favorites',
                provider: favoritesProvider,
              ),
            ),
            _SectionTile(
              icon: Icons.archive_outlined,
              title: 'Archived',
              count: archived.value?.length ?? 0,
              onTap: () => _openSection(
                context,
                title: 'Archived',
                provider: archivedProvider,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'TYPES',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _TypesSection(),
            const SizedBox(height: 28),
            Text(
              'COLLECTIONS',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            collections.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load collections: $error'),
              ),
              data: (collections) => GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  for (final (collection, count) in collections)
                    _CollectionTile(
                      collection: collection,
                      count: count,
                      onTap: () => _openSection(
                        context,
                        title: collection.name,
                        provider: collectionItemsProvider(collection.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _createCollection(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Collection'),
            ),
          ],
        ),
      ),
    );
  }

  void _openSection(
    BuildContext context, {
    required String title,
    required dynamic provider,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LibrarySectionScreen(title: title, provider: provider),
      ),
    );
  }

  Future<void> _createCollection(BuildContext context, WidgetRef ref) async {
    final name = await _promptForName(context, title: 'New collection');
    if (name == null || name.trim().isEmpty) return;
    await ref.read(collectionRepositoryProvider).create(name);
  }

  Future<String?> _promptForName(
    BuildContext context, {
    required String title,
    String initial = '',
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Live list of content-type tiles (Video, Repository, etc.) with item counts.
/// Only types that the user actually has classified items for are shown.
class _TypesSection extends ConsumerWidget {
  const _TypesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(libraryTypeCountsProvider);
    return counts.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('Could not load types: $error'),
      ),
      data: (counts) {
        if (counts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Text(
              'No classified items yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (typeString, count) in counts)
              _TypeTile(
                type: ContentType.fromString(typeString),
                count: count,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => LibrarySectionScreen(
                      title: ContentType.fromString(typeString).label,
                      provider: itemsByTypeProvider(typeString),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.type,
    required this.count,
    required this.onTap,
  });

  final ContentType type;
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(type.icon),
              const SizedBox(height: 8),
              Text(
                type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$count ${count == 1 ? 'item' : 'items'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CollectionTile extends ConsumerWidget {
  const _CollectionTile({
    required this.collection,
    required this.count,
    required this.onTap,
  });

  final Collection collection;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      onLongPress: () => _showMenu(context, ref),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              Icons.folder_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '$count ${count == 1 ? 'item' : 'items'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(collectionRepositoryProvider);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () => Navigator.of(sheetContext).pop('rename'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Delete collection',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (action == 'rename' && context.mounted) {
      final name = await _promptForName(
        context,
        title: 'Rename collection',
        initial: collection.name,
      );
      if (name != null && name.trim().isNotEmpty) {
        await repository.rename(collection.id, name);
      }
    } else if (action == 'delete' && context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Delete "${collection.name}"?'),
          content: const Text('Items stay in your library; only the collection is removed.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed == true) await repository.delete(collection.id);
    }
  }

  Future<String?> _promptForName(
    BuildContext context, {
    required String title,
    String initial = '',
  }) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../features/collections/presentation/collection_providers.dart';
import '../../features/inbox/presentation/inbox_providers.dart';
import '../models/item_status.dart';
import '../models/laterbox_item.dart';

/// Opens the modal action sheet for an item. Used by the item card (long
/// press) and the item detail screen. Every action writes to Drift first and
/// lets the streams update the UI; nothing here waits on the network.
Future<void> showItemActions(
  BuildContext context,
  WidgetRef ref,
  LaterBoxItem item,
) async {
  final repository = ref.read(itemRepositoryProvider);
  final itemId = item.id;

  final (statusLabel, statusIcon, statusAction) = switch (item.status) {
    ItemStatus.inbox => (
      'Keep',
      Icons.bookmark_add_outlined,
      () => repository.keep(itemId),
    ),
    ItemStatus.saved => (
      'Archive',
      Icons.archive_outlined,
      () => repository.archive(itemId),
    ),
    ItemStatus.archived => (
      'Unarchive',
      Icons.unarchive_outlined,
      () => repository.keep(itemId),
    ),
  };

  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.metadata?.title ?? item.title ?? item.url ?? 'Untitled',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  if (item.url != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.url!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(sheetContext).textTheme.bodySmall
                          ?.copyWith(
                            color: Theme.of(sheetContext)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            ListTile(
              leading: Icon(
                item.favorite
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
              ),
              title: Text(item.favorite ? 'Remove from Favorites' : 'Favorite'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                repository.setFavorite(itemId, !item.favorite);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded),
              title: const Text('Add to collection'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                showCollectionPicker(context, ref, itemId);
              },
            ),
            ListTile(
              leading: Icon(statusIcon),
              title: Text(statusLabel),
              onTap: () {
                Navigator.of(sheetContext).pop();
                statusAction();
              },
            ),
            if (item.url != null)
              ListTile(
                leading: const Icon(Icons.open_in_new_rounded),
                title: const Text('Open original'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  openOriginalForItem(context, item);
                },
              ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(sheetContext).colorScheme.error,
              ),
              title: Text(
                'Delete',
                style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
              ),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: sheetContext,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Delete this item?'),
                    content: const Text('It will be moved to trash.'),
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
                if (confirmed == true && sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                  repository.delete(itemId);
                }
              },
            ),
            const SizedBox(height: 8),
          ],
          ),
        ),
      );
    },
  );
}

/// Opens a link in the external browser.
Future<void> openOriginal(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme) return;
  final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!launched && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
  }
}

/// Opens the original page at the saved quote using the browser-native text
/// fragment feature (`#:~:text=...`). Chromium browsers scroll to and highlight
/// the matching text; other browsers ignore the fragment and open the page
/// normally.
String? buildTextFragmentUrl(LaterBoxItem item) {
  final url = item.url;
  final text = item.text?.trim();
  if (url == null || text == null || text.isEmpty) return null;

  final directive = <String>[
    if (item.selector.before case final before? when before.isNotEmpty)
      '${Uri.encodeComponent(before)}-',
    Uri.encodeComponent(text),
    if (item.selector.after case final after? when after.isNotEmpty)
      '-${Uri.encodeComponent(after)}',
  ].join(',');

  if (directive.length > 2000) return null;

  final base = url.split('#').first;
  return '$base#~:text=$directive';
}

Future<void> openOriginalForItem(BuildContext context, LaterBoxItem item) {
  final url = buildTextFragmentUrl(item) ?? item.url;
  if (url == null) return Future.value();
  return openOriginal(context, url);
}

/// Bottom sheet listing every collection with a checkbox reflecting whether
/// the item is already in it, plus a quick "new collection" entry.
Future<void> showCollectionPicker(
  BuildContext context,
  WidgetRef ref,
  String itemId,
) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CollectionPickerSheet(itemId: itemId),
  );
}

class _CollectionPickerSheet extends ConsumerWidget {
  const _CollectionPickerSheet({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);
    final membership = ref.watch(collectionsForItemProvider(itemId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Add to collection',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Flexible(
              child: collections.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                ),
                error: (error, stackTrace) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load collections: $error'),
                ),
                data: (collections) {
                  final memberIds = membership
                          .value
                          ?.map((collection) => collection.id)
                          .toSet() ??
                      <String>{};
                  if (collections.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No collections yet. Create one to get started.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final collection in collections)
                          CheckboxListTile(
                            value: memberIds.contains(collection.id),
                            title: Text(collection.name),
                            onChanged: (checked) {
                              final repository =
                                  ref.read(collectionRepositoryProvider);
                              repository.setItemMembership(
                                collection.id,
                                itemId,
                                checked ?? false,
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('New collection'),
              onTap: () => _createAndAdd(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createAndAdd(BuildContext context, WidgetRef ref) async {
    final name = await _promptForName(context);
    if (name == null || name.trim().isEmpty) return;
    final repository = ref.read(collectionRepositoryProvider);
    final id = await repository.create(name);
    await repository.addItem(id, itemId);
  }

  Future<String?> _promptForName(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New collection'),
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
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

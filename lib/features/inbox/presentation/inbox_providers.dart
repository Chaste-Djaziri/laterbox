import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../shared/models/laterbox_item.dart';
import '../../enrichment/domain/content_type.dart';
import '../data/item_repository.dart';

enum InboxFilterType {
  all('All', Icons.all_inbox_rounded),
  articles('Articles', Icons.article_rounded),
  videos('Videos', Icons.play_circle_rounded),
  audio('Audio', Icons.headphones_rounded),
  images('Images', Icons.image_rounded),
  notes('Notes', Icons.note_alt_rounded),
  starred('Starred', Icons.star_rounded);

  const InboxFilterType(this.label, this.icon);
  final String label;
  final IconData icon;
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return ItemRepository(
    ref.watch(localItemDataSourceProvider),
    userId: ref.watch(activeUserIdProvider),
    onSaved: () async => coordinator.requestSync(),
  );
});

final inboxItemsProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchInboxItems();
});

final inboxFilterProvider =
    StateProvider<InboxFilterType>((ref) => InboxFilterType.all);

final filteredInboxItemsProvider =
    Provider<AsyncValue<List<LaterBoxItem>>>((ref) {
  final itemsAsync = ref.watch(inboxItemsProvider);
  final filter = ref.watch(inboxFilterProvider);

  return itemsAsync.whenData((items) {
    if (filter == InboxFilterType.all) return items;

    return items.where((item) {
      switch (filter) {
        case InboxFilterType.starred:
          return item.isFavorite;
        case InboxFilterType.notes:
          return item.url == null ||
              (item.text != null && item.text!.isNotEmpty) ||
              item.metadata?.classification?.type == ContentType.note;
        case InboxFilterType.articles:
          return item.metadata?.classification?.type == ContentType.article;
        case InboxFilterType.videos:
          return item.metadata?.classification?.type == ContentType.video;
        case InboxFilterType.audio:
          return item.metadata?.classification?.type == ContentType.audio;
        case InboxFilterType.images:
          return item.metadata?.classification?.type == ContentType.image;
        case InboxFilterType.all:
          return true;
      }
    }).toList();
  });
});

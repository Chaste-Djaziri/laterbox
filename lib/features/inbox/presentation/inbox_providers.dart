import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../shared/models/laterbox_item.dart';
import '../../enrichment/domain/content_type.dart';
import '../data/item_repository.dart';
import '../../scheduling/presentation/schedule_providers.dart';

enum InboxFilterType {
  all('All', Icons.all_inbox_rounded),
  starred('Starred', Icons.star_rounded),
  videos('Videos', Icons.play_circle_rounded),
  notes('Notes', Icons.note_alt_rounded),
  products('Products', Icons.shopping_bag_outlined),
  articles('Articles', Icons.article_rounded),
  music('Music', Icons.music_note_rounded),
  code('Code', Icons.code_rounded),
  places('Places', Icons.place_outlined),
  books('Books', Icons.menu_book_rounded),
  files('Files', Icons.attach_file_rounded),
  links('Links', Icons.link_rounded);

  const InboxFilterType(this.label, this.icon);
  final String label;
  final IconData icon;

  bool matches(LaterBoxItem item) {
    switch (this) {
      case InboxFilterType.all:
        return true;
      case InboxFilterType.starred:
        return item.favorite;
      case InboxFilterType.videos:
        final t = item.type.toLowerCase();
        final ct = item.metadata?.classification?.type;
        return ct == ContentType.video || t == 'video';
      case InboxFilterType.notes:
        final t = item.type.toLowerCase();
        final hasNoUrl = item.url == null || item.url!.trim().isEmpty;
        final hasText = item.text != null && item.text!.trim().isNotEmpty;
        return t == 'note' || (hasNoUrl && hasText);
      case InboxFilterType.products:
        final t = item.type.toLowerCase();
        final ct = item.metadata?.classification?.type;
        return ct == ContentType.product || t == 'product';
      case InboxFilterType.articles:
        final t = item.type.toLowerCase();
        final ct = item.metadata?.classification?.type;
        return ct == ContentType.article || t == 'article';
      case InboxFilterType.music:
        final t = item.type.toLowerCase();
        final ct = item.metadata?.classification?.type;
        return ct == ContentType.music || t == 'music' || t == 'audio';
      case InboxFilterType.code:
        final t = item.type.toLowerCase();
        final ct = item.metadata?.classification?.type;
        return ct == ContentType.repository || t == 'repository' || t == 'code';
      case InboxFilterType.places:
        final t = item.type.toLowerCase();
        final ct = item.metadata?.classification?.type;
        return ct == ContentType.place || t == 'place';
      case InboxFilterType.books:
        final t = item.type.toLowerCase();
        final ct = item.metadata?.classification?.type;
        return ct == ContentType.book || t == 'book';
      case InboxFilterType.files:
        final t = item.type.toLowerCase();
        final ct = item.metadata?.classification?.type;
        return ct == ContentType.file ||
            t == 'file' ||
            t == 'document' ||
            t == 'pdf';
      case InboxFilterType.links:
        final t = item.type.toLowerCase();
        final ct = item.metadata?.classification?.type;
        final hasUrl = item.url != null && item.url!.trim().isNotEmpty;
        return ct == ContentType.link || t == 'link' || (hasUrl && ct == null);
    }
  }
}

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return ItemRepository(
    ref.watch(localItemDataSourceProvider),
    userId: ref.watch(activeUserIdProvider),
    onSaved: () async => coordinator.requestSync(),
  );
});

List<LaterBoxItem> deduplicateInboxItems(List<LaterBoxItem> items) {
  final seenIds = <String>{};
  final seenKeys = <String>{};
  final result = <LaterBoxItem>[];

  for (final item in items) {
    if (!seenIds.add(item.id)) continue;
    final key = item.url != null && item.url!.isNotEmpty
        ? 'url:${item.url}'
        : (item.text != null && item.text!.isNotEmpty
              ? 'text:${item.text}'
              : null);
    if (key != null && !seenKeys.add(key)) continue;
    result.add(item);
  }
  return result;
}

final inboxItemsProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  final now =
      ref.watch(scheduleClockProvider).valueOrNull ??
      ref.watch(scheduleNowProvider)();
  return ref.watch(itemRepositoryProvider).watchInboxItems().map((items) {
    final due = deduplicateInboxItems(
      items.where((item) => item.isDue(now)).toList(),
    );
    due.sort((a, b) {
      final aDate = a.returnAt ?? a.createdAt;
      final bDate = b.returnAt ?? b.createdAt;
      final cmp = aDate.compareTo(bDate);
      if (cmp != 0) return cmp;
      return a.createdAt.compareTo(b.createdAt);
    });
    return due;
  });
});

final starredItemsProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchFavorites();
});

final keptItemsProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchKeptItems();
});

final archivedItemsProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchArchived();
});

final inboxSearchQueryProvider = StateProvider<String>((ref) => '');
final inboxSortOrderProvider = StateProvider<String>((ref) => 'fifo');

final inboxFilterProvider = StateProvider<InboxFilterType>(
  (ref) => InboxFilterType.all,
);

final filteredInboxItemsProvider = Provider<AsyncValue<List<LaterBoxItem>>>((
  ref,
) {
  final itemsAsync = ref.watch(inboxItemsProvider);
  final filter = ref.watch(inboxFilterProvider);
  final searchQuery = ref.watch(inboxSearchQueryProvider).trim().toLowerCase();

  return itemsAsync.whenData((items) {
    var result = filter == InboxFilterType.all
        ? items
        : items.where(filter.matches).toList();

    if (searchQuery.isNotEmpty) {
      result = result.where((item) {
        final title = (item.title ?? '').toLowerCase();
        final url = (item.url ?? '').toLowerCase();
        final text = (item.text ?? '').toLowerCase();
        final domain = (item.metadata?.domain ?? '').toLowerCase();
        final desc = (item.metadata?.description ?? '').toLowerCase();
        final tags =
            (item.metadata?.classification?.structuredData?['tags'] as List?)
                ?.map((e) => e.toString().toLowerCase())
                .join(' ') ??
            '';
        return title.contains(searchQuery) ||
            url.contains(searchQuery) ||
            text.contains(searchQuery) ||
            domain.contains(searchQuery) ||
            desc.contains(searchQuery) ||
            tags.contains(searchQuery);
      }).toList();
    }

    // First-come, first-served (FIFO) by arrival date (returnAt ?? createdAt)
    result.sort((a, b) {
      final aDate = a.returnAt ?? a.createdAt;
      final bDate = b.returnAt ?? b.createdAt;
      final cmp = aDate.compareTo(bDate);
      if (cmp != 0) return cmp;
      return a.createdAt.compareTo(b.createdAt);
    });

    return result;
  });
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/database/database_providers.dart';
import '../../../shared/models/laterbox_item.dart';
import '../../inbox/presentation/inbox_providers.dart';

/// Every saved item (including archived), newest first. Used by the Library
/// tab and the Search screen's recent list.
final allItemsProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchAllItems();
});

/// Non-deleted favorites, newest first.
final favoritesProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchFavorites();
});

/// Non-deleted kept items (status == 'saved'), newest first.
final keptProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchKeptItems();
});

/// Non-deleted archived items, newest first.
final archivedProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchArchived();
});

/// Live (content_type, count) for the current user's classified items.
final libraryTypeCountsProvider =
    StreamProvider<List<(String, int)>>((ref) {
  final userId = ref.watch(activeUserIdProvider);
  return ref.watch(localItemDataSourceProvider).watchTypeCounts(userId);
});

/// Items of a given content type, newest first.
final itemsByTypeProvider =
    StreamProvider.family<List<LaterBoxItem>, String>((ref, type) {
  final userId = ref.watch(activeUserIdProvider);
  return ref
      .watch(localItemDataSourceProvider)
      .watchItemsByType(userId, type)
      .map((rows) => rows
          .map((row) => LaterBoxItem.fromDriftRows(row.$1, row.$2))
          .toList());
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../shared/models/laterbox_item.dart';
import '../data/collection_repository.dart';

final collectionRepositoryProvider = Provider<CollectionRepository>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return CollectionRepository(
    ref.watch(localCollectionDataSourceProvider),
    userId: ref.watch(activeUserIdProvider),
    onChanged: () async => coordinator.requestSync(),
  );
});

/// Non-deleted collections, oldest first.
final collectionsProvider = StreamProvider<List<Collection>>((ref) {
  return ref
      .watch(localCollectionDataSourceProvider)
      .watchCollections(ref.watch(activeUserIdProvider));
});

/// Collections with their current (non-deleted) item counts.
final collectionCountsProvider = StreamProvider<List<(Collection, int)>>(
  (ref) {
    return ref
        .watch(localCollectionDataSourceProvider)
        .watchCollectionCounts(ref.watch(activeUserIdProvider));
  },
);

/// Collections a given item currently belongs to.
final collectionsForItemProvider =
    StreamProvider.family<List<Collection>, String>((ref, itemId) {
  return ref
      .watch(localCollectionDataSourceProvider)
      .watchCollectionsForItem(itemId, ref.watch(activeUserIdProvider));
});

/// Live items inside a single collection, most recently added first.
final collectionItemsProvider =
    StreamProvider.family<List<LaterBoxItem>, String>((ref, collectionId) {
  final dataSource = ref.watch(localCollectionDataSourceProvider);
  final userId = ref.watch(activeUserIdProvider);
  return dataSource.watchItemsInCollection(collectionId, userId).map(
    (rows) => rows
        .map((row) => LaterBoxItem.fromDriftRows(row.$1, row.$2))
        .toList(),
  );
});
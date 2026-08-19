import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'remote_collection_data_source.dart';

class LocalCollectionDataSource {
  const LocalCollectionDataSource(this._database);

  final AppDatabase _database;

  Stream<List<Collection>> watchCollections(String? userId) {
    return _database.watchCollections(userId);
  }

  Stream<List<Collection>> watchCollectionsForItem(
    String itemId,
    String? userId,
  ) {
    return _database.watchCollectionsForItem(itemId, userId);
  }

  Stream<List<(Collection, int)>> watchCollectionCounts(String? userId) {
    return _database.watchCollectionCounts(userId);
  }

  Stream<List<(Item, ItemMetadataData?)>> watchItemsInCollection(
    String collectionId,
    String? userId,
  ) {
    return _database.watchItemsInCollection(collectionId, userId);
  }

  Future<void> create(String id, String? userId, String name) {
    return _database.createCollection(id, userId, name);
  }

  Future<void> rename(String id, String name) {
    return _database.renameCollection(id, name);
  }

  Future<void> delete(String id) {
    return _database.softDeleteCollection(id);
  }

  Future<void> addItem(String collectionId, String itemId) {
    return _database.addItemToCollection(collectionId, itemId);
  }

  Future<void> removeItem(String collectionId, String itemId) {
    return _database.removeItemFromCollection(collectionId, itemId);
  }

  Future<List<Collection>> collectionsNeedingSync(String userId) {
    return _database.collectionsNeedingSync(userId);
  }

  Future<List<CollectionItem>> collectionItemsNeedingSync(String userId) {
    return _database.collectionItemsNeedingSync(userId);
  }

  Future<void> markCollectionSynced(String id, DateTime syncedAt) {
    return _database.markCollectionSynced(id, syncedAt);
  }

  Future<void> markCollectionFailed(String id) {
    return _database.markCollectionFailed(id);
  }

  Future<void> markCollectionItemSynced(
    String collectionId,
    String itemId,
    DateTime syncedAt,
  ) {
    return _database.markCollectionItemSynced(collectionId, itemId, syncedAt);
  }

  Future<void> markCollectionItemFailed(String collectionId, String itemId) {
    return _database.markCollectionItemFailed(collectionId, itemId);
  }

  Future<Collection?> collectionById(String id) {
    return _database.collectionById(id);
  }

  Future<CollectionItem?> collectionItemById(
    String collectionId,
    String itemId,
  ) {
    return _database.collectionItemById(collectionId, itemId);
  }

  /// Applies a remote collection when it is at least as new as the local copy.
  /// Returns true when the local row changed.
  Future<bool> applyRemoteCollection(
    RemoteCollection remote,
    DateTime syncedAt,
  ) async {
    final local = await _database.collectionById(remote.id);
    if (local != null && local.updatedAt.isAfter(remote.updatedAt)) {
      return false;
    }

    await _database.upsertRemoteCollection(
      CollectionsCompanion.insert(
        id: remote.id,
        userId: Value(remote.userId),
        name: remote.name,
        createdAt: remote.createdAt,
        updatedAt: remote.updatedAt,
        deletedAt: Value(remote.deletedAt),
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(syncedAt),
      ),
    );
    return true;
  }

  /// Applies a remote membership when it is at least as new as the local copy.
  /// Returns true when the local row changed.
  Future<bool> applyRemoteCollectionItem(
    RemoteCollectionItem remote,
    DateTime syncedAt,
  ) async {
    final local =
        await _database.collectionItemById(remote.collectionId, remote.itemId);
    if (local != null && local.updatedAt.isAfter(remote.updatedAt)) {
      return false;
    }

    await _database.upsertRemoteCollectionItem(
      CollectionItemsCompanion.insert(
        collectionId: remote.collectionId,
        itemId: remote.itemId,
        userId: Value(remote.userId),
        createdAt: remote.createdAt,
        updatedAt: remote.updatedAt,
        deletedAt: Value(remote.deletedAt),
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(syncedAt),
      ),
    );
    return true;
  }
}
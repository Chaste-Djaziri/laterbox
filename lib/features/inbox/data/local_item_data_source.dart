import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'remote_item_data_source.dart';

class LocalItemDataSource {
  const LocalItemDataSource(this._database);

  final AppDatabase _database;

  Stream<List<Item>> watchInboxItems(String? userId) {
    return _database.watchInboxItems(userId);
  }

  Stream<List<(Item, ItemMetadataData?)>> watchInboxItemsWithMetadata(
    String? userId,
  ) {
    return _database.watchInboxItemsWithMetadata(userId);
  }

  Stream<List<(Item, ItemMetadataData?)>> watchAllItemsWithMetadata(
    String? userId,
  ) {
    return _database.watchAllItemsWithMetadata(userId);
  }

  Stream<List<(Item, ItemMetadataData?, ItemNote?)>> searchItemsWithMetadata(
    String? userId,
    String query, {
    String? contentType,
  }) {
    return _database.searchItems(
      userId,
      query,
      contentType: contentType,
    );
  }

  Stream<(Item, ItemMetadataData?)?> watchItemWithMetadata(String id) {
    return _database.watchItemWithMetadata(id);
  }

  Future<void> insert(ItemsCompanion item) => _database.saveItem(item);

  Future<bool> exists(String id) async => (await _database.itemById(id)) != null;

  Future<Item?> findActiveInboxItem(
    String? userId, {
    String? url,
    String? textContent,
  }) {
    return _database.findActiveInboxItem(
      userId,
      url: url,
      textContent: textContent,
    );
  }

  Future<List<Item>> itemsNeedingSync(String userId) {
    return _database.itemsNeedingSync(userId);
  }

  Future<void> markSynced(String id, DateTime syncedAt) {
    return _database.markSynced(id, syncedAt);
  }

  Future<void> markFailed(String id) => _database.markFailed(id);

  Future<bool> applyRemote(RemoteItem remote, DateTime syncedAt) async {
    final local = await _database.itemById(remote.id);
    if (local != null && local.updatedAt.isAfter(remote.updatedAt)) {
      return false;
    }

    await _database.upsertRemoteItem(
      ItemsCompanion.insert(
        id: remote.id,
        userId: Value(remote.userId),
        url: Value(remote.url),
        title: Value(remote.title),
        textContent: Value(remote.textContent),
        textSelector: Value(remote.textSelector),
        type: Value(remote.type),
        favorite: Value(remote.favorite),
        status: Value(remote.status),
        createdAt: remote.createdAt,
        updatedAt: remote.updatedAt,
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(syncedAt),
        deletedAt: Value(remote.deletedAt),
      ),
    );
    return true;
  }

  Stream<List<(Item, ItemMetadataData?)>> watchItemsWithStatus(
    String? userId,
    String status,
  ) {
    return _database.watchItemsWithStatus(userId, status);
  }

  Stream<List<(Item, ItemMetadataData?)>> watchFavoriteItemsWithMetadata(
    String? userId,
  ) {
    return _database.watchFavoriteItemsWithMetadata(userId);
  }

  Stream<List<(String, int)>> watchTypeCounts(String? userId) {
    return _database.watchTypeCounts(userId);
  }

  Stream<List<(Item, ItemMetadataData?)>> watchItemsByType(
    String? userId,
    String type,
  ) {
    return _database.watchItemsByType(userId, type);
  }

  Future<void> updateStatus(String id, String status) {
    return _database.updateItemStatus(id, status);
  }

  Future<void> updateFavorite(String id, bool favorite) {
    return _database.updateItemFavorite(id, favorite);
  }

  Future<void> softDelete(String id) {
    return _database.softDeleteItem(id);
  }
}

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'remote_item_data_source.dart';

class LocalItemDataSource {
  const LocalItemDataSource(this._database);

  final AppDatabase _database;

  Stream<List<Item>> watchInboxItems() => _database.watchInboxItems();

  Future<void> insert(ItemsCompanion item) => _database.saveItem(item);

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
        type: Value(remote.type),
        favorite: Value(remote.favorite),
        archived: Value(remote.archived),
        createdAt: remote.createdAt,
        updatedAt: remote.updatedAt,
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(syncedAt),
        deletedAt: Value(remote.deletedAt),
      ),
    );
    return true;
  }
}

import '../../../core/database/app_database.dart';

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
}
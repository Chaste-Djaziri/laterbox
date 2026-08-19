import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'remote_item_note_data_source.dart';

class LocalItemNoteDataSource {
  const LocalItemNoteDataSource(this._database);

  final AppDatabase _database;

  Stream<ItemNote?> watchNote(String itemId, String? userId) {
    return _database.watchNote(itemId, userId);
  }

  Future<ItemNote?> noteById(String itemId) {
    return _database.noteById(itemId);
  }

  Future<void> save(String itemId, String? userId, String content) {
    return _database.saveNote(itemId, userId, content);
  }

  Future<void> delete(String itemId) {
    return _database.deleteNote(itemId);
  }

  Future<List<ItemNote>> notesNeedingSync(String userId) {
    return _database.notesNeedingSync(userId);
  }

  Future<void> markSynced(String itemId, DateTime syncedAt) {
    return _database.markNoteSynced(itemId, syncedAt);
  }

  Future<void> markFailed(String itemId) {
    return _database.markNoteFailed(itemId);
  }

  /// Applies a remote note when it is at least as new as the local copy.
  /// Returns true when the local row changed.
  Future<bool> applyRemoteNote(RemoteItemNote remote, DateTime syncedAt) async {
    final local = await _database.noteById(remote.itemId);
    if (local != null && local.updatedAt.isAfter(remote.updatedAt)) {
      return false;
    }

    await _database.upsertRemoteNote(
      ItemNotesCompanion.insert(
        itemId: remote.itemId,
        userId: Value(remote.userId),
        content: remote.content,
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
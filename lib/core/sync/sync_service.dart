import '../../features/collections/data/local_collection_data_source.dart';
import '../../features/collections/data/remote_collection_data_source.dart';
import '../../features/attachments/domain/attachment_sync_service.dart';
import '../../features/enrichment/data/local_metadata_data_source.dart';
import '../../features/enrichment/data/remote_metadata_data_source.dart';
import '../../features/inbox/data/local_item_data_source.dart';
import '../../features/inbox/data/remote_item_data_source.dart';
import '../../features/notes/data/local_item_note_data_source.dart';
import '../../features/notes/data/remote_item_note_data_source.dart';
import '../database/app_database.dart';
import 'sync_result.dart';

class SyncService {
  factory SyncService({
    required LocalItemDataSource local,
    required RemoteItemDataSource? remote,
    required String? Function() currentUserId,
    LocalMetadataDataSource? localMetadata,
    RemoteMetadataDataSource? remoteMetadata,
    LocalCollectionDataSource? localCollections,
    RemoteCollectionDataSource? remoteCollections,
    LocalItemNoteDataSource? localNotes,
    RemoteItemNoteDataSource? remoteNotes,
    Future<AttachmentSyncService?> Function()? attachmentSync,
  }) => SyncService._(
    local,
    remote,
    currentUserId,
    localMetadata,
    remoteMetadata,
    localCollections,
    remoteCollections,
    localNotes,
    remoteNotes,
    attachmentSync,
  );

  SyncService._(
    this._local,
    this._remote,
    this._currentUserId,
    this._localMetadata,
    this._remoteMetadata,
    this._localCollections,
    this._remoteCollections,
    this._localNotes,
    this._remoteNotes,
    this._attachmentSync,
  );

  final LocalItemDataSource _local;
  final RemoteItemDataSource? _remote;
  final String? Function() _currentUserId;
  final LocalMetadataDataSource? _localMetadata;
  final RemoteMetadataDataSource? _remoteMetadata;
  final LocalCollectionDataSource? _localCollections;
  final RemoteCollectionDataSource? _remoteCollections;
  final LocalItemNoteDataSource? _localNotes;
  final RemoteItemNoteDataSource? _remoteNotes;
  final Future<AttachmentSyncService?> Function()? _attachmentSync;
  Future<SyncResult>? _activeSync;
  int _pushed = 0;
  int _pulled = 0;
  int _failed = 0;

  Future<SyncResult> sync() {
    return _activeSync ??= _run().whenComplete(() => _activeSync = null);
  }

  Future<SyncResult> _run() async {
    final userId = _currentUserId();
    final remote = _remote;
    if (userId == null || remote == null) return const SyncResult.skipped();

    _pushed = 0;
    _pulled = 0;
    _failed = 0;
    final syncedAt = DateTime.now().toUtc();

    try {
      final remoteItems = await remote.fetchItems(userId);
      for (final item in remoteItems) {
        if (await _local.applyRemote(item, syncedAt)) _pulled++;
      }
    } catch (_) {
      return const SyncResult(pushed: 0, pulled: 0, failed: 1);
    }

    final attachmentSync = await _attachmentSync?.call();
    if (attachmentSync != null) {
      final result = await attachmentSync.sync(userId);
      _pushed += result.pushed;
      _pulled += result.pulled;
      _failed += result.failed;
    }

    final pendingItems = await _local.itemsNeedingSync(userId);
    for (final item in pendingItems) {
      try {
        await remote.upsertItem(item);
        await _local.markSynced(item.id, syncedAt);
        _pushed++;
      } catch (_) {
        await _local.markFailed(item.id);
        _failed++;
      }
    }

    final localMetadata = _localMetadata;
    final remoteMetadata = _remoteMetadata;
    if (localMetadata != null && remoteMetadata != null) {
      try {
        final remoteRows = await remoteMetadata.fetchMetadata(userId);
        for (final row in remoteRows) {
          if (await localMetadata.applyRemoteMetadata(row, syncedAt)) _pulled++;
        }
      } catch (_) {
        _failed++;
      }

      final pendingMetadata = await localMetadata.metadataNeedingSync(userId);
      for (final metadata in pendingMetadata) {
        try {
          await remoteMetadata.upsertMetadata(metadata);
          _pushed++;
        } catch (_) {
          _failed++;
        }
      }
    }

    await _syncCollections(userId);
    await _syncNotes(userId);

    return SyncResult(pushed: _pushed, pulled: _pulled, failed: _failed);
  }

  Future<void> _syncNotes(String userId) async {
    final local = _localNotes;
    final remote = _remoteNotes;
    if (local == null || remote == null) return;
    await _syncEntity(
      fetchRemote: () => remote.fetchNotes(userId),
      applyRemote: (RemoteItemNote row, syncedAt) =>
          local.applyRemoteNote(row, syncedAt),
      needingSync: () => local.notesNeedingSync(userId),
      upsert: (ItemNote row) => remote.upsertNote(row),
      markSynced: (row, syncedAt) => local.markSynced(row.itemId, syncedAt),
      markFailed: (row) => local.markFailed(row.itemId),
    );
  }

  Future<void> _syncCollections(String userId) async {
    final local = _localCollections;
    final remote = _remoteCollections;
    if (local == null || remote == null) return;
    await _syncEntity(
      fetchRemote: () => remote.fetchCollections(userId),
      applyRemote: (RemoteCollection row, syncedAt) =>
          local.applyRemoteCollection(row, syncedAt),
      needingSync: () => local.collectionsNeedingSync(userId),
      upsert: (Collection row) => remote.upsertCollection(row),
      markSynced: (row, syncedAt) =>
          local.markCollectionSynced(row.id, syncedAt),
      markFailed: (row) => local.markCollectionFailed(row.id),
    );
    await _syncEntity(
      fetchRemote: () => remote.fetchCollectionItems(userId),
      applyRemote: (RemoteCollectionItem row, syncedAt) =>
          local.applyRemoteCollectionItem(row, syncedAt),
      needingSync: () => local.collectionItemsNeedingSync(userId),
      upsert: (CollectionItem row) => remote.upsertCollectionItem(row),
      markSynced: (row, syncedAt) => local.markCollectionItemSynced(
        row.collectionId,
        row.itemId,
        syncedAt,
      ),
      markFailed: (row) =>
          local.markCollectionItemFailed(row.collectionId, row.itemId),
    );
  }

  Future<void> _syncEntity<TRemote, TLocal>({
    required Future<List<TRemote>> Function() fetchRemote,
    required Future<bool> Function(TRemote row, DateTime syncedAt) applyRemote,
    required Future<List<TLocal>> Function() needingSync,
    required Future<void> Function(TLocal row) upsert,
    required Future<void> Function(TLocal row, DateTime syncedAt) markSynced,
    required Future<void> Function(TLocal row) markFailed,
  }) async {
    final syncedAt = DateTime.now().toUtc();
    try {
      final remoteRows = await fetchRemote();
      for (final row in remoteRows) {
        if (await applyRemote(row, syncedAt)) _pulled++;
      }
    } catch (_) {
      _failed++;
    }

    final pending = await needingSync();
    for (final row in pending) {
      try {
        await upsert(row);
        await markSynced(row, syncedAt);
        _pushed++;
      } catch (_) {
        await markFailed(row);
        _failed++;
      }
    }
  }
}

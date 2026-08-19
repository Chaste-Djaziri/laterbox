import '../../features/enrichment/data/local_metadata_data_source.dart';
import '../../features/enrichment/data/remote_metadata_data_source.dart';
import '../../features/inbox/data/local_item_data_source.dart';
import '../../features/inbox/data/remote_item_data_source.dart';
import 'sync_result.dart';

class SyncService {
  factory SyncService({
    required LocalItemDataSource local,
    required RemoteItemDataSource? remote,
    required String? Function() currentUserId,
    LocalMetadataDataSource? localMetadata,
    RemoteMetadataDataSource? remoteMetadata,
  }) => SyncService._(
    local,
    remote,
    currentUserId,
    localMetadata,
    remoteMetadata,
  );

  SyncService._(
    this._local,
    this._remote,
    this._currentUserId,
    this._localMetadata,
    this._remoteMetadata,
  );

  final LocalItemDataSource _local;
  final RemoteItemDataSource? _remote;
  final String? Function() _currentUserId;
  final LocalMetadataDataSource? _localMetadata;
  final RemoteMetadataDataSource? _remoteMetadata;
  Future<SyncResult>? _activeSync;

  Future<SyncResult> sync() {
    return _activeSync ??= _run().whenComplete(() => _activeSync = null);
  }

  Future<SyncResult> _run() async {
    final userId = _currentUserId();
    final remote = _remote;
    if (userId == null || remote == null) return const SyncResult.skipped();

    var pulled = 0;
    var pushed = 0;
    var failed = 0;
    final syncedAt = DateTime.now().toUtc();

    try {
      final remoteItems = await remote.fetchItems(userId);
      for (final item in remoteItems) {
        if (await _local.applyRemote(item, syncedAt)) pulled++;
      }
    } catch (_) {
      return const SyncResult(pushed: 0, pulled: 0, failed: 1);
    }

    final pendingItems = await _local.itemsNeedingSync(userId);
    for (final item in pendingItems) {
      try {
        await remote.upsertItem(item);
        await _local.markSynced(item.id, syncedAt);
        pushed++;
      } catch (_) {
        await _local.markFailed(item.id);
        failed++;
      }
    }

    final localMetadata = _localMetadata;
    final remoteMetadata = _remoteMetadata;
    if (localMetadata != null && remoteMetadata != null) {
      try {
        final remoteRows = await remoteMetadata.fetchMetadata(userId);
        for (final row in remoteRows) {
          if (await localMetadata.applyRemoteMetadata(row, syncedAt)) pulled++;
        }
      } catch (_) {
        failed++;
      }

      final pendingMetadata = await localMetadata.metadataNeedingSync(userId);
      for (final metadata in pendingMetadata) {
        try {
          await remoteMetadata.upsertMetadata(metadata);
          pushed++;
        } catch (_) {
          failed++;
        }
      }
    }

    return SyncResult(pushed: pushed, pulled: pulled, failed: failed);
  }
}
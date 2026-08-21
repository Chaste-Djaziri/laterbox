import '../../../core/database/app_database.dart';
import '../data/attachment_storage.dart';
import '../data/attachment_storage_api.dart';
import '../data/remote_attachment_data_source.dart';

class AttachmentSyncResult {
  const AttachmentSyncResult({
    required this.uploaded,
    required this.pushed,
    required this.pulled,
    required this.failed,
  });

  final int uploaded;
  final int pushed;
  final int pulled;
  final int failed;
}

class AttachmentSyncService {
  const AttachmentSyncService(
    this._database,
    this._remote,
    this._storageApi,
    this._storage,
  );

  final AppDatabase _database;
  final RemoteAttachmentDataSource _remote;
  final AttachmentStorageApi _storageApi;
  final AttachmentStorage? _storage;

  Future<AttachmentSyncResult> sync(String userId) async {
    var uploaded = 0;
    var pushed = 0;
    var pulled = 0;
    var failed = 0;
    final syncedAt = DateTime.now().toUtc();

    try {
      final remoteRows = await _remote.fetchAttachments(userId);
      for (final row in remoteRows) {
        await _database.upsertRemoteAttachment(row.toLocalCompanion(syncedAt));
        pulled++;
      }
    } catch (_) {
      failed++;
    }

    final uploads = await _database.attachmentsNeedingUpload(userId);
    for (final attachment in uploads) {
      final storage = _storage;
      final localPath = attachment.localPath;
      final localBytes = attachment.localBytes;
      if (localPath == null && localBytes == null) continue;
      try {
        await _database.markAttachmentUploading(attachment.id);
        final objectKey = localBytes != null
            ? await _storageApi.uploadBytes(attachment, localBytes)
            : await _storageApi.upload(
                attachment,
                storage!.resolveLocalPath(localPath!),
              );
        await _database.markAttachmentUploaded(attachment.id, objectKey, userId);
        uploaded++;
      } catch (error) {
        await _database.markAttachmentUploadFailed(
          attachment.id,
          _safeError(error),
        );
        failed++;
      }
    }

    final pending = await _database.attachmentsNeedingSync(userId);
    for (final attachment in pending) {
      try {
        await _remote.upsertAttachment(attachment);
        if (attachment.deletedAt != null && attachment.r2ObjectKey != null) {
          await _storageApi.delete(attachment.id);
        }
        await _database.markAttachmentSynced(attachment.id, syncedAt);
        pushed++;
      } catch (_) {
        await _database.markAttachmentSyncFailed(attachment.id);
        failed++;
      }
    }

    return AttachmentSyncResult(
      uploaded: uploaded,
      pushed: pushed,
      pulled: pulled,
      failed: failed,
    );
  }

  Future<String> download(Attachment attachment) async {
    final storage = _storage;
    if (storage == null) {
      throw UnsupportedError('Local attachment downloads are unavailable.');
    }
    final localPath = attachment.localPath;
    if (localPath != null) return storage.resolveLocalPath(localPath);
    try {
      await _database.markAttachmentDownloading(attachment.id);
      final downloadedPath = await _storageApi.download(attachment, storage);
      await _database.markAttachmentDownloaded(attachment.id, downloadedPath);
      return storage.resolveLocalPath(downloadedPath);
    } catch (_) {
      await _database.markAttachmentDownloadFailed(attachment.id);
      rethrow;
    }
  }

  String _safeError(Object error) {
    final value = error.toString();
    return value.length <= 500 ? value : value.substring(0, 500);
  }
}

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import 'attachment_storage.dart';

class AttachmentRepository {
  const AttachmentRepository(this._database, this._storage);

  final AppDatabase _database;
  final AttachmentStorage _storage;

  Future<void> saveItemWithAttachments({
    required String itemId,
    required String? userId,
    required String title,
    required String? textContent,
    required DateTime createdAt,
    required List<StoredAttachment> attachments,
  }) {
    return _database.saveItemWithAttachments(
      ItemsCompanion.insert(
        id: itemId,
        userId: Value(userId),
        title: Value(title),
        textContent: Value(textContent),
        type: const Value('file'),
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
      attachments
          .map(
            (attachment) => AttachmentsCompanion.insert(
              id: attachment.id,
              itemId: itemId,
              userId: Value(userId),
              originalFileName: attachment.validation.originalFileName,
              fileExtension: attachment.validation.fileExtension,
              mimeType: attachment.validation.mimeType,
              byteSize: attachment.validation.byteSize,
              sha256: attachment.sha256,
              localPath: attachment.localPath,
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          )
          .toList(),
    );
  }

  Stream<List<Attachment>> watchForItem(String itemId, String? userId) {
    return _database.watchAttachmentsForItem(itemId, userId);
  }

  Future<List<String>?> existingAttachmentIds(String itemId) async {
    if (await _database.itemById(itemId) == null) return null;
    final rows = await _database.attachmentsForItem(itemId);
    return rows.map((attachment) => attachment.id).toList();
  }

  Future<void> removeOrphans() async {
    await _storage.removeOrphans(await _database.attachmentIds());
  }
}

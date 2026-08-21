import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as path;

import '../../../core/database/app_database.dart';
import '../data/attachment_file_picker.dart';
import 'attachment_file_policy.dart';
import 'attachment_import_result.dart';

class WebAttachmentImportService {
  const WebAttachmentImportService({
    required AppDatabase database,
    required AttachmentFilePolicy policy,
    required String? Function() currentUserId,
    required String Function() newId,
    required DateTime Function() now,
    Future<void> Function()? onSaved,
  }) : this._(database, policy, currentUserId, newId, now, onSaved);

  const WebAttachmentImportService._(
    this._database,
    this._policy,
    this._currentUserId,
    this._newId,
    this._now,
    this._onSaved,
  );

  final AppDatabase _database;
  final AttachmentFilePolicy _policy;
  final String? Function() _currentUserId;
  final String Function() _newId;
  final DateTime Function() _now;
  final Future<void> Function()? _onSaved;

  Future<AttachmentImportResult> importFiles({
    required List<PickedAttachmentFile> files,
    String? text,
  }) async {
    final attachments = <AttachmentsCompanion>[];
    final attachmentIds = <String>[];
    final failures = <AttachmentImportFailure>[];
    final createdAt = _now();
    final userId = _currentUserId();

    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null) {
        failures.add(
          AttachmentImportFailure(
            displayName: file.name,
            sourcePath: file.name,
            code: AttachmentImportFailureCode.unreadable,
            details: 'The browser did not provide the selected file bytes.',
          ),
        );
        continue;
      }
      try {
        final validation = await _policy.validateBytes(file.name, bytes);
        final id = _newId();
        attachmentIds.add(id);
        attachments.add(
          AttachmentsCompanion.insert(
            id: id,
            itemId: '',
            userId: Value(userId),
            originalFileName: validation.originalFileName,
            fileExtension: validation.fileExtension,
            mimeType: validation.mimeType,
            byteSize: validation.byteSize,
            sha256: sha256.convert(bytes).toString(),
            localBytes: Value(bytes),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
      } on AttachmentValidationException catch (error) {
        failures.add(
          AttachmentImportFailure(
            displayName: file.name,
            sourcePath: file.name,
            code: error.code,
            details: error.details,
          ),
        );
      }
    }

    if (attachments.isEmpty) {
      return AttachmentImportResult(
        itemId: null,
        attachmentIds: const [],
        failures: failures,
      );
    }

    final itemId = _newId();
    final normalizedText = text?.trim();
    final rows = attachments
        .map((row) => row.copyWith(itemId: Value(itemId)))
        .toList();
    try {
      await _database.saveItemWithAttachments(
        ItemsCompanion.insert(
          id: itemId,
          userId: Value(userId),
          title: Value(path.basenameWithoutExtension(files.first.name)),
          textContent: Value(
            normalizedText == null || normalizedText.isEmpty
                ? null
                : normalizedText,
          ),
          type: const Value('file'),
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
        rows,
      );
    } catch (error) {
      return AttachmentImportResult(
        itemId: null,
        attachmentIds: const [],
        failures: [
          ...failures,
          ...files.map(
            (file) => AttachmentImportFailure(
              displayName: file.name,
              sourcePath: file.name,
              code: AttachmentImportFailureCode.databaseFailed,
              details: error.toString(),
            ),
          ),
        ],
      );
    }

    try {
      await _onSaved?.call();
    } catch (_) {}
    return AttachmentImportResult(
      itemId: itemId,
      attachmentIds: attachmentIds,
      failures: failures,
    );
  }
}

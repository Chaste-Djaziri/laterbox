import 'package:path/path.dart' as path;

import '../data/attachment_repository.dart';
import '../data/attachment_storage.dart';
import 'attachment_file_policy.dart';
import 'attachment_import_result.dart';

class AttachmentImportService {
  const AttachmentImportService({
    required AttachmentFilePolicy policy,
    required AttachmentStorage storage,
    required AttachmentRepository repository,
    required String? Function() currentUserId,
    required String Function() newId,
    required DateTime Function() now,
    Future<void> Function()? onSaved,
  }) : this._(policy, storage, repository, currentUserId, newId, now, onSaved);

  const AttachmentImportService._(
    this._policy,
    this._storage,
    this._repository,
    this._currentUserId,
    this._newId,
    this._now,
    this._onSaved,
  );

  final AttachmentFilePolicy _policy;
  final AttachmentStorage _storage;
  final AttachmentRepository _repository;
  final String? Function() _currentUserId;
  final String Function() _newId;
  final DateTime Function() _now;
  final Future<void> Function()? _onSaved;

  Future<AttachmentImportResult> importFiles({
    required List<String> sourcePaths,
    String? text,
    String? itemId,
  }) async {
    if (itemId != null) {
      final existingIds = await _repository.existingAttachmentIds(itemId);
      if (existingIds != null) {
        return AttachmentImportResult(
          itemId: itemId,
          attachmentIds: existingIds,
          failures: const [],
        );
      }
    }
    final attemptId = _newId();
    final stored = <StoredAttachment>[];
    final failures = <AttachmentImportFailure>[];
    final resolvedPaths = <String>{};

    for (final sourcePath in sourcePaths) {
      AttachmentFileValidation validation;
      try {
        validation = await _policy.validate(sourcePath);
      } on AttachmentValidationException catch (error) {
        failures.add(
          AttachmentImportFailure(
            displayName: path.basename(sourcePath),
            sourcePath: sourcePath,
            code: error.code,
            details: error.details,
          ),
        );
        continue;
      } catch (error) {
        failures.add(
          AttachmentImportFailure(
            displayName: path.basename(sourcePath),
            sourcePath: sourcePath,
            code: AttachmentImportFailureCode.unreadable,
            details: error.toString(),
          ),
        );
        continue;
      }

      final normalized = path.normalize(validation.sourcePath);
      if (!resolvedPaths.add(normalized)) continue;

      try {
        stored.add(
          await _storage.copyVerified(
            attemptId: attemptId,
            attachmentId: _newId(),
            validation: validation,
          ),
        );
      } on AttachmentStorageException catch (error) {
        failures.add(
          AttachmentImportFailure(
            displayName: validation.originalFileName,
            sourcePath: sourcePath,
            code: error.code,
            details: error.details,
          ),
        );
      }
    }

    if (stored.isEmpty) {
      return AttachmentImportResult(
        itemId: null,
        attachmentIds: const [],
        failures: failures,
      );
    }

    final resolvedItemId = itemId ?? _newId();
    final createdAt = _now();
    final normalizedText = text?.trim();
    try {
      await _repository.saveItemWithAttachments(
        itemId: resolvedItemId,
        userId: _currentUserId(),
        title: path.basenameWithoutExtension(
          stored.first.validation.originalFileName,
        ),
        textContent: normalizedText == null || normalizedText.isEmpty
            ? null
            : normalizedText,
        createdAt: createdAt,
        attachments: stored,
      );
    } catch (error) {
      await _storage.removeOwnedCopies(
        stored.map((attachment) => attachment.id),
      );
      return AttachmentImportResult(
        itemId: null,
        attachmentIds: const [],
        failures: [
          ...failures,
          ...stored.map(
            (attachment) => AttachmentImportFailure(
              displayName: attachment.validation.originalFileName,
              sourcePath: attachment.validation.sourcePath,
              code: AttachmentImportFailureCode.databaseFailed,
              details: error.toString(),
            ),
          ),
        ],
      );
    }

    try {
      await _onSaved?.call();
    } catch (_) {
      // The local transaction is already committed. Sync remains best effort
      // and must never turn a durable local import into a visible save failure.
    }
    return AttachmentImportResult(
      itemId: resolvedItemId,
      attachmentIds: stored.map((attachment) => attachment.id).toList(),
      failures: failures,
    );
  }
}

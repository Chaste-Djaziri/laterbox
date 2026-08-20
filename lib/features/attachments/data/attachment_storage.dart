import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

import '../domain/attachment_file_policy.dart';
import '../domain/attachment_import_result.dart';

class StoredAttachment {
  const StoredAttachment({
    required this.id,
    required this.validation,
    required this.sha256,
    required this.localPath,
  });

  final String id;
  final AttachmentFileValidation validation;
  final String sha256;
  final String localPath;
}

class AttachmentStorageException implements Exception {
  const AttachmentStorageException(this.code, [this.details]);

  final AttachmentImportFailureCode code;
  final String? details;
}

class AttachmentStorage {
  AttachmentStorage(this.applicationSupportDirectory);

  final Directory applicationSupportDirectory;

  Directory get _attachmentsRoot =>
      Directory(path.join(applicationSupportDirectory.path, 'attachments'));

  Future<StoredAttachment> copyVerified({
    required String attemptId,
    required String attachmentId,
    required AttachmentFileValidation validation,
  }) async {
    final stagingDirectory = Directory(
      path.join(_attachmentsRoot.path, '.staging', attemptId, attachmentId),
    );
    final finalDirectory = Directory(
      path.join(_attachmentsRoot.path, attachmentId),
    );
    final fileName = 'original.${validation.fileExtension}';
    final temporaryFile = File(
      path.join(stagingDirectory.path, '$fileName.tmp'),
    );
    final finalFile = File(path.join(finalDirectory.path, fileName));

    try {
      await stagingDirectory.create(recursive: true);
      final sourceDigest = await _copyAndHash(
        File(validation.sourcePath),
        temporaryFile,
      );
      final copiedDigest = await _hash(temporaryFile);
      if (sourceDigest != copiedDigest) {
        throw const AttachmentStorageException(
          AttachmentImportFailureCode.verificationFailed,
          'The copied bytes did not match the source hash.',
        );
      }

      final after = await File(validation.sourcePath).stat();
      if (after.type != FileSystemEntityType.file ||
          after.size != validation.byteSize ||
          after.modified != validation.modifiedAt) {
        throw const AttachmentStorageException(
          AttachmentImportFailureCode.sourceChanged,
        );
      }

      await finalDirectory.create(recursive: true);
      await temporaryFile.rename(finalFile.path);
      await _deleteIfEmpty(stagingDirectory);
      await _deleteIfEmpty(stagingDirectory.parent);

      return StoredAttachment(
        id: attachmentId,
        validation: validation,
        sha256: sourceDigest,
        localPath: path.posix.join('attachments', attachmentId, fileName),
      );
    } on AttachmentStorageException {
      await _deleteDirectory(stagingDirectory);
      await _deleteDirectory(finalDirectory);
      rethrow;
    } on FileSystemException catch (error) {
      await _deleteDirectory(stagingDirectory);
      await _deleteDirectory(finalDirectory);
      throw AttachmentStorageException(
        AttachmentImportFailureCode.copyFailed,
        error.message,
      );
    }
  }

  Future<void> removeOwnedCopies(Iterable<String> attachmentIds) async {
    for (final id in attachmentIds) {
      if (!_isUuid(id)) continue;
      await _deleteDirectory(Directory(path.join(_attachmentsRoot.path, id)));
    }
  }

  Future<void> removeOrphans(Set<String> attachmentIds) async {
    final staging = Directory(path.join(_attachmentsRoot.path, '.staging'));
    await _deleteDirectory(staging);
    if (!await _attachmentsRoot.exists()) return;
    await for (final entity in _attachmentsRoot.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final id = path.basename(entity.path);
      if (_isUuid(id) && !attachmentIds.contains(id)) {
        await _deleteDirectory(entity);
      }
    }
  }

  String resolveLocalPath(String relativePath) {
    final normalized = path.posix.normalize(relativePath);
    if (path.posix.isAbsolute(normalized) ||
        normalized == '..' ||
        normalized.startsWith('../')) {
      throw ArgumentError.value(relativePath, 'relativePath');
    }
    final segments = path.posix.split(normalized);
    final resolved = path.normalize(
      path.joinAll([applicationSupportDirectory.path, ...segments]),
    );
    if (!path.isWithin(applicationSupportDirectory.path, resolved)) {
      throw ArgumentError.value(relativePath, 'relativePath');
    }
    return resolved;
  }

  Future<String> _copyAndHash(File source, File destination) async {
    final digest = await _hash(source);
    final output = destination.openWrite(mode: FileMode.writeOnly);
    try {
      await for (final chunk in source.openRead()) {
        output.add(chunk);
      }
      await output.flush();
      await output.close();
      return digest;
    } catch (_) {
      await output.close();
      rethrow;
    }
  }

  Future<String> _hash(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();

  Future<void> _deleteDirectory(Directory directory) async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> _deleteIfEmpty(Directory directory) async {
    if (!await directory.exists()) return;
    if (!await directory.list().isEmpty) return;
    await directory.delete();
  }

  bool _isUuid(String value) => RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value);
}

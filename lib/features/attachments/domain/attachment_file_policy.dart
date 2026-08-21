import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import 'attachment_import_result.dart';

const int attachmentMaxBytes = 100 * 1024 * 1024;

const Map<String, String> attachmentMimeTypes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'pdf': 'application/pdf',
  'txt': 'text/plain',
  'md': 'text/markdown',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
};

class AttachmentFileValidation {
  const AttachmentFileValidation({
    required this.sourcePath,
    required this.originalFileName,
    required this.fileExtension,
    required this.mimeType,
    required this.byteSize,
    required this.modifiedAt,
  });

  final String sourcePath;
  final String originalFileName;
  final String fileExtension;
  final String mimeType;
  final int byteSize;
  final DateTime modifiedAt;
}

class AttachmentValidationException implements Exception {
  const AttachmentValidationException(this.code, [this.details]);

  final AttachmentImportFailureCode code;
  final String? details;
}

class AttachmentFilePolicy {
  const AttachmentFilePolicy();

  Future<AttachmentFileValidation> validateBytes(
    String name,
    Uint8List bytes,
  ) async {
    if (bytes.isEmpty) {
      throw const AttachmentValidationException(
        AttachmentImportFailureCode.emptyFile,
      );
    }
    if (bytes.length > attachmentMaxBytes) {
      throw const AttachmentValidationException(
        AttachmentImportFailureCode.tooLarge,
      );
    }

    final safeName = path.basename(name);
    final extension = path
        .extension(safeName)
        .replaceFirst('.', '')
        .toLowerCase();
    final expectedMime = attachmentMimeTypes[extension];
    if (expectedMime == null) {
      throw const AttachmentValidationException(
        AttachmentImportFailureCode.unsupportedType,
      );
    }
    final header = Uint8List.sublistView(bytes, 0, bytes.length.clamp(0, 8192));
    final detectedMime = lookupMimeType(safeName, headerBytes: header);
    if (!_headerMatches(extension, header) ||
        _contradictsExpected(extension, detectedMime)) {
      throw AttachmentValidationException(
        AttachmentImportFailureCode.mimeMismatch,
        detectedMime == null ? null : 'Detected $detectedMime for .$extension.',
      );
    }
    if (extension == 'docx') {
      _validateDocxArchive(ZipDecoder().decodeBytes(bytes));
    }
    return AttachmentFileValidation(
      sourcePath: safeName,
      originalFileName: safeName,
      fileExtension: extension,
      mimeType: expectedMime,
      byteSize: bytes.length,
      modifiedAt: DateTime.now(),
    );
  }

  Future<AttachmentFileValidation> validate(String selectedPath) async {
    String resolvedPath;
    try {
      resolvedPath = await File(selectedPath).resolveSymbolicLinks();
    } on FileSystemException catch (error) {
      throw AttachmentValidationException(
        AttachmentImportFailureCode.unreadable,
        error.message,
      );
    }

    final file = File(resolvedPath);
    final FileStat stat;
    try {
      stat = await file.stat();
      if (stat.type != FileSystemEntityType.file) {
        throw const AttachmentValidationException(
          AttachmentImportFailureCode.unreadable,
          'The selected entry is not a regular file.',
        );
      }
    } on AttachmentValidationException {
      rethrow;
    } on FileSystemException catch (error) {
      throw AttachmentValidationException(
        AttachmentImportFailureCode.unreadable,
        error.message,
      );
    }

    if (stat.size == 0) {
      throw const AttachmentValidationException(
        AttachmentImportFailureCode.emptyFile,
      );
    }
    if (stat.size > attachmentMaxBytes) {
      throw const AttachmentValidationException(
        AttachmentImportFailureCode.tooLarge,
      );
    }

    final name = path.basename(resolvedPath);
    final extension = path.extension(name).replaceFirst('.', '').toLowerCase();
    final expectedMime = attachmentMimeTypes[extension];
    if (expectedMime == null) {
      throw const AttachmentValidationException(
        AttachmentImportFailureCode.unsupportedType,
      );
    }

    final header = await _readHeader(file);
    final detectedMime = lookupMimeType(name, headerBytes: header);
    if (!_headerMatches(extension, header)) {
      throw const AttachmentValidationException(
        AttachmentImportFailureCode.mimeMismatch,
      );
    }
    if (_contradictsExpected(extension, detectedMime)) {
      throw AttachmentValidationException(
        AttachmentImportFailureCode.mimeMismatch,
        'Detected $detectedMime for .$extension.',
      );
    }
    if (extension == 'docx') {
      await _validateDocx(resolvedPath);
    }

    return AttachmentFileValidation(
      sourcePath: resolvedPath,
      originalFileName: name,
      fileExtension: extension,
      mimeType: expectedMime,
      byteSize: stat.size,
      modifiedAt: stat.modified,
    );
  }

  Future<Uint8List> _readHeader(File file) async {
    try {
      final bytes = <int>[];
      await for (final chunk in file.openRead(0, 8192)) {
        bytes.addAll(chunk);
      }
      return Uint8List.fromList(bytes);
    } on FileSystemException catch (error) {
      throw AttachmentValidationException(
        AttachmentImportFailureCode.unreadable,
        error.message,
      );
    }
  }

  bool _contradictsExpected(String extension, String? detectedMime) {
    if (detectedMime == null || detectedMime == 'application/octet-stream') {
      return false;
    }
    if (extension == 'txt' || extension == 'md') {
      return !detectedMime.startsWith('text/');
    }
    if (extension == 'doc' || extension == 'docx') {
      return !detectedMime.startsWith('application/');
    }
    return detectedMime != attachmentMimeTypes[extension];
  }

  bool _headerMatches(String extension, Uint8List bytes) {
    bool starts(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (var index = 0; index < signature.length; index++) {
        if (bytes[index] != signature[index]) return false;
      }
      return true;
    }

    return switch (extension) {
      'jpg' || 'jpeg' => starts(const [0xff, 0xd8, 0xff]),
      'png' => starts(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
      'webp' =>
        bytes.length >= 12 &&
            String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
            String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP',
      'heic' =>
        bytes.length >= 12 &&
            String.fromCharCodes(bytes.sublist(4, 8)) == 'ftyp' &&
            const {
              'heic',
              'heix',
              'hevc',
              'hevx',
              'mif1',
              'msf1',
            }.contains(String.fromCharCodes(bytes.sublist(8, 12))),
      'pdf' => starts(const [0x25, 0x50, 0x44, 0x46, 0x2d]),
      'doc' => starts(const [0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1]),
      'docx' => starts(const [0x50, 0x4b]),
      'txt' || 'md' => !bytes.contains(0),
      _ => false,
    };
  }

  Future<void> _validateDocx(String filePath) async {
    InputFileStream? input;
    try {
      input = InputFileStream(filePath);
      _validateDocxArchive(ZipDecoder().decodeStream(input));
    } catch (error) {
      throw AttachmentValidationException(
        AttachmentImportFailureCode.mimeMismatch,
        'Invalid DOCX container: $error',
      );
    } finally {
      input?.closeSync();
    }
  }

  void _validateDocxArchive(Archive archive) {
    if (archive.length > 10000) {
      throw const FormatException('Too many DOCX entries.');
    }
    var totalDeclaredBytes = 0;
    var hasContentTypes = false;
    var hasDocument = false;
    for (final entry in archive) {
      final normalized = path.posix.normalize(entry.name.replaceAll('\\', '/'));
      if (normalized.startsWith('../') || path.posix.isAbsolute(normalized)) {
        throw const FormatException('Unsafe DOCX entry path.');
      }
      totalDeclaredBytes += entry.size;
      if (totalDeclaredBytes > attachmentMaxBytes * 4) {
        throw const FormatException('DOCX expands beyond the safe limit.');
      }
      if (normalized == '[Content_Types].xml' ||
          normalized == 'word/document.xml') {
        final content = entry.readBytes();
        if (content == null) {
          throw const FormatException('Unreadable DOCX entry.');
        }
        hasContentTypes |= normalized == '[Content_Types].xml';
        hasDocument |= normalized == 'word/document.xml';
      }
    }
    if (!hasContentTypes || !hasDocument) {
      throw const FormatException('Required Word entries are missing.');
    }
  }
}

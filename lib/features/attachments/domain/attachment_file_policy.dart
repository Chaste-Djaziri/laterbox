import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import 'attachment_import_result.dart';

/// Maximum attachment size per file: 5 GiB.
const int attachmentMaxBytes = 5 * 1024 * 1024 * 1024;

/// Categorized Preview Classification for UI rendering and backend derivative jobs.
enum PreviewKind {
  image,
  pdf,
  text,
  code,
  spreadsheet,
  document,
  presentation,
  audio,
  video,
  archive,
  ebook,
  model3d,
  font,
  generic,
}

const Map<String, String> _wellKnownMimeTypes = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'heic': 'image/heic',
  'heif': 'image/heif',
  'gif': 'image/gif',
  'avif': 'image/avif',
  'bmp': 'image/bmp',
  'svg': 'image/svg+xml',
  'pdf': 'application/pdf',
  'txt': 'text/plain',
  'md': 'text/markdown',
  'markdown': 'text/markdown',
  'log': 'text/plain',
  'rtf': 'application/rtf',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'odt': 'application/vnd.oasis.opendocument.text',
  'xls': 'application/vnd.ms-excel',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'ods': 'application/vnd.oasis.opendocument.spreadsheet',
  'csv': 'text/csv',
  'ppt': 'application/vnd.ms-powerpoint',
  'pptx':
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'odp': 'application/vnd.oasis.opendocument.presentation',
  'epub': 'application/epub+zip',
  'mp3': 'audio/mpeg',
  'm4a': 'audio/mp4',
  'aac': 'audio/aac',
  'wav': 'audio/wav',
  'flac': 'audio/flac',
  'ogg': 'audio/ogg',
  'opus': 'audio/opus',
  'wma': 'audio/x-ms-wma',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'm4v': 'video/x-m4v',
  'webm': 'video/webm',
  'mkv': 'video/x-matroska',
  'avi': 'video/x-msvideo',
  'zip': 'application/zip',
  'rar': 'application/vnd.rar',
  '7z': 'application/x-7z-compressed',
  'tar': 'application/x-tar',
  'gz': 'application/gzip',
  'json': 'application/json',
  'xml': 'application/xml',
  'yaml': 'text/yaml',
  'yml': 'text/yaml',
  'toml': 'application/toml',
  'html': 'text/html',
  'htm': 'text/html',
  'css': 'text/css',
  'js': 'text/javascript',
  'ts': 'text/typescript',
  'dart': 'text/x-dart',
  'py': 'text/x-python',
  'sh': 'application/x-sh',
  'exe': 'application/x-msdownload',
  'dmg': 'application/x-apple-diskimage',
  'apk': 'application/vnd.android.package-archive',
};

class AttachmentFileValidation {
  const AttachmentFileValidation({
    required this.sourcePath,
    required this.originalFileName,
    required this.fileExtension,
    required this.mimeType,
    required this.byteSize,
    required this.modifiedAt,
    required this.previewKind,
  });

  final String sourcePath;
  final String originalFileName;
  final String fileExtension;
  final String mimeType;
  final int byteSize;
  final DateTime modifiedAt;
  final PreviewKind previewKind;
}

class AttachmentValidationException implements Exception {
  const AttachmentValidationException(this.code, [this.details]);

  final AttachmentImportFailureCode code;
  final String? details;
}

class AttachmentFilePolicy {
  const AttachmentFilePolicy();

  /// Resolves the canonical PreviewKind for an extension and MIME type.
  static PreviewKind classifyPreviewKind(String extension, String mimeType) {
    final ext = extension.toLowerCase();
    final mime = mimeType.toLowerCase();

    if (mime.startsWith('image/') ||
        const {
          'jpg',
          'jpeg',
          'png',
          'webp',
          'heic',
          'heif',
          'gif',
          'avif',
          'bmp',
          'tif',
          'tiff',
          'svg',
        }.contains(ext)) {
      return PreviewKind.image;
    }
    if (ext == 'pdf' || mime == 'application/pdf') {
      return PreviewKind.pdf;
    }
    if (const {'txt', 'md', 'markdown', 'log'}.contains(ext)) {
      return PreviewKind.text;
    }
    if (const {
      'json',
      'xml',
      'yaml',
      'yml',
      'toml',
      'html',
      'htm',
      'css',
      'js',
      'jsx',
      'ts',
      'tsx',
      'dart',
      'py',
      'rb',
      'php',
      'java',
      'kt',
      'kts',
      'swift',
      'c',
      'h',
      'cpp',
      'hpp',
      'rs',
      'go',
      'sql',
    }.contains(ext)) {
      return PreviewKind.code;
    }
    if (const {'csv', 'xls', 'xlsx', 'ods'}.contains(ext)) {
      return PreviewKind.spreadsheet;
    }
    if (const {'rtf', 'doc', 'docx', 'odt'}.contains(ext)) {
      return PreviewKind.document;
    }
    if (const {'ppt', 'pptx', 'odp'}.contains(ext)) {
      return PreviewKind.presentation;
    }
    if (mime.startsWith('audio/') ||
        const {'mp3', 'm4a', 'aac', 'wav', 'flac', 'ogg', 'opus', 'wma'}
            .contains(ext)) {
      return PreviewKind.audio;
    }
    if (mime.startsWith('video/') ||
        const {'mp4', 'mov', 'm4v', 'webm', 'mkv', 'avi', 'mpg', 'mpeg'}
            .contains(ext)) {
      return PreviewKind.video;
    }
    if (const {'zip', 'rar', '7z', 'tar', 'gz', 'tgz', 'bz2', 'xz'}
        .contains(ext)) {
      return PreviewKind.archive;
    }
    if (ext == 'epub') {
      return PreviewKind.ebook;
    }
    if (const {'glb', 'gltf'}.contains(ext)) {
      return PreviewKind.model3d;
    }
    if (const {'ttf', 'otf', 'woff', 'woff2'}.contains(ext)) {
      return PreviewKind.font;
    }
    return PreviewKind.generic;
  }

  Future<AttachmentFileValidation> validateBytes(
    String name,
    Uint8List bytes,
  ) async {
    if (bytes.length > attachmentMaxBytes) {
      throw const AttachmentValidationException(
        AttachmentImportFailureCode.tooLarge,
      );
    }

    final safeName = path.basename(name);
    final extension =
        path.extension(safeName).replaceFirst('.', '').toLowerCase();
    final header =
        Uint8List.sublistView(bytes, 0, bytes.length.clamp(0, 8192));
    final mime = _wellKnownMimeTypes[extension] ??
        lookupMimeType(safeName, headerBytes: header) ??
        'application/octet-stream';

    if (extension == 'docx' && bytes.isNotEmpty) {
      try {
        _validateDocxArchive(ZipDecoder().decodeBytes(bytes));
      } catch (error) {
        throw AttachmentValidationException(
          AttachmentImportFailureCode.mimeMismatch,
          'Invalid DOCX container: $error',
        );
      }
    }

    final previewKind = classifyPreviewKind(extension, mime);

    return AttachmentFileValidation(
      sourcePath: safeName,
      originalFileName: safeName,
      fileExtension: extension,
      mimeType: mime,
      byteSize: bytes.length,
      modifiedAt: DateTime.now(),
      previewKind: previewKind,
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

    if (stat.size > attachmentMaxBytes) {
      throw const AttachmentValidationException(
        AttachmentImportFailureCode.tooLarge,
      );
    }

    final name = path.basename(resolvedPath);
    final extension =
        path.extension(name).replaceFirst('.', '').toLowerCase();
    final header = await _readHeader(file);
    final mime = _wellKnownMimeTypes[extension] ??
        lookupMimeType(name, headerBytes: header) ??
        'application/octet-stream';

    if (extension == 'docx' && stat.size > 0) {
      await _validateDocx(resolvedPath);
    }

    final previewKind = classifyPreviewKind(extension, mime);

    return AttachmentFileValidation(
      sourcePath: resolvedPath,
      originalFileName: name,
      fileExtension: extension,
      mimeType: mime,
      byteSize: stat.size,
      modifiedAt: stat.modified,
      previewKind: previewKind,
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
      final normalized =
          path.posix.normalize(entry.name.replaceAll('\\', '/'));
      if (normalized.startsWith('../') || path.posix.isAbsolute(normalized)) {
        throw const FormatException('Unsafe DOCX entry path.');
      }
      totalDeclaredBytes += entry.size;
      if (totalDeclaredBytes > 500 * 1024 * 1024) {
        throw const FormatException('DOCX expands beyond safe limit.');
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

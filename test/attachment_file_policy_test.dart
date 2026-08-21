import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/features/attachments/domain/attachment_file_policy.dart';

void main() {
  late Directory tempDir;
  late AttachmentFilePolicy policy;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('policy-test-');
    policy = const AttachmentFilePolicy();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AttachmentFilePolicy Universal Classification & Validation', () {
    test('classifies PreviewKind correctly across major file categories', () {
      expect(
        AttachmentFilePolicy.classifyPreviewKind('jpg', 'image/jpeg'),
        PreviewKind.image,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('svg', 'image/svg+xml'),
        PreviewKind.image,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('pdf', 'application/pdf'),
        PreviewKind.pdf,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('txt', 'text/plain'),
        PreviewKind.text,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('dart', 'text/x-dart'),
        PreviewKind.code,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('xlsx', 'application/excel'),
        PreviewKind.spreadsheet,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('docx', 'application/msword'),
        PreviewKind.document,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('pptx', 'application/ppt'),
        PreviewKind.presentation,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('mp3', 'audio/mpeg'),
        PreviewKind.audio,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('mp4', 'video/mp4'),
        PreviewKind.video,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('mkv', 'video/x-matroska'),
        PreviewKind.video,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('zip', 'application/zip'),
        PreviewKind.archive,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('epub', 'application/epub+zip'),
        PreviewKind.ebook,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('glb', 'model/gltf-binary'),
        PreviewKind.model3d,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('ttf', 'font/ttf'),
        PreviewKind.font,
      );
      expect(
        AttachmentFilePolicy.classifyPreviewKind('customformat', 'application/octet-stream'),
        PreviewKind.generic,
      );
    });

    test('accepts zero-byte files (e.g. .gitkeep or empty.txt)', () async {
      final file = File('${tempDir.path}/.gitkeep');
      await file.writeAsBytes([]);

      final validation = await policy.validate(file.path);
      expect(validation.byteSize, 0);
      expect(validation.originalFileName, '.gitkeep');
    });

    test('accepts unknown extensions as generic attachments', () async {
      final file = File('${tempDir.path}/model.blend');
      await file.writeAsBytes([0x42, 0x4c, 0x45, 0x4e, 0x44]);

      final validation = await policy.validate(file.path);
      expect(validation.fileExtension, 'blend');
      expect(validation.previewKind, PreviewKind.generic);
    });

    test('validates bytes for in-memory attachments', () async {
      final bytes = Uint8List.fromList('const x = 42;'.codeUnits);
      final validation = await policy.validateBytes('script.dart', bytes);

      expect(validation.fileExtension, 'dart');
      expect(validation.previewKind, PreviewKind.code);
      expect(validation.byteSize, bytes.length);
    });
  });
}

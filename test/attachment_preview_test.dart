import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/attachments/data/attachment_storage.dart';
import 'package:laterbox/features/attachments/presentation/attachment_preview.dart';

void main() {
  test(
    'Android opens attachments through the native content URI channel',
    () async {
      const channel = MethodChannel('laterbox/file_open');
      MethodCall? received;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            received = call;
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final opened = await openAttachmentPath(
        '/private/attachments/original.pdf',
        'application/pdf',
        useAndroidChannel: true,
      );

      expect(opened, isTrue);
      expect(received?.method, 'openFile');
      expect(received?.arguments, {
        'path': '/private/attachments/original.pdf',
        'mimeType': 'application/pdf',
      });
    },
  );

  testWidgets('shows a type specific card and the remaining file count', (
    tester,
  ) async {
    final root = Directory.systemTemp;
    final attachments = [
      _attachment(
        id: 'pdf',
        name: 'proposal.pdf',
        extension: 'pdf',
        mimeType: 'application/pdf',
        localPath: 'attachments/pdf/original.pdf',
      ),
      _attachment(
        id: 'document',
        name: 'notes.md',
        extension: 'md',
        mimeType: 'text/markdown',
        localPath: 'attachments/document/original.md',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttachmentCardPreview(
            attachments: attachments,
            storage: AttachmentStorage(root),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('attachmentCardPreview')), findsOneWidget);
    expect(find.text('proposal.pdf'), findsOneWidget);
    expect(find.text('PDF document · 1.0 KB'), findsOneWidget);
    expect(find.text('+1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows type specific metadata for every attachment', (
    tester,
  ) async {
    final root = Directory.systemTemp;
    final attachments = [
      _attachment(
        id: 'pdf',
        name: 'proposal.pdf',
        extension: 'pdf',
        mimeType: 'application/pdf',
        localPath: 'attachments/pdf/original.pdf',
        byteSize: 2048,
      ),
      _attachment(
        id: 'document',
        name: 'notes.md',
        extension: 'md',
        mimeType: 'text/markdown',
        localPath: 'attachments/document/original.md',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttachmentDetailPreview(
            attachments: attachments,
            storage: AttachmentStorage(root),
          ),
        ),
      ),
    );

    expect(find.text('2 attachments'), findsOneWidget);
    expect(find.text('proposal.pdf'), findsWidgets);
    expect(find.text('PDF document · 2.0 KB'), findsOneWidget);
    expect(find.text('notes.md'), findsWidgets);
    expect(find.text('Markdown document · 1.0 KB'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Attachment _attachment({
  required String id,
  required String name,
  required String extension,
  required String mimeType,
  required String localPath,
  int byteSize = 1024,
}) {
  final now = DateTime.utc(2026, 8, 20);
  return Attachment(
    id: id,
    itemId: 'item',
    originalFileName: name,
    fileExtension: extension,
    mimeType: mimeType,
    byteSize: byteSize,
    sha256: 'a' * 64,
    localPath: localPath,
    downloadStatus: 'downloaded',
    uploadStatus: 'local',
    uploadAttempts: 0,
    syncStatus: 'pending',
    createdAt: now,
    updatedAt: now,
  );
}

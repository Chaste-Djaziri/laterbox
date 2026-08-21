import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/attachments/data/attachment_repository.dart';
import 'package:laterbox/features/attachments/data/attachment_storage.dart';
import 'package:laterbox/features/attachments/domain/attachment_file_policy.dart';
import 'package:laterbox/features/attachments/domain/attachment_import_result.dart';
import 'package:laterbox/features/attachments/domain/attachment_import_service.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'laterbox-attachments-',
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('imports valid files once and classifies universal attachments', () async {
    final source = File('${temporaryDirectory.path}/Project Proposal.pdf');
    await source.writeAsBytes('%PDF-1.4\nLaterBox'.codeUnits);
    final zipFile = File('${temporaryDirectory.path}/archive.zip');
    await zipFile.writeAsBytes([0x50, 0x4b, 0x03, 0x04]);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final storage = AttachmentStorage(temporaryDirectory);
    var counter = 1;
    final service = AttachmentImportService(
      policy: const AttachmentFilePolicy(),
      storage: storage,
      repository: AttachmentRepository(database, storage),
      currentUserId: () => null,
      newId: () => '20000000-0000-4000-8000-00000000000${counter++}',
      now: () => DateTime.utc(2026, 8, 20),
      onSaved: () async => throw StateError('offline'),
    );

    final result = await service.importFiles(
      sourcePaths: [source.path, source.path, zipFile.path],
      text: 'Review with Alex',
    );

    expect(result.saved, isTrue);
    expect(result.attachmentIds, hasLength(2));
    final item = await database.itemById(result.itemId!);
    expect(item?.title, 'Project Proposal');
    expect(item?.textContent, 'Review with Alex');
    expect(item?.type, 'file');
    final dbAttachments = await database.attachments.select().get();
    expect(dbAttachments, hasLength(2));
    expect(
      File(storage.resolveLocalPath(dbAttachments.first.localPath!)).existsSync(),
      isTrue,
    );
  });

  test('creates no item when all selected files fail to resolve', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final storage = AttachmentStorage(temporaryDirectory);
    final service = AttachmentImportService(
      policy: const AttachmentFilePolicy(),
      storage: storage,
      repository: AttachmentRepository(database, storage),
      currentUserId: () => null,
      newId: () => '20000000-0000-4000-8000-000000000001',
      now: DateTime.now,
    );

    final result = await service.importFiles(
      sourcePaths: ['${temporaryDirectory.path}/nonexistent_file.unknown'],
      text: 'Keep this text in the sheet',
    );

    expect(result.saved, isFalse);
    expect(await database.items.select().get(), isEmpty);
  });

  test('accepts a real DOCX structure and rejects a corrupted DOCX container', () async {
    final policy = const AttachmentFilePolicy();
    final valid = File('${temporaryDirectory.path}/valid.docx');
    final validArchive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', '<Types/>'))
      ..addFile(ArchiveFile.string('word/document.xml', '<document/>'));
    await valid.writeAsBytes(ZipEncoder().encode(validArchive));
    final invalid = File('${temporaryDirectory.path}/invalid.docx');
    final invalidArchive = Archive()
      ..addFile(ArchiveFile.string('not-word.txt', 'hello'));
    await invalid.writeAsBytes(ZipEncoder().encode(invalidArchive));

    expect((await policy.validate(valid.path)).fileExtension, 'docx');
    await expectLater(
      policy.validate(invalid.path),
      throwsA(
        isA<AttachmentValidationException>().having(
          (error) => error.code,
          'code',
          AttachmentImportFailureCode.mimeMismatch,
        ),
      ),
    );
  });

  test('startup cleanup removes only unreferenced UUID directories', () async {
    final storage = AttachmentStorage(temporaryDirectory);
    final orphan = Directory(
      '${temporaryDirectory.path}/attachments/'
      '20000000-0000-4000-8000-000000000001',
    );
    final referenced = Directory(
      '${temporaryDirectory.path}/attachments/'
      '20000000-0000-4000-8000-000000000002',
    );
    final unknown = Directory('${temporaryDirectory.path}/attachments/manual');
    await orphan.create(recursive: true);
    await referenced.create(recursive: true);
    await unknown.create(recursive: true);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.into(database.items).insert(
          ItemsCompanion.insert(
            id: '10000000-0000-4000-8000-000000000001',
            type: const Value('file'),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await database.into(database.attachments).insert(
          AttachmentsCompanion.insert(
            id: '20000000-0000-4000-8000-000000000002',
            itemId: '10000000-0000-4000-8000-000000000001',
            originalFileName: 'file.pdf',
            fileExtension: 'pdf',
            mimeType: 'application/pdf',
            byteSize: 10,
            sha256: 'a' * 64,
            localPath: const Value(
              'attachments/20000000-0000-4000-8000-000000000002/file.pdf',
            ),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final repository = AttachmentRepository(database, storage);
    await repository.removeOrphans();

    expect(await orphan.exists(), isFalse);
    expect(await referenced.exists(), isTrue);
    expect(await unknown.exists(), isTrue);
  });
}

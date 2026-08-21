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

  test('imports valid files once and reports invalid peers', () async {
    final source = File('${temporaryDirectory.path}/Project Proposal.pdf');
    await source.writeAsBytes('%PDF-1.4\nLaterBox'.codeUnits);
    final unsupported = File('${temporaryDirectory.path}/archive.zip');
    await unsupported.writeAsBytes([0x50, 0x4b, 0x03, 0x04]);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final storage = AttachmentStorage(temporaryDirectory);
    final ids = [
      '20000000-0000-4000-8000-000000000001',
      '20000000-0000-4000-8000-000000000002',
      '20000000-0000-4000-8000-000000000003',
    ].iterator;
    final service = AttachmentImportService(
      policy: const AttachmentFilePolicy(),
      storage: storage,
      repository: AttachmentRepository(database, storage),
      currentUserId: () => null,
      newId: () {
        ids.moveNext();
        return ids.current;
      },
      now: () => DateTime.utc(2026, 8, 20),
      onSaved: () async => throw StateError('offline'),
    );

    final result = await service.importFiles(
      sourcePaths: [source.path, source.path, unsupported.path],
      text: 'Review with Alex',
    );

    expect(result.saved, isTrue);
    expect(result.attachmentIds, hasLength(1));
    expect(
      result.failures.single.code,
      AttachmentImportFailureCode.unsupportedType,
    );
    final item = await database.itemById(result.itemId!);
    expect(item?.title, 'Project Proposal');
    expect(item?.textContent, 'Review with Alex');
    expect(item?.type, 'file');
    final attachment = await database.attachments.select().getSingle();
    expect(attachment.sha256, hasLength(64));
    expect(
      File(storage.resolveLocalPath(attachment.localPath!)).existsSync(),
      isTrue,
    );
  });

  test('creates no item when all selected files fail', () async {
    final source = File('${temporaryDirectory.path}/archive.zip');
    await source.writeAsBytes([0x50, 0x4b, 0x03, 0x04]);
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
      sourcePaths: [source.path],
      text: 'Keep this text in the sheet',
    );

    expect(result.saved, isFalse);
    expect(await database.items.select().get(), isEmpty);
  });

  test('accepts a real DOCX structure and rejects a renamed ZIP', () async {
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

    await storage.removeOrphans({'20000000-0000-4000-8000-000000000002'});

    expect(orphan.existsSync(), isFalse);
    expect(referenced.existsSync(), isTrue);
    expect(unknown.existsSync(), isTrue);
  });
}

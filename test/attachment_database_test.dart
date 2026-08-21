import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:drift/native.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('creates an item with several local attachments atomically', () async {
    final now = DateTime.utc(2026, 8, 20);
    await database.saveItemWithAttachments(
      ItemsCompanion.insert(
        id: 'item-1',
        title: const Value('Proposal'),
        type: const Value('file'),
        createdAt: now,
        updatedAt: now,
      ),
      [
        _attachment('10000000-0000-4000-8000-000000000001', now),
        _attachment('10000000-0000-4000-8000-000000000002', now),
      ],
    );

    final rows = await database.attachments.select().get();
    expect(rows, hasLength(2));
    expect(rows.every((row) => row.userId == null), isTrue);
    expect(rows.every((row) => row.uploadStatus == 'local'), isTrue);
    expect(rows.every((row) => row.syncStatus == 'pending'), isTrue);
  });

  test('claims guest item and all attachment tombstones together', () async {
    final now = DateTime.utc(2026, 8, 20);
    await database.saveItemWithAttachments(
      ItemsCompanion.insert(
        id: 'item-1',
        type: const Value('file'),
        createdAt: now,
        updatedAt: now,
      ),
      [_attachment('10000000-0000-4000-8000-000000000001', now)],
    );
    await (database.attachments.update()).write(
      AttachmentsCompanion(deletedAt: Value(now)),
    );

    await database.itemsNeedingSync('user-1');

    expect((await database.itemById('item-1'))?.userId, 'user-1');
    final attachment = await database.attachments.select().getSingle();
    expect(attachment.userId, 'user-1');
    expect(attachment.deletedAt?.toUtc(), now);
  });

  test('soft deleting an item tombstones active attachments', () async {
    final now = DateTime.utc(2026, 8, 20);
    await database.saveItemWithAttachments(
      ItemsCompanion.insert(
        id: 'item-1',
        type: const Value('file'),
        createdAt: now,
        updatedAt: now,
      ),
      [_attachment('10000000-0000-4000-8000-000000000001', now)],
    );

    await database.softDeleteItem('item-1');

    final item = await database.itemById('item-1');
    final attachment = await database.attachments.select().getSingle();
    expect(item?.deletedAt, isNotNull);
    expect(item?.syncStatus, 'pending');
    expect(attachment.deletedAt, isNotNull);
    expect(attachment.syncStatus, 'pending');
  });

  test('database constraints reject invalid attachment metadata', () async {
    final now = DateTime.utc(2026, 8, 20);
    await database.saveItem(
      ItemsCompanion.insert(id: 'item-1', createdAt: now, updatedAt: now),
    );

    expect(
      () => database.attachments.insertOne(
        _attachment('10000000-0000-4000-8000-000000000001', now, byteSize: -1),
      ),
      throwsA(isA<SqliteException>()),
    );
  });
}

AttachmentsCompanion _attachment(String id, DateTime now, {int byteSize = 42}) {
  return AttachmentsCompanion.insert(
    id: id,
    itemId: 'item-1',
    originalFileName: 'proposal.pdf',
    fileExtension: 'pdf',
    mimeType: 'application/pdf',
    byteSize: byteSize,
    sha256: 'a' * 64,
    localPath: Value('attachments/$id/original.pdf'),
    createdAt: now,
    updatedAt: now,
  );
}

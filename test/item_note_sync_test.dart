import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/sync/sync_service.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/inbox/data/remote_item_data_source.dart';
import 'package:laterbox/features/notes/data/local_item_note_data_source.dart';
import 'package:laterbox/features/notes/data/remote_item_note_data_source.dart';

void main() {
  late AppDatabase database;
  late LocalItemDataSource items;
  late LocalItemNoteDataSource notes;
  late FakeRemoteItemDataSource remoteItems;
  late FakeRemoteItemNoteDataSource remoteNotes;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    items = LocalItemDataSource(database);
    notes = LocalItemNoteDataSource(database);
    remoteItems = FakeRemoteItemDataSource();
    remoteNotes = FakeRemoteItemNoteDataSource();
  });

  tearDown(() => database.close());

  SyncService makeService() => SyncService(
    local: items,
    remote: remoteItems,
    currentUserId: () => 'user-1',
    localNotes: notes,
    remoteNotes: remoteNotes,
  );

  Future<void> seedItem(String id) {
    final timestamp = DateTime.utc(2026, 8, 19);
    return database.saveItem(
      ItemsCompanion.insert(
        id: id,
        userId: const Value('user-1'),
        url: Value('https://example.com/$id'),
        type: const Value('link'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  test('pushes a pending note and claims it for the user', () async {
    await seedItem('item-a');
    await notes.save('item-a', null, 'A thought from my guest days');

    final result = await makeService().sync();

    expect(result.failed, 0);
    expect(remoteNotes.upserted, hasLength(1));
    expect(remoteNotes.upserted.single.content, 'A thought from my guest days');
    expect(remoteNotes.upserted.single.userId, 'user-1');
    final saved = (await notes.noteById('item-a'))!;
    expect(saved.syncStatus, 'synced');
    expect(saved.userId, 'user-1');
  });

  test('pulls a remote note written on another device', () async {
    final written = DateTime.utc(2026, 8, 19, 10);
    remoteNotes.notes = [
      RemoteItemNote(
        itemId: 'item-a',
        userId: 'user-1',
        content: 'Note from device B',
        createdAt: written,
        updatedAt: written.add(const Duration(hours: 1)),
      ),
    ];
    await seedItem('item-a');

    final result = await makeService().sync();

    expect(result.pulled, 1);
    final saved = (await notes.noteById('item-a'))!;
    expect(saved.content, 'Note from device B');
    expect(saved.syncStatus, 'synced');
    expect(saved.userId, 'user-1');
  });

  test('keeps a local note when it is newer than the remote', () async {
    await seedItem('item-a');
    await notes.save('item-a', 'user-1', 'Local newer version');
    await (database.update(database.itemNotes)
          ..where((note) => note.itemId.equals('item-a')))
        .write(ItemNotesCompanion(updatedAt: Value(DateTime.now())));

    remoteNotes.notes = [
      RemoteItemNote(
        itemId: 'item-a',
        userId: 'user-1',
        content: 'Remote older version',
        createdAt: DateTime.utc(2026, 8, 18),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];

    final result = await makeService().sync();

    expect(result.pulled, 0);
    final saved = (await notes.noteById('item-a'))!;
    expect(saved.content, 'Local newer version');
  });

  test('a remote edit newer than the local copy wins', () async {
    await seedItem('item-a');
    await notes.save('item-a', 'user-1', 'Local stale version');
    await (database.update(
      database.itemNotes,
    )..where((note) => note.itemId.equals('item-a'))).write(
      ItemNotesCompanion(updatedAt: Value(DateTime.utc(2026, 8, 19, 11))),
    );
    final newer = DateTime.utc(2026, 8, 19, 12);
    remoteNotes.notes = [
      RemoteItemNote(
        itemId: 'item-a',
        userId: 'user-1',
        content: 'Remote fresh version',
        createdAt: DateTime.utc(2026, 8, 19, 10),
        updatedAt: newer,
      ),
    ];

    final result = await makeService().sync();

    expect(result.pulled, 1);
    final saved = (await notes.noteById('item-a'))!;
    expect(saved.content, 'Remote fresh version');
  });

  test('a deletion is pushed as a tombstone and never resurrected', () async {
    await seedItem('item-a');
    await notes.save('item-a', 'user-1', 'Doomed');
    await notes.delete('item-a');

    final now = DateTime.now();
    remoteNotes.notes = [
      RemoteItemNote(
        itemId: 'item-a',
        userId: 'user-1',
        content: 'Older content from device B',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
    ];

    final result = await makeService().sync();

    expect(remoteNotes.upserted, hasLength(1));
    expect(remoteNotes.upserted.single.deletedAt, isNotNull);
    expect(result.pulled, 0);
    final saved = (await notes.noteById('item-a'))!;
    expect(saved.deletedAt, isNotNull);
  });

  test('retries failed note writes and marks failures', () async {
    await seedItem('item-a');
    await notes.save('item-a', null, 'Fragile thought');
    remoteNotes.failWrites = true;

    final failed = await makeService().sync();

    expect(failed.failed, 1);
    expect((await notes.noteById('item-a'))!.syncStatus, 'failed');

    remoteNotes.failWrites = false;
    final retried = await makeService().sync();

    expect(retried.failed, 0);
    expect((await notes.noteById('item-a'))!.syncStatus, 'synced');
    expect(remoteNotes.upserted, hasLength(1));
  });
}

class FakeRemoteItemDataSource implements RemoteItemDataSource {
  List<RemoteItem> items = [];

  @override
  Future<List<RemoteItem>> fetchItems(String userId) async => items;

  @override
  Future<void> upsertItem(Item item) async {}
}

class FakeRemoteItemNoteDataSource implements RemoteItemNoteDataSource {
  List<RemoteItemNote> notes = [];
  final List<ItemNote> upserted = [];
  bool failWrites = false;

  @override
  Future<List<RemoteItemNote>> fetchNotes(String userId) async => notes;

  @override
  Future<void> upsertNote(ItemNote note) async {
    if (failWrites) throw Exception('offline');
    upserted.add(note);
  }
}

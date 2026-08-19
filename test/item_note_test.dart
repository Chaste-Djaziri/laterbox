import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/notes/data/item_note_repository.dart';
import 'package:laterbox/features/notes/data/local_item_note_data_source.dart';

void main() {
  late AppDatabase database;
  late LocalItemDataSource items;
  late LocalItemNoteDataSource notes;
  late ItemNoteRepository repository;
  late int syncNudges;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    items = LocalItemDataSource(database);
    notes = LocalItemNoteDataSource(database);
    syncNudges = 0;
    repository = ItemNoteRepository(
      notes,
      userId: 'user-1',
      onChanged: () async => syncNudges++,
    );
  });

  tearDown(() => database.close());

  Future<void> seedItem(String id, {String? userId = 'user-1'}) {
    final timestamp = DateTime.utc(2026, 8, 19);
    return database.saveItem(
      ItemsCompanion.insert(
        id: id,
        userId: Value(userId),
        url: Value('https://example.com/$id'),
        type: const Value('link'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  group('saving and reading', () {
    test('saves a note and streams it back', () async {
      await seedItem('item-a');

      await repository.save('item-a', 'Read this before the interview');

      final note = await notes.noteById('item-a');
      expect(note!.content, 'Read this before the interview');
      expect(note.userId, 'user-1');
      expect(note.syncStatus, 'pending');
      expect(note.deletedAt, isNull);

      final streamed = await repository.watchNote('item-a').first;
      expect(streamed!.content, 'Read this before the interview');
      expect(syncNudges, 1);
    });

test('saving over an existing note updates content, not createdAt', () async {
      await seedItem('item-a');
      await notes.save('item-a', 'user-1', 'First draft');
      await (database.update(database.itemNotes)
            ..where((note) => note.itemId.equals('item-a')))
          .write(
        ItemNotesCompanion(
          updatedAt: Value(DateTime.utc(2026, 1, 1)),
        ),
      );
      final original = (await notes.noteById('item-a'))!;

      await repository.save('item-a', 'Second draft');

      final note = (await notes.noteById('item-a'))!;
      expect(note.content, 'Second draft');
      expect(note.createdAt, original.createdAt);
      expect(note.updatedAt.isAfter(original.updatedAt), isTrue);
    });

    test('an empty note is tombstoned instead of saved', () async {
      await seedItem('item-a');
      await notes.save('item-a', 'user-1', 'Something worth keeping');

      await repository.save('item-a', '   ');

      final raw = await notes.noteById('item-a');
      expect(raw!.deletedAt, isNotNull);
      expect(raw.syncStatus, 'pending');
      expect(await repository.watchNote('item-a').first, isNull);
    });

    test('delete tombstones the note', () async {
      await seedItem('item-a');
      await notes.save('item-a', 'user-1', 'Gone soon');

      await repository.delete('item-a');

      final raw = await notes.noteById('item-a');
      expect(raw!.deletedAt, isNotNull);
      expect(await repository.watchNote('item-a').first, isNull);
      expect(syncNudges, 1);
    });
  });

  group('guest behavior', () {
    test('a guest note survives a database restart', () async {
      final dir = await Directory.systemTemp.createTemp('laterbox-note-test');
      addTearDown(() => dir.delete(recursive: true));
      final path = '${dir.path}/guest.db';

      final first = AppDatabase(NativeDatabase(File(path)));
      await LocalItemDataSource(first).insert(
        ItemsCompanion.insert(
          id: 'item-a',
          userId: const Value(null),
          url: const Value('https://example.com/item-a'),
          type: const Value('link'),
          createdAt: DateTime.utc(2026, 8, 19),
          updatedAt: DateTime.utc(2026, 8, 19),
        ),
      );
      await LocalItemNoteDataSource(first).save('item-a', null, 'Guest thought');
      await first.close();

      final reopened = AppDatabase(NativeDatabase(File(path)));
      addTearDown(reopened.close);

      final note =
          await LocalItemNoteDataSource(reopened).noteById('item-a');
      expect(note!.content, 'Guest thought');
      expect(note.userId, isNull);
    });

    test('claiming assigns the signed-in user and keeps the content', () async {
      await seedItem('item-a', userId: null);
      await notes.save('item-a', null, 'Mine before I had an account');
      final guest = (await notes.noteById('item-a'))!;
      expect(guest.userId, isNull);

      final pending = await notes.notesNeedingSync('user-1');

      expect(pending, hasLength(1));
      expect(pending.single.userId, 'user-1');
      expect(pending.single.content, 'Mine before I had an account');
    });
  });

  group('account isolation', () {
    test('another account cannot see the note', () async {
      await seedItem('item-a');
      await notes.save('item-a', 'user-1', 'Private to user-1');

      final other = LocalItemNoteDataSource(database);
      expect(await other.watchNote('item-a', 'user-2').first, isNull);
    });

    test('logout hides an authenticated note but keeps the cache', () async {
      await seedItem('item-a');
      await notes.save('item-a', 'user-1', 'Keep me cached');

      final loggedOut = ItemNoteRepository(
        notes,
        userId: null,
        onChanged: () async {},
      );

      expect(await loggedOut.watchNote('item-a').first, isNull);
      expect((await notes.noteById('item-a'))!.content, 'Keep me cached');
    });
  });

  test('an item deletion hides its note', () async {
    await seedItem('item-a');
    await notes.save('item-a', 'user-1', 'Bundled with the item');

    await items.softDelete('item-a');

    expect(await notes.watchNote('item-a', 'user-1').first, isNull);
  });
}
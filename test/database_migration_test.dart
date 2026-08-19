import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
    'migration survives a stale version stamp and partial v5 columns',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'laterbox_migration_test',
      );
      final path = '${dir.path}/db.sqlite';
      try {
        // Create a fully migrated v5 database on disk.
        final database = AppDatabase(NativeDatabase(File(path)));
        await database.watchCollections(null).first;
        await database.close();

        // Simulate the broken state: schema already has every v5 column but
        // user_version still reports 4, so on the next open the v5 migration
        // re-runs and must skip columns that already exist.
        final raw = sqlite3.open(path);
        raw.execute('PRAGMA user_version = 4');
        raw.close();

        final reopened = AppDatabase(NativeDatabase(File(path)));
        final collections = await reopened.watchCollections(null).first;
        expect(collections, isEmpty);
        await reopened.close();
      } finally {
        if (await dir.exists()) await dir.delete(recursive: true);
      }
    },
  );

  test('migration backfills a missing updated_at without a constant default',
      () async {
    final dir = await Directory.systemTemp.createTemp(
      'laterbox_migration_test',
    );
    final path = '${dir.path}/db.sqlite';
    try {
      // Create a v5 database with a membership row.
      final database = AppDatabase(NativeDatabase(File(path)));
      await database.watchCollections(null).first;
      await database.saveItem(
        ItemsCompanion.insert(
          id: 'item-1',
          url: const Value('https://example.com'),
          type: const Value('link'),
          createdAt: DateTime.utc(2026, 8, 19),
          updatedAt: DateTime.utc(2026, 8, 19),
        ),
      );
      await database.createCollection('col-1', null, 'Development');
      await database.addItemToCollection('col-1', 'item-1');
      await database.close();

      // Drop only updated_at, leaving the other v5 columns, and rewind the
      // version stamp so the migration re-runs against that partial state.
      final raw = sqlite3.open(path);
      raw.execute('ALTER TABLE collection_items DROP COLUMN updated_at');
      raw.execute('PRAGMA user_version = 4');
      raw.close();

      final reopened = AppDatabase(NativeDatabase(File(path)));
      final membership =
          await reopened.collectionItemById('col-1', 'item-1');
      expect(membership!.updatedAt, membership.createdAt);
      expect(membership.syncStatus, 'pending');
      await reopened.close();
    } finally {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  });
}
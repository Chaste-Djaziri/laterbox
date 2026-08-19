import 'dart:io';

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
}
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';

void main() {
  test(
    'guest claiming and account partitions never expose another user',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final now = DateTime.utc(2026, 8, 19);

      await database.saveItem(
        ItemsCompanion.insert(
          id: 'guest-item',
          url: const Value('https://guest.example'),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.saveItem(
        ItemsCompanion.insert(
          id: 'first-user-item',
          userId: const Value('user-1'),
          url: const Value('https://first.example'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(
        (await database.watchInboxItems(null).first).map((item) => item.id),
        ['guest-item'],
      );
      expect(
        (await database.watchInboxItems('user-1').first).map((item) => item.id),
        ['first-user-item'],
      );

      await database.itemsNeedingSync('user-2');

      expect(await database.watchInboxItems(null).first, isEmpty);
      expect(
        (await database.watchInboxItems('user-2').first).map((item) => item.id),
        ['guest-item'],
      );
      expect(
        (await database.watchInboxItems('user-1').first).map((item) => item.id),
        ['first-user-item'],
      );
    },
  );
}

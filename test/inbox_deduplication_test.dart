import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/app.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/router/app_router.dart';
import 'package:laterbox/features/capture/data/android_share_receiver.dart';
import 'package:laterbox/features/inbox/data/item_repository.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/inbox/presentation/inbox_providers.dart';
import 'package:laterbox/shared/models/laterbox_item.dart';

void main() {
  group('Inbox Deduplication', () {
    test('ItemRepository.save prevents duplicate active inbox saves', () async {
      final database = AppDatabase(NativeDatabase.memory());
      final local = LocalItemDataSource(database);
      final repository = ItemRepository(
        local,
        userId: null,
        onSaved: () async {},
      );

      await repository.save('https://example.com/article');
      await repository.save('https://example.com/article');
      await repository.save('https://example.com/article');

      final items = await repository.watchInboxItems().first;
      expect(items.length, 1);
      expect(items.first.url, 'https://example.com/article');

      await database.close();
    });

    test('ItemRepository.save prevents duplicate text inbox saves', () async {
      final database = AppDatabase(NativeDatabase.memory());
      final local = LocalItemDataSource(database);
      final repository = ItemRepository(
        local,
        userId: null,
        onSaved: () async {},
      );

      await repository.save('Remember to buy groceries');
      await repository.save('Remember to buy groceries');
      await repository.save('Remember to buy groceries');

      final items = await repository.watchInboxItems().first;
      expect(items.length, 1);
      expect(items.first.text, 'Remember to buy groceries');

      await database.close();
    });

    test('deduplicateInboxItems filters out duplicate items with same URL or ID', () {
      final now = DateTime.now();
      final items = [
        LaterBoxItem(
          id: 'item-1',
          url: 'https://example.com/duplicate',
          createdAt: now,
        ),
        LaterBoxItem(
          id: 'item-2',
          url: 'https://example.com/duplicate',
          createdAt: now.subtract(const Duration(seconds: 1)),
        ),
        LaterBoxItem(
          id: 'item-3',
          url: 'https://example.com/unique',
          createdAt: now,
        ),
        LaterBoxItem(
          id: 'item-1',
          url: 'https://example.com/duplicate',
          createdAt: now,
        ),
      ];

      final deduplicated = deduplicateInboxItems(items);
      expect(deduplicated.length, 2);
      expect(deduplicated[0].id, 'item-1');
      expect(deduplicated[1].id, 'item-3');
    });

    test('ItemRepository.watchInboxItems filters legacy duplicate rows in SQLite', () async {
      final database = AppDatabase(NativeDatabase.memory());
      final local = LocalItemDataSource(database);
      final repository = ItemRepository(
        local,
        userId: null,
        onSaved: () async {},
      );

      final now = DateTime.now();
      await database.saveItem(
        ItemsCompanion.insert(
          id: 'legacy-1',
          url: const drift.Value('https://example.com/legacy'),
          type: const drift.Value('link'),
          status: const drift.Value('inbox'),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.saveItem(
        ItemsCompanion.insert(
          id: 'legacy-2',
          url: const drift.Value('https://example.com/legacy'),
          type: const drift.Value('link'),
          status: const drift.Value('inbox'),
          createdAt: now.subtract(const Duration(seconds: 5)),
          updatedAt: now.subtract(const Duration(seconds: 5)),
        ),
      );

      final items = await repository.watchInboxItems().first;
      expect(items.length, 1);
      expect(items.first.id, 'legacy-1');

      await database.close();
    });

    testWidgets('mobile share drain does not show duplicated items on multiple lifecycle calls', (
      tester,
    ) async {
      final database = AppDatabase(NativeDatabase.memory());
      var consumeCallCount = 0;
      const channel = MethodChannel(AndroidShareReceiver.channelName);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'consumeShares') {
              consumeCallCount++;
              return [
                {
                  'id': 'share-abc',
                  'text': 'https://example.com/shared-once',
                  'filePaths': <String>[],
                  'createdAt': DateTime.now().toIso8601String(),
                },
              ];
            }
            if (call.method == 'acknowledgeShares') return true;
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            initialLocationProvider.overrideWithValue('/inbox'),
          ],
          child: const LaterBoxApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger app resumed lifecycle event
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Trigger app resumed lifecycle event again
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.text('EXAMPLE.COM'), findsOneWidget);
      expect(find.text('https://example.com/shared-once'), findsOneWidget);
      expect(find.text('1 item saved'), findsOneWidget);
      expect(consumeCallCount, greaterThanOrEqualTo(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await database.close();
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/app.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/core/billing/billing_providers.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/router/app_router.dart';
import 'package:laterbox/features/capture/data/android_share_receiver.dart';
import 'package:laterbox/features/capture/data/ios_share_receiver.dart';

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int iterations = 40,
}) async {
  for (var i = 0; i < iterations; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
}

void main() {
  testWidgets('imports queued iOS shares for a free account', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    const channel = MethodChannel(IosShareReceiver.channelName);
    const androidChannel = MethodChannel(AndroidShareReceiver.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(androidChannel, (call) async => []);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'consumePending') {
            return [
              {
                'id': '3f257aa0-147d-4d95-99e8-e311380c886f',
                'value': 'https://example.com/b',
                'createdAt': '2026-08-19T07:01:00Z',
              },
            ];
          }
          if (call.method == 'acknowledgePending') return true;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(channel, null)
        ..setMockMethodCallHandler(androidChannel, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guestModeProvider.overrideWith((ref) => true),
          hasProAccessProvider.overrideWithValue(false),
          appDatabaseProvider.overrideWithValue(database),
          initialLocationProvider.overrideWithValue('/inbox'),
        ],
        child: const LaterBoxApp(),
      ),
    );
    await tester.pumpAndSettle();
    final stored = (await tester.runAsync(
      () => database.watchAllItemsWithMetadata(null).first,
    ))!;
    expect(stored, hasLength(1));
    expect(stored.single.$1.url, 'https://example.com/b');
    expect(stored.single.$1.status, 'deferred');
    expect(stored.single.$1.returnAt, isNull);
    expect(find.text('https://example.com/b'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });

  testWidgets('imports queued iOS share with returnAt scheduled time', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    const channel = MethodChannel(IosShareReceiver.channelName);
    const androidChannel = MethodChannel(AndroidShareReceiver.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(androidChannel, (call) async => []);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'consumePending') {
            return [
              {
                'id': 'return-at-share-123',
                'value': 'https://example.com/scheduled',
                'createdAt': '2026-08-19T07:01:00Z',
                'returnAt': '2026-08-20T10:00:00.000Z',
              },
            ];
          }
          if (call.method == 'acknowledgePending') return true;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(channel, null)
        ..setMockMethodCallHandler(androidChannel, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guestModeProvider.overrideWith((ref) => true),
          hasProAccessProvider.overrideWithValue(false),
          appDatabaseProvider.overrideWithValue(database),
          initialLocationProvider.overrideWithValue('/inbox'),
        ],
        child: const LaterBoxApp(),
      ),
    );
    await tester.pumpAndSettle();
    final stored = (await tester.runAsync(
      () => database.watchAllItemsWithMetadata(null).first,
    ))!;
    expect(stored, hasLength(1));
    expect(stored.single.$1.url, 'https://example.com/scheduled');
    expect(stored.single.$1.status, 'deferred');
    expect(
      stored.single.$1.returnAt?.toUtc(),
      DateTime.parse('2026-08-20T10:00:00.000Z'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });

  testWidgets('does not import an empty iOS share queue', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    const channel = MethodChannel(IosShareReceiver.channelName);
    const androidChannel = MethodChannel(AndroidShareReceiver.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(androidChannel, (call) async => []);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => []);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        ..setMockMethodCallHandler(channel, null)
        ..setMockMethodCallHandler(androidChannel, null),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guestModeProvider.overrideWith((ref) => true),
          appDatabaseProvider.overrideWithValue(database),
          initialLocationProvider.overrideWithValue('/inbox'),
        ],
        child: const LaterBoxApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('You’re all clear'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });

  testWidgets(
    'drains pending shares when onNewShareAvailable event is received',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      const channel = MethodChannel(IosShareReceiver.channelName);
      const androidChannel = MethodChannel(AndroidShareReceiver.channelName);
      var returnShares = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(androidChannel, (call) async => []);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'isAppGroupAvailable') return true;
            if (call.method == 'consumePending') {
              if (!returnShares) return [];
              return [
                {
                  'id': 'dynamic-share-42',
                  'value': 'https://example.com/live',
                  'createdAt': '2026-09-14T21:00:00Z',
                },
              ];
            }
            if (call.method == 'acknowledgePending') return true;
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMethodCallHandler(channel, null)
          ..setMockMethodCallHandler(androidChannel, null),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            guestModeProvider.overrideWith((ref) => true),
            hasProAccessProvider.overrideWithValue(false),
            appDatabaseProvider.overrideWithValue(database),
            initialLocationProvider.overrideWithValue('/inbox'),
          ],
          child: const LaterBoxApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('You’re all clear'), findsOneWidget);

      returnShares = true;
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            IosShareReceiver.channelName,
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('onNewShareAvailable'),
            ),
            (ByteData? data) {},
          );

      await _pumpUntilFound(tester, find.text('https://example.com/live'));
      final stored = (await tester.runAsync(
        () => database.watchAllItemsWithMetadata(null).first,
      ))!;
      expect(stored.single.$1.url, 'https://example.com/live');
      expect(stored.single.$1.status, 'deferred');
      expect(stored.single.$1.returnAt, isNull);
      expect(find.text('https://example.com/live'), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await database.close();
    },
  );
}

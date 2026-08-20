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

void main() {
  testWidgets('saves queued Android shares through the capture pipeline', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    const channel = MethodChannel(AndroidShareReceiver.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'consumeShares') {
        return ['https://example.com/a', 'read this later'];
      }
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

    expect(find.text('EXAMPLE.COM'), findsOneWidget);
    expect(find.text('https://example.com/a'), findsOneWidget);
    expect(find.text('read this later'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });

  testWidgets('ignores an empty Android share queue', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    const channel = MethodChannel(AndroidShareReceiver.channelName);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => []);
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

    expect(find.text('Nothing saved yet'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });
}
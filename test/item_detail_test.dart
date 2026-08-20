import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/app.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/router/app_router.dart';

void main() {
  Future<AppDatabase> seedDatabase({
    String id = 'item-1',
    String title = 'Flutter notes',
    String? url = 'https://github.com/flutter/flutter',
  }) async {
    final database = AppDatabase(NativeDatabase.memory());
    final timestamp = DateTime.utc(2026, 8, 19);
    await database.saveItem(
      ItemsCompanion.insert(
        id: id,
        title: Value(title),
        url: Value(url),
        type: const Value('link'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    return database;
  }

import 'package:laterbox/core/router/app_router.dart';

  Future<void> pumpApp(WidgetTester tester, AppDatabase database) async {
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
  }

  Future<void> disposeDatabase(
    WidgetTester tester,
    AppDatabase database,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  }

  testWidgets('tapping a card opens the detail screen', (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);

    await tester.tap(find.text('Flutter notes'));
    await tester.pumpAndSettle();

    expect(find.text('Collection'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('URL'), findsOneWidget);
    expect(find.text('Open original'), findsOneWidget);

    await disposeDatabase(tester, database);
  });

  testWidgets('long pressing a card keeps an item out of the inbox',
      (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);

    await tester.longPress(find.text('Flutter notes'));
    await tester.pumpAndSettle();

    expect(find.text('Keep'), findsOneWidget);
    await tester.tap(find.text('Keep'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect((await database.itemById('item-1'))!.status, 'saved');

    await disposeDatabase(tester, database);
  });

  testWidgets('deleting from the action sheet removes the item', (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);

    await tester.longPress(find.text('Flutter notes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Delete this item?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Nothing saved yet'), findsOneWidget);
    expect((await database.itemById('item-1'))!.deletedAt != null, isTrue);

    await disposeDatabase(tester, database);
  });

  testWidgets('favoriting from the detail action menu', (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);

    await tester.tap(find.text('Flutter notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Favorite'));
    await tester.pumpAndSettle();

    expect((await database.itemById('item-1'))!.favorite, isTrue);

    await disposeDatabase(tester, database);
  });

  testWidgets('adding to a new collection from the action sheet',
      (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);

    await tester.longPress(find.text('Flutter notes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to collection'));
    await tester.pumpAndSettle();

    expect(find.text('New collection'), findsWidgets);
    await tester.tap(find.widgetWithText(ListTile, 'New collection'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Development');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Development'), findsOneWidget);

    await disposeDatabase(tester, database);
  });
}
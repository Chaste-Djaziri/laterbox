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
  Future<AppDatabase> seedDatabase() async {
    final database = AppDatabase(NativeDatabase.memory());
    final timestamp = DateTime.utc(2026, 8, 19);
    await database.saveItem(
      ItemsCompanion.insert(
        id: 'item-1',
        title: const Value('Flutter notes'),
        type: const Value('note'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await database.saveItem(
      ItemsCompanion.insert(
        id: 'item-2',
        title: const Value('Dart notes'),
        type: const Value('note'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await database.createCollection('col-1', null, 'Development');
    await database.addItemToCollection('col-1', 'item-1');
    return database;
  }

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

  testWidgets('library shows sections and opens a collection', (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Library'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All Items'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);
    expect(find.text('Development'), findsOneWidget);
    expect(find.text('1 item'), findsOneWidget);

    await tester.ensureVisible(find.text('Development'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Development'));
    await tester.pumpAndSettle();

    expect(find.text('Flutter notes'), findsOneWidget);
    expect(find.text('Dart notes'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });
}
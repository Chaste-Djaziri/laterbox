import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/app.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';

void main() {
  Future<AppDatabase> seedDatabase() async {
    final database = AppDatabase(NativeDatabase.memory());
    final timestamp = DateTime.utc(2026, 8, 19);
    await database.saveItem(
      ItemsCompanion.insert(
        id: 'flutter-item',
        title: const Value('Flutter notes'),
        textContent: const Value('A saved note'),
        type: const Value('note'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await database.saveItem(
      ItemsCompanion.insert(
        id: 'dart-item',
        title: const Value('Dart notes'),
        type: const Value('note'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    return database;
  }

  Future<void> pumpApp(WidgetTester tester, AppDatabase database) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          guestModeProvider.overrideWith((ref) => true),
          appDatabaseProvider.overrideWithValue(database),
        ],
        child: const LaterBoxApp(),
      ),
    );
  }

  testWidgets('navigates between Inbox, Search and Library', (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Inbox'),
      ),
      findsOneWidget,
    );
    expect(find.text('Flutter notes'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Search'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Flutter notes'), findsOneWidget);
    expect(find.text('Dart notes'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Library'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsWidgets);
    expect(find.text('Flutter notes'), findsOneWidget);
    expect(find.text('Dart notes'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });

  testWidgets('search filters items as you type', (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Search'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pumpAndSettle();

    expect(find.text('Flutter notes'), findsOneWidget);
    expect(find.text('Dart notes'), findsNothing);

    await tester.enterText(find.byType(TextField), 'dart');
    await tester.pumpAndSettle();

    expect(find.text('Dart notes'), findsOneWidget);
    expect(find.text('Flutter notes'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();

    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Flutter notes'), findsOneWidget);
    expect(find.text('Dart notes'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });
}
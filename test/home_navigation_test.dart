import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
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
          initialLocationProvider.overrideWithValue('/inbox'),
        ],
        child: const LaterBoxApp(),
      ),
    );
  }

  Finder navigationDestination(String label) {
    final navigationType = find.byType(NavigationBar).evaluate().isNotEmpty
        ? NavigationBar
        : NavigationRail;
    return find.descendant(
      of: find.byType(navigationType),
      matching: find.text(label),
    );
  }

  testWidgets('navigates between Inbox, Library and Settings', (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);
    await tester.pumpAndSettle();

    expect(navigationDestination('Inbox'), findsOneWidget);
    expect(find.text('Flutter notes'), findsOneWidget);

    await tester.tap(navigationDestination('Library'));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsWidgets);
    expect(find.text('All Items'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Archived'), findsOneWidget);

    await tester.tap(find.text('All Items'));
    await tester.pumpAndSettle();

    expect(find.text('Flutter notes'), findsOneWidget);
    expect(find.text('Dart notes'), findsOneWidget);

    await tester.tap(navigationDestination('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });

  testWidgets('search input on home page activates search view and filters items', (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);
    await tester.pumpAndSettle();

    // Tap search input on home page to activate search view page
    expect(find.text('Search items, tags, notes...'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home_search_input')));
    await tester.pumpAndSettle();

    expect(find.text('Recent'), findsOneWidget);
    expect(find.text('Flutter notes'), findsOneWidget);
    expect(find.text('Dart notes'), findsOneWidget);

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

    // Tap back to return to Inbox
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Search items, tags, notes...'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  });

  testWidgets('renders standard size floating action button on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final database = await seedDatabase();
      await pumpApp(tester, database);
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      final size = tester.getSize(fabFinder);
      expect(size.width, lessThan(60));
      expect(size.height, lessThan(60));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await database.close();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

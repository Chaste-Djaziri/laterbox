import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/app.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/router/app_router.dart';
import 'package:laterbox/features/notes/data/local_item_note_data_source.dart';

void main() {
  Future<AppDatabase> seedDatabase({String? noteContent}) async {
    final database = AppDatabase(NativeDatabase.memory());
    final timestamp = DateTime.utc(2026, 8, 19);
    await database.saveItem(
      ItemsCompanion.insert(
        id: 'item-1',
        title: const Value('Flutter notes'),
        url: const Value('https://github.com/flutter/flutter'),
        type: const Value('link'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    if (noteContent != null) {
      await LocalItemNoteDataSource(database).save(
        'item-1',
        null,
        noteContent,
      );
    }
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

  Future<void> disposeDatabase(
    WidgetTester tester,
    AppDatabase database,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await database.close();
  }

  testWidgets('shows Add a note when the item has none', (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);

    await tester.tap(find.text('Flutter notes'));
    await tester.pumpAndSettle();

    expect(find.text('MY NOTE'), findsOneWidget);
    await tester.ensureVisible(find.text('Add a note'));
    await tester.pumpAndSettle();
    expect(find.text('Add a note'), findsOneWidget);

    await disposeDatabase(tester, database);
  });

  testWidgets('saving a note shows it and persists it', (tester) async {
    final database = await seedDatabase();
    await pumpApp(tester, database);

    await tester.tap(find.text('Flutter notes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add a note'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add a note'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'My own reference');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('My own reference'), findsOneWidget);
    final saved =
        await LocalItemNoteDataSource(database).noteById('item-1');
    expect(saved!.content, 'My own reference');

    await disposeDatabase(tester, database);
  });

  testWidgets('editing an existing note to empty removes it', (tester) async {
    final database = await seedDatabase(noteContent: 'Old thought');
    await pumpApp(tester, database);

    await tester.tap(find.text('Flutter notes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Old thought'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Old thought'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Add a note'), findsOneWidget);
    expect(
      (await LocalItemNoteDataSource(database).noteById('item-1'))!
          .deletedAt,
      isNotNull,
    );

    await disposeDatabase(tester, database);
  });

  testWidgets('search finds an item from its note text', (tester) async {
    final database = await seedDatabase(
      noteContent: 'Remember the sharding math',
    );
    await pumpApp(tester, database);

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'sharding math');
    await tester.pumpAndSettle();

    expect(find.text('Flutter notes'), findsOneWidget);

    await disposeDatabase(tester, database);
  });
}
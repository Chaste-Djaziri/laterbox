import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/settings/item_view_mode.dart';
import 'package:laterbox/features/inbox/presentation/inbox_providers.dart';
import 'package:laterbox/features/inbox/presentation/inbox_screen.dart';
import 'package:laterbox/shared/models/item_status.dart';
import 'package:laterbox/shared/models/laterbox_item.dart';
import 'package:laterbox/shared/widgets/item_card.dart';
import 'package:laterbox/shared/widgets/item_list_row.dart';
import 'package:laterbox/shared/widgets/view_mode_toggle.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('itemViewModeProvider defaults to cards and toggles to list', () async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(itemViewModeProvider), ItemViewMode.cards);

    await container.read(itemViewModeProvider.notifier).toggle();
    expect(container.read(itemViewModeProvider), ItemViewMode.list);

    final stored = await (db.select(db.appSettings)
          ..where((tbl) => tbl.key.equals(itemViewModeSettingKey)))
        .getSingleOrNull();
    expect(stored?.value, 'list');

    await container.read(itemViewModeProvider.notifier).toggle();
    expect(container.read(itemViewModeProvider), ItemViewMode.cards);
  });

  testWidgets('ViewModeToggle switches modes when tapped', (tester) async {
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ViewModeToggle(),
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Cards view'), findsOneWidget);
    expect(find.byTooltip('List view'), findsOneWidget);
    expect(container.read(itemViewModeProvider), ItemViewMode.cards);

    await tester.tap(find.byTooltip('List view'));
    await tester.pumpAndSettle();

    expect(container.read(itemViewModeProvider), ItemViewMode.list);

    await tester.tap(find.byTooltip('Cards view'));
    await tester.pumpAndSettle();

    expect(container.read(itemViewModeProvider), ItemViewMode.cards);
  });

  testWidgets('ItemListRow renders item metadata and triggers favorite toggle', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 9, 14, 1, 0, 0);
    await db.saveItem(
      ItemsCompanion.insert(
        id: 'test-item-1',
        title: const drift.Value('Flutter Architecture Guide'),
        url: const drift.Value('https://docs.flutter.dev/arch'),
        type: const drift.Value('article'),
        status: const drift.Value('inbox'),
        favorite: const drift.Value(false),
        createdAt: now,
        updatedAt: now,
      ),
    );

    final item = LaterBoxItem(
      id: 'test-item-1',
      title: 'Flutter Architecture Guide',
      url: 'https://docs.flutter.dev/arch',
      type: 'article',
      status: ItemStatus.inbox,
      favorite: false,
      createdAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ItemListRow(item: item),
          ),
        ),
      ),
    );

    expect(find.text('Flutter Architecture Guide'), findsOneWidget);
    expect(find.text('docs.flutter.dev'), findsOneWidget);
    expect(find.byTooltip('Star'), findsOneWidget);
    expect(find.byTooltip('Keep'), findsOneWidget);

    await tester.tap(find.byTooltip('Star'));
    await tester.pumpAndSettle();

    final updated = await (db.select(db.items)
          ..where((tbl) => tbl.id.equals('test-item-1')))
        .getSingle();
    expect(updated.favorite, isTrue);
  });

  testWidgets('InboxScreen switches between ItemCard and ItemListRow', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 9, 14, 1, 0, 0);
    final items = [
      LaterBoxItem(
        id: 'inbox-item-1',
        title: 'Design Systems in Flutter',
        url: 'https://laterbox.dev/design',
        type: 'article',
        status: ItemStatus.inbox,
        createdAt: now,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        inboxItemsProvider.overrideWith((ref) => Stream.value(items)),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: InboxScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Default view mode is cards -> renders ItemCard
    expect(find.byType(ItemCard), findsOneWidget);
    expect(find.byType(ItemListRow), findsNothing);

    // Header layout: Inbox title with count beside it, view switcher, and 3 dots
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('1'), findsAtLeastNWidgets(1));
    expect(find.byType(ViewModeToggle), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

    // Top app bar icons are removed
    expect(find.byIcon(Icons.search), findsNothing);
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsNothing);

    // Switch view mode to list
    await container.read(itemViewModeProvider.notifier).setViewMode(ItemViewMode.list);
    await tester.pumpAndSettle();

    // In list mode -> renders ItemListRow
    expect(find.byType(ItemListRow), findsOneWidget);
    expect(find.byType(ItemCard), findsNothing);
  });
}

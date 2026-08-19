import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/inbox/data/item_repository.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/shared/models/item_status.dart';

void main() {
  late AppDatabase database;
  late ItemRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ItemRepository(
      LocalItemDataSource(database),
      userId: 'user-1',
      onSaved: () async {},
    );
  });

  tearDown(() => database.close());

  Future<void> seedItem(String id, {String? title}) async {
    final timestamp = DateTime.utc(2026, 8, 19);
    await database.saveItem(
      ItemsCompanion.insert(
        id: id,
        userId: const Value('user-1'),
        url: Value('https://example.com/$id'),
        title: Value(title),
        type: const Value('link'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  test('captures start in the inbox', () async {
    await seedItem('item-1');
    final inbox = await repository.watchInboxItems().first;
    expect(inbox.map((item) => item.id), ['item-1']);
    expect(inbox.single.status, ItemStatus.inbox);
  });

  test('keep moves an item out of the inbox into the library', () async {
    await seedItem('item-1');

    await repository.keep('item-1');

    expect(await repository.watchInboxItems().first, isEmpty);
    final all = await repository.watchAllItems().first;
    expect(all.single.status, ItemStatus.saved);
  });

  test('archive moves an item to the archived section', () async {
    await seedItem('item-1');

    await repository.archive('item-1');

    expect(await repository.watchInboxItems().first, isEmpty);
    final archived = await repository.watchArchived().first;
    expect(archived.single.status, ItemStatus.archived);
  });

  test('favoriting surfaces the item in favorites', () async {
    await seedItem('item-1');

    await repository.setFavorite('item-1', true);

    final favorites = await repository.watchFavorites().first;
    expect(favorites.single.id, 'item-1');

    await repository.setFavorite('item-1', false);
    expect(await repository.watchFavorites().first, isEmpty);
  });

  test('delete hides the item from every list', () async {
    await seedItem('item-1');

    await repository.delete('item-1');

    expect(await repository.watchInboxItems().first, isEmpty);
    expect(await repository.watchAllItems().first, isEmpty);
    expect(await repository.watchFavorites().first, isEmpty);
    expect(await repository.watchArchived().first, isEmpty);
    expect((await database.itemById('item-1'))!.deletedAt != null, isTrue);
  });

  test('guest writes stay guest-scoped after status changes', () async {
    final guest = ItemRepository(
      LocalItemDataSource(database),
      userId: null,
      onSaved: () async {},
    );
    final timestamp = DateTime.utc(2026, 8, 19);
    await database.saveItem(
      ItemsCompanion.insert(
        id: 'guest-1',
        url: const Value('https://guest.example'),
        type: const Value('link'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );

    await guest.keep('guest-1');

    expect(await guest.watchAllItems().first, isNotEmpty);
    expect(await repository.watchAllItems().first, isEmpty);
  });
}
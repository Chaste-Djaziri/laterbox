import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/collections/data/collection_repository.dart';
import 'package:laterbox/features/collections/data/local_collection_data_source.dart';

void main() {
  late AppDatabase database;
  late LocalCollectionDataSource dataSource;
  late CollectionRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    dataSource = LocalCollectionDataSource(database);
    repository = CollectionRepository(
      dataSource,
      userId: 'user-1',
      onChanged: () async {},
    );
  });

  tearDown(() => database.close());

  Future<String> seedItem(String id) async {
    final timestamp = DateTime.utc(2026, 8, 19);
    await database.saveItem(
      ItemsCompanion.insert(
        id: id,
        userId: const Value('user-1'),
        url: Value('https://example.com/$id'),
        type: const Value('link'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    return id;
  }

  test('creating a collection surfaces it immediately', () async {
    final id = await repository.create('Development');

    final collections = await dataSource.watchCollections('user-1').first;
    expect(collections.single.id, id);
    expect(collections.single.name, 'Development');
  });

  test('adding items to a collection updates membership and counts', () async {
    final collectionId = await repository.create('Development');
    final itemA = await seedItem('a');
    final itemB = await seedItem('b');

    await repository.addItem(collectionId, itemA);
    await repository.addItem(collectionId, itemB);

    final memberships =
        await dataSource.watchCollectionsForItem(itemA, 'user-1').first;
    expect(memberships.map((c) => c.id), [collectionId]);

    final counts = await dataSource.watchCollectionCounts('user-1').first;
    expect(counts.single.$2, 2);

    final items =
        await dataSource.watchItemsInCollection(collectionId, 'user-1').first;
    expect(items.map((row) => row.$1.id).toSet(), {itemA, itemB});
  });

  test('removing an item updates counts and membership', () async {
    final collectionId = await repository.create('Development');
    final item = await seedItem('a');
    await repository.addItem(collectionId, item);

    await repository.removeItem(collectionId, item);

    final counts = await dataSource.watchCollectionCounts('user-1').first;
    expect(counts.single.$2, 0);
    final memberships =
        await dataSource.watchCollectionsForItem(item, 'user-1').first;
    expect(memberships, isEmpty);
  });

  test('deleting a collection hides it but keeps its items', () async {
    final collectionId = await repository.create('Development');
    final item = await seedItem('a');
    await repository.addItem(collectionId, item);

    await repository.delete(collectionId);

    final collections = await dataSource.watchCollections('user-1').first;
    expect(collections, isEmpty);
    expect(await database.itemById(item) != null, isTrue);
  });

  test('renaming updates the collection name', () async {
    final id = await repository.create('Old name');

    await repository.rename(id, 'New name');

    final collections = await dataSource.watchCollections('user-1').first;
    expect(collections.single.name, 'New name');
  });

  test('collections are scoped per user', () async {
    await repository.create('Mine');

    final guestCollections = await dataSource.watchCollections(null).first;
    expect(guestCollections, isEmpty);
  });
}
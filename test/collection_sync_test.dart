import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/sync/sync_service.dart';
import 'package:laterbox/features/collections/data/local_collection_data_source.dart';
import 'package:laterbox/features/collections/data/remote_collection_data_source.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/inbox/data/remote_item_data_source.dart';

void main() {
  late AppDatabase database;
  late LocalItemDataSource items;
  late LocalCollectionDataSource collections;
  late FakeRemoteItemDataSource remoteItems;
  late FakeRemoteCollectionDataSource remoteCollections;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    items = LocalItemDataSource(database);
    collections = LocalCollectionDataSource(database);
    remoteItems = FakeRemoteItemDataSource();
    remoteCollections = FakeRemoteCollectionDataSource();
  });

  tearDown(() => database.close());

  SyncService makeService() => SyncService(
    local: items,
    remote: remoteItems,
    currentUserId: () => 'user-1',
    localCollections: collections,
    remoteCollections: remoteCollections,
  );

  Future<void> seedItem(String id, {String? userId}) async {
    final timestamp = DateTime.utc(2026, 8, 19);
    await database.saveItem(
      ItemsCompanion.insert(
        id: id,
        userId: Value(userId),
        url: Value('https://example.com/$id'),
        type: const Value('link'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  test('pushes a pending collection and claims it for the user', () async {
    await collections.create('dev', null, 'Development');

    final result = await makeService().sync();

    expect(result.failed, 0);
    expect(remoteCollections.upsertedCollections, hasLength(1));
    expect(remoteCollections.upsertedCollections.single.name, 'Development');
    expect(
      (await collections.collectionById('dev'))!.syncStatus,
      'synced',
    );
    expect((await collections.collectionById('dev'))!.userId, 'user-1');
  });

  test('pulls remote collections and accepts the newest update', () async {
    final old = DateTime.utc(2026, 8, 18);
    remoteCollections.collections = [
      RemoteCollection(
        id: 'remote-col',
        userId: 'user-1',
        name: 'From device B',
        createdAt: old,
        updatedAt: old.add(const Duration(hours: 1)),
      ),
    ];

    final result = await makeService().sync();

    expect(result.pulled, 1);
    final saved = await collections.collectionById('remote-col');
    expect(saved!.name, 'From device B');
    expect(saved.syncStatus, 'synced');
    expect(saved.userId, 'user-1');
  });

  test('keeps a local collection when it is newer than the remote', () async {
    final old = DateTime.utc(2026, 8, 18);
    await collections.create('local-col', 'user-1', 'Local name');

    final now = DateTime.now();
    await (database.update(database.collections)
          ..where((c) => c.id.equals('local-col')))
        .write(
      CollectionsCompanion(
        name: const Value('Local newer'),
        updatedAt: Value(now),
        syncStatus: const Value('pending'),
      ),
    );
    remoteCollections.collections = [
      RemoteCollection(
        id: 'local-col',
        userId: 'user-1',
        name: 'Remote older',
        createdAt: old,
        updatedAt: now.subtract(const Duration(minutes: 1)),
      ),
    ];

    final result = await makeService().sync();

    expect(result.pulled, 0);
    final saved = await collections.collectionById('local-col');
    expect(saved!.name, 'Local newer');
  });

  test('pushes a membership removal as a tombstone', () async {
    await seedItem('item-a');
    await collections.create('dev', 'user-1', 'Development');
    await collections.addItem('dev', 'item-a');
    await collections.removeItem('dev', 'item-a');

    final result = await makeService().sync();

    expect(result.failed, 0);
    expect(remoteCollections.upsertedItems, hasLength(1));
    expect(
      remoteCollections.upsertedItems.single.deletedAt,
      isNotNull,
    );
  });

  test('a removal is never resurrected by an older remote membership',
      () async {
    final now = DateTime.now();
    await seedItem('item-a');
    await collections.create('dev', 'user-1', 'Development');
    await collections.addItem('dev', 'item-a');
    await collections.removeItem('dev', 'item-a');

    remoteCollections.items = [
      RemoteCollectionItem(
        collectionId: 'dev',
        itemId: 'item-a',
        userId: 'user-1',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
      ),
    ];

    final result = await makeService().sync();

    expect(result.pulled, 0);
    final membership =
        await collections.collectionItemById('dev', 'item-a');
    expect(membership!.deletedAt, isNotNull);
    final counts = await collections.watchCollectionCounts('user-1').first;
    expect(counts.single.$2, 0);
  });

  test('retries failed collection writes and accepts tombstones', () async {
    await collections.create('dev', null, 'Development');
    remoteCollections.failWrites = true;

    final failed = await makeService().sync();

    expect(failed.failed, 1);
    expect(
      (await collections.collectionById('dev'))!.syncStatus,
      'failed',
    );

    remoteCollections.failWrites = false;
    final retried = await makeService().sync();

    expect(retried.failed, 0);
    expect(
      (await collections.collectionById('dev'))!.syncStatus,
      'synced',
    );
  });
}

class FakeRemoteItemDataSource implements RemoteItemDataSource {
  List<RemoteItem> items = [];

  @override
  Future<List<RemoteItem>> fetchItems(String userId) async => items;

  @override
  Future<void> upsertItem(Item item) async {}
}

class FakeRemoteCollectionDataSource implements RemoteCollectionDataSource {
  List<RemoteCollection> collections = [];
  List<RemoteCollectionItem> items = [];
  final List<Collection> upsertedCollections = [];
  final List<CollectionItem> upsertedItems = [];
  bool failWrites = false;

  @override
  Future<List<RemoteCollection>> fetchCollections(String userId) async =>
      collections;

  @override
  Future<List<RemoteCollectionItem>> fetchCollectionItems(String userId) async =>
      items;

  @override
  Future<void> upsertCollection(Collection collection) async {
    if (failWrites) throw Exception('offline');
    upsertedCollections.add(collection);
  }

  @override
  Future<void> upsertCollectionItem(CollectionItem item) async {
    if (failWrites) throw Exception('offline');
    upsertedItems.add(item);
  }
}

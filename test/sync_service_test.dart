import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/sync/sync_service.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/inbox/data/remote_item_data_source.dart';

void main() {
  late AppDatabase database;
  late LocalItemDataSource local;
  late FakeRemoteItemDataSource remote;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    local = LocalItemDataSource(database);
    remote = FakeRemoteItemDataSource();
  });

  tearDown(() => database.close());

  test(
    'keeps an offline write pending when no user is authenticated',
    () async {
      await local.insert(_pendingItem('offline-item'));
      final service = SyncService(
        local: local,
        remote: remote,
        currentUserId: () => null,
      );

      final result = await service.sync();

      expect(result.skipped, isTrue);
      expect((await database.itemById('offline-item'))!.syncStatus, 'pending');
      expect(remote.upserted, isEmpty);
    },
  );

  test('pushes pending writes and prevents duplicate IDs', () async {
    await local.insert(_pendingItem('shared-id'));
    final service = _service(local, remote);

    await service.sync();
    await service.sync();

    final saved = await database.itemById('shared-id');
    expect(saved!.syncStatus, 'synced');
    expect(saved.userId, 'user-1');
    expect(remote.upserted.where((id) => id == 'shared-id'), hasLength(1));
  });

  test('retries failed writes and accepts the newest remote update', () async {
    final old = DateTime.utc(2026, 8, 18);
    await local.insert(_pendingItem('conflict', updatedAt: old));
    remote.items = [
      RemoteItem(
        id: 'conflict',
        userId: 'user-1',
        url: 'https://remote.example',
        type: 'link',
        favorite: false,
        status: 'inbox',
        createdAt: old,
        updatedAt: old.add(const Duration(hours: 1)),
      ),
    ];
    remote.failWrites = true;
    final service = _service(local, remote);

    final pulled = await service.sync();
    expect(pulled.pulled, 1);
    expect(
      (await database.itemById('conflict'))!.url,
      'https://remote.example',
    );

    await local.insert(_pendingItem('retry'));
    final failed = await service.sync();
    expect(failed.failed, 1);
    expect((await database.itemById('retry'))!.syncStatus, 'failed');

    remote.failWrites = false;
    final retried = await service.sync();
    expect(retried.pushed, 1);
    expect((await database.itemById('retry'))!.syncStatus, 'synced');
  });
}

SyncService _service(LocalItemDataSource local, RemoteItemDataSource remote) =>
    SyncService(local: local, remote: remote, currentUserId: () => 'user-1');

ItemsCompanion _pendingItem(String id, {DateTime? updatedAt}) {
  final timestamp = updatedAt ?? DateTime.utc(2026, 8, 19);
  return ItemsCompanion.insert(
    id: id,
    url: const Value('https://local.example'),
    type: const Value('link'),
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

class FakeRemoteItemDataSource implements RemoteItemDataSource {
  List<RemoteItem> items = [];
  final List<String> upserted = [];
  bool failWrites = false;

  @override
  Future<List<RemoteItem>> fetchItems(String userId) async => items;

  @override
  Future<void> upsertItem(Item item) async {
    if (failWrites) throw Exception('offline');
    if (!upserted.contains(item.id)) upserted.add(item.id);
  }
}

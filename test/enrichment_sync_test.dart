import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/sync/sync_service.dart';
import 'package:laterbox/features/enrichment/data/local_metadata_data_source.dart';
import 'package:laterbox/features/enrichment/data/remote_metadata_data_source.dart';
import 'package:laterbox/features/enrichment/domain/item_metadata.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/inbox/data/remote_item_data_source.dart';

void main() {
  late AppDatabase database;
  late FakeRemoteItemDataSource remoteItems;
  late FakeRemoteMetadataDataSource remoteMetadata;
  late LocalMetadataDataSource localMetadata;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    remoteItems = FakeRemoteItemDataSource();
    remoteMetadata = FakeRemoteMetadataDataSource();
    localMetadata = LocalMetadataDataSource(database);
  });

  tearDown(() => database.close());

  test('pushes enriched metadata to the remote during sync', () async {
    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    await localMetadata.ensurePending(
      'item-1',
      'https://example.com/x',
      'user-1',
    );
    await localMetadata.saveEnriched(
      'item-1',
      const EnrichedMetadata(title: 'A title'),
      'user-1',
    );

    final service = _service(database, remoteItems, remoteMetadata);
    final result = await service.sync();

    expect(remoteMetadata.upserted, contains('item-1'));
    expect(result.pushed, greaterThanOrEqualTo(1));
  });

  test('pulls remote metadata that is newer than the local row', () async {
    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    final old = DateTime.utc(2026, 8, 1);
    remoteMetadata.metadata = [
      RemoteItemMetadata(
        itemId: 'item-1',
        userId: 'user-1',
        title: 'Remote title',
        status: 'enriched',
        attemptCount: 1,
        metadataVersion: 1,
        createdAt: old,
        updatedAt: DateTime.utc(2026, 8, 19),
      ),
    ];

    final service = _service(database, remoteItems, remoteMetadata);
    final result = await service.sync();

    expect(result.pulled, greaterThanOrEqualTo(1));
    final row = await database.metadataById('item-1');
    expect(row!.title, 'Remote title');
    expect(row.status, 'enriched');
  });

  test('keeps the local metadata row when it is newer than remote', () async {
    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    await localMetadata.ensurePending(
      'item-1',
      'https://example.com/x',
      'user-1',
    );
    await localMetadata.saveEnriched(
      'item-1',
      const EnrichedMetadata(title: 'Local title'),
      'user-1',
    );
    remoteMetadata.metadata = [
      RemoteItemMetadata(
        itemId: 'item-1',
        userId: 'user-1',
        title: 'Remote title',
        status: 'enriched',
        attemptCount: 1,
        metadataVersion: 1,
        createdAt: DateTime.utc(2026, 8, 1),
        updatedAt: DateTime.utc(2026, 8, 1),
      ),
    ];

    final service = _service(database, remoteItems, remoteMetadata);
    await service.sync();

    expect((await database.metadataById('item-1'))!.title, 'Local title');
  });
}

SyncService _service(
  AppDatabase database,
  FakeRemoteItemDataSource remoteItems,
  FakeRemoteMetadataDataSource remoteMetadata,
) {
  return SyncService(
    local: LocalItemDataSource(database),
    remote: remoteItems,
    currentUserId: () => 'user-1',
    localMetadata: LocalMetadataDataSource(database),
    remoteMetadata: remoteMetadata,
  );
}

Future<void> _insertItem(
  AppDatabase database, {
  required String id,
  required String url,
}) {
  final timestamp = DateTime.utc(2026, 8, 19);
  return database.saveItem(
    ItemsCompanion.insert(
      id: id,
      url: Value(url),
      type: const Value('link'),
      createdAt: timestamp,
      updatedAt: timestamp,
    ),
  );
}

class FakeRemoteItemDataSource implements RemoteItemDataSource {
  final List<String> upserted = [];

  @override
  Future<List<RemoteItem>> fetchItems(String userId) async => [];

  @override
  Future<void> upsertItem(Item item) async {
    upserted.add(item.id);
  }
}

class FakeRemoteMetadataDataSource implements RemoteMetadataDataSource {
  List<RemoteItemMetadata> metadata = [];
  final List<String> upserted = [];

  @override
  Future<EnrichedMetadata> fetch(String url) async {
    throw UnsupportedError('fetch is not exercised in the sync test');
  }

  @override
  Future<List<RemoteItemMetadata>> fetchMetadata(String userId) async =>
      metadata;

  @override
  Future<void> upsertMetadata(ItemMetadataData metadata) async {
    if (!upserted.contains(metadata.itemId)) upserted.add(metadata.itemId);
  }
}
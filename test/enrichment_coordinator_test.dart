import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/enrichment/enrichment_coordinator.dart';
import 'package:laterbox/features/enrichment/data/enrichment_repository.dart';
import 'package:laterbox/features/enrichment/data/local_metadata_data_source.dart';
import 'package:laterbox/features/enrichment/data/remote_metadata_data_source.dart';
import 'package:laterbox/features/enrichment/domain/enrichment_service.dart';
import 'package:laterbox/features/enrichment/domain/item_metadata.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('drains the queue and enriches URL items on start', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final remote = FakeRemoteMetadataDataSource(
      onFetch: (_) => const EnrichedMetadata(title: 'Enriched title'),
    );
    final coordinator = _coordinator(database, remote);

    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    coordinator.start(
      items: const Stream.empty(),
      connectivityChanges: Stream.value([ConnectivityResult.wifi]),
    );

    await _waitUntil(() async => remote.fetchCalls == 1);
    await _waitUntil(
      () async => (await database.metadataById('item-1'))?.status == 'enriched',
    );
    expect((await database.metadataById('item-1'))!.title, 'Enriched title');

    await coordinator.dispose();
  });

  test('stops retrying after four failed attempts', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final remote = FakeRemoteMetadataDataSource(
      onFetch: (_) => const FunctionsHttpException(status: 502),
    );
    final coordinator = _coordinator(
      database,
      remote,
      retryDelayResolver: (_) => const Duration(milliseconds: 5),
    );

    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    coordinator.start(
      items: const Stream.empty(),
      connectivityChanges: Stream.value([ConnectivityResult.wifi]),
    );

    await _waitUntil(() async => remote.fetchCalls == 4);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(remote.fetchCalls, 4);
    expect((await database.metadataById('item-1'))!.attemptCount, 4);

    await coordinator.dispose();
  });

  test('resets stuck enriching rows on start and enriches them', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final remote = FakeRemoteMetadataDataSource(
      onFetch: (_) => const EnrichedMetadata(title: 'Enriched title'),
    );
    final coordinator = _coordinator(database, remote);

    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    final now = DateTime.now();
    await database.upsertMetadata(
      ItemMetadataCompanion.insert(
        itemId: 'item-1',
        status: const Value('enriching'),
        attemptCount: const Value(2),
        createdAt: now,
        updatedAt: now,
      ),
    );

    coordinator.start(
      items: const Stream.empty(),
      connectivityChanges: Stream.value([ConnectivityResult.wifi]),
    );

    await _waitUntil(() async => remote.fetchCalls == 1);
    final row = await database.metadataById('item-1');
    expect(row!.status, 'enriched');
    expect(row.attemptCount, 3);

    await coordinator.dispose();
  });
}

EnrichmentCoordinator _coordinator(
  AppDatabase database,
  RemoteMetadataDataSource remote, {
  Duration? Function(int completedAttempts)? retryDelayResolver,
}) {
  final repository = EnrichmentRepository(
    local: LocalMetadataDataSource(database),
    remote: remote,
    currentUserId: () => null,
  );
  return EnrichmentCoordinator(
    service: EnrichmentService(repository: repository),
    repository: repository,
    retryDelayResolver: retryDelayResolver,
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

Future<void> _waitUntil(
  Future<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition was not met before timeout.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

class FakeRemoteMetadataDataSource implements RemoteMetadataDataSource {
  FakeRemoteMetadataDataSource({required this.onFetch});

  final Object? Function(String url) onFetch;
  int fetchCalls = 0;

  @override
  Future<EnrichedMetadata> fetch(String url) async {
    fetchCalls++;
    final result = onFetch(url);
    if (result is EnrichedMetadata) return result;
    throw result!;
  }

  @override
  Future<List<RemoteItemMetadata>> fetchMetadata(String userId) async => [];

  @override
  Future<void> upsertMetadata(ItemMetadataData metadata) async {}
}
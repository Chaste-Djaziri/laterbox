import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/enrichment/data/enrichment_repository.dart';
import 'package:laterbox/features/enrichment/data/local_metadata_data_source.dart';
import 'package:laterbox/features/enrichment/data/remote_metadata_data_source.dart';
import 'package:laterbox/features/enrichment/domain/enrichment_result.dart';
import 'package:laterbox/features/enrichment/domain/enrichment_service.dart';
import 'package:laterbox/features/enrichment/domain/item_metadata.dart';
import 'package:laterbox/shared/models/laterbox_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late AppDatabase database;
  late FakeRemoteMetadataDataSource remote;
  late EnrichmentService service;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    remote = FakeRemoteMetadataDataSource();
    service = _service(database, remote);
  });

  tearDown(() => database.close());

  test('enriches a URL item and persists the metadata', () async {
    await _insertItem(database, id: 'item-1', url: 'https://github.com/flutter');
    remote.onFetch = (_) => const EnrichedMetadata(
      domain: 'github.com',
      siteName: 'GitHub',
      title: 'flutter/flutter',
      description: 'Flutter is fast.',
      faviconUrl: 'https://github.com/favicon.ico',
    );

    final result = await service.enrich(
      _item('item-1', url: 'https://github.com/flutter'),
    );

    expect(result, isA<EnrichmentSucceeded>());
    final row = await database.metadataById('item-1');
    expect(row!.status, 'enriched');
    expect(row.title, 'flutter/flutter');
    expect(row.description, 'Flutter is fast.');
    expect(row.attemptCount, 1);
    expect(row.domain, 'github.com');
    expect(remote.fetchCalls, 1);
  });

  test('reuses cached metadata for a duplicate URL without a remote call', () async {
    await _insertItem(database, id: 'a', url: 'https://example.com/article');
    await _insertItem(database, id: 'b', url: 'https://example.com/article');

    await service.enrich(_item('a', url: 'https://example.com/article'));
    final second = await service.enrich(_item('b', url: 'https://example.com/article'));

    expect(second, isA<EnrichmentSucceeded>());
    expect(remote.fetchCalls, 1);
    final rowB = await database.metadataById('b');
    expect(rowB!.status, 'enriched');
    expect(rowB.title, 'Enriched title');
  });

  test('normalizes the URL before invoking the function and caching', () async {
    await _insertItem(database, id: 'a', url: 'https://example.com/article');
    await _insertItem(database, id: 'b', url: 'HTTPS://EXAMPLE.com/Article');

    await service.enrich(_item('a', url: 'https://example.com/article'));
    remote.onFetch = (_) => const EnrichedMetadata(title: 'Should be cached');
    final second = await service.enrich(_item('b', url: 'https://example.com/article'));

    expect(remote.fetchCalls, 1);
    expect(
      (second as EnrichmentSucceeded).metadata.title,
      'Enriched title',
    );
  });

  test('classifies HTTP 422 as unsupported and not retryable', () async {
    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    remote.onFetch = (_) => const FunctionsHttpException(
      status: 422,
      reasonPhrase: 'Not HTML content',
    );

    final result = await service.enrich(_item('item-1', url: 'https://example.com/x'));

    expect(
      result,
      isA<EnrichmentFailed>().having((r) => r.retryable, 'retryable', false),
    );
    expect((await database.metadataById('item-1'))!.status, 'unsupported');
  });

  test('classifies HTTP 5xx as retryable and keeps failed status', () async {
    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    remote.onFetch = (_) => const FunctionsHttpException(status: 502);

    final result = await service.enrich(_item('item-1', url: 'https://example.com/x'));

    expect(
      result,
      isA<EnrichmentFailed>().having((r) => r.retryable, 'retryable', true),
    );
    expect((await database.metadataById('item-1'))!.status, 'failed');
  });

  test('classifies network failures as retryable', () async {
    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    remote.onFetch = (_) => const FunctionsFetchException();

    final result = await service.enrich(_item('item-1', url: 'https://example.com/x'));

    expect(
      result,
      isA<EnrichmentFailed>().having((r) => r.retryable, 'retryable', true),
    );
    expect(
      (result as EnrichmentFailed).message,
      'Network error',
    );
  });

  test('increments the attempt count on each attempt', () async {
    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    remote.onFetch = (_) => const FunctionsHttpException(status: 502);

    await service.enrich(_item('item-1', url: 'https://example.com/x'));
    final second = await service.enrich(_item('item-1', url: 'https://example.com/x'));

    expect((second as EnrichmentFailed).attemptCount, 2);
    expect((await database.metadataById('item-1'))!.attemptCount, 2);
  });

  test('skips enrichment while another attempt is in flight', () async {
    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    await _ensureEnriching(database, 'item-1');

    final result = await service.enrich(_item('item-1', url: 'https://example.com/x'));

    expect(result, isA<EnrichmentSkipped>());
    expect(remote.fetchCalls, 0);
  });

  test('a failed enrichment never touches the item', () async {
    await _insertItem(database, id: 'item-1', url: 'https://example.com/x');
    remote.onFetch = (_) => const FunctionsHttpException(status: 502);

    await service.enrich(_item('item-1', url: 'https://example.com/x'));

    final item = await database.itemById('item-1');
    expect(item!.url, 'https://example.com/x');
    expect(item.type, 'link');
  });
}

EnrichmentService _service(
  AppDatabase database,
  RemoteMetadataDataSource remote,
) {
  return EnrichmentService(
    repository: EnrichmentRepository(
      local: LocalMetadataDataSource(database),
      remote: remote,
      currentUserId: () => null,
    ),
  );
}

LaterBoxItem _item(String id, {String? url}) =>
    LaterBoxItem(id: id, url: url, createdAt: DateTime.now());

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

Future<void> _ensureEnriching(AppDatabase database, String itemId) {
  return database.upsertMetadata(
    ItemMetadataCompanion.insert(
      itemId: itemId,
      status: const Value('enriching'),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );
}

class FakeRemoteMetadataDataSource implements RemoteMetadataDataSource {
  int fetchCalls = 0;
  Object? Function(String url)? onFetch;
  final List<String> upserted = [];

  @override
  Future<EnrichedMetadata> fetch(String url) async {
    fetchCalls++;
    final handler = onFetch;
    if (handler != null) {
      final result = handler(url);
      if (result is EnrichedMetadata) return result;
      if (result != null) throw result;
    }
    return const EnrichedMetadata(title: 'Enriched title');
  }

  @override
  Future<List<RemoteItemMetadata>> fetchMetadata(String userId) async => [];

  @override
  Future<void> upsertMetadata(ItemMetadataData metadata) async {
    upserted.add(metadata.itemId);
  }
}
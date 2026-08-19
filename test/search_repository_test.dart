import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/enrichment/data/local_metadata_data_source.dart';
import 'package:laterbox/features/enrichment/domain/item_metadata.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/search/data/search_repository.dart';
import 'package:laterbox/features/search/domain/search_query.dart';

void main() {
  late AppDatabase database;
  late LocalMetadataDataSource localMetadata;
  late SearchRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    localMetadata = LocalMetadataDataSource(database);
    repository = SearchRepository(
      LocalItemDataSource(database),
      () => 'user-1',
    );
  });

  tearDown(() => database.close());

  Future<void> insertItem(
    String id, {
    String? url,
    String? title,
    String? text,
    DateTime? createdAt,
  }) {
    final timestamp = createdAt ?? DateTime.utc(2026, 8, 19);
    return database.saveItem(
      ItemsCompanion.insert(
        id: id,
        userId: const Value('user-1'),
        url: Value(url),
        title: Value(title),
        textContent: Value(text),
        type: const Value('link'),
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
  }

  Future<void> enrich(
    String itemId, {
    String? domain,
    String? siteName,
    String? title,
    String? description,
  }) async {
    await localMetadata.ensurePending(
      itemId,
      'https://placeholder.example',
      'user-1',
    );
    await localMetadata.saveEnriched(
      itemId,
      EnrichedMetadata(
        domain: domain,
        siteName: siteName,
        title: title,
        description: description,
      ),
      'user-1',
    );
  }

  test('ranks by title priority then recency', () async {
    await insertItem('a', title: 'guide to flutter navigation');
    await enrich('a', title: 'Guide to flutter navigation');
    await insertItem(
      'b',
      title: 'flutter',
      createdAt: DateTime.utc(2026, 8, 19),
    );
    await enrich('b', title: 'flutter');
    await insertItem('c', title: 'Fluttering leaves');
    await enrich('c', title: 'Fluttering leaves');
    await insertItem('d', url: 'https://flutter.dev');
    await enrich('d', title: 'unrelated', domain: 'example.org');

    final results = await repository
        .search(SearchQuery.raw('flutter'))
        .first;

    expect(results.map((r) => r.item.id), ['b', 'c', 'a', 'd']);
  });

  test('matches domain and site name before description', () async {
    await insertItem('domain', title: 'Some other thing');
    await enrich(
      'domain',
      title: 'Some other thing',
      domain: 'flutter.dev',
    );
    await insertItem('desc', title: 'Some other thing');
    await enrich(
      'desc',
      title: 'Some other thing',
      description: 'A deep dive into flutter',
      domain: 'example.org',
    );

    final results = await repository
        .search(SearchQuery.raw('flutter'))
        .first;

    expect(results.map((r) => r.item.id), ['domain', 'desc']);
  });

  test('matches url and text content', () async {
    await insertItem('url', url: 'https://flutter.org/x');
    await insertItem('text', text: 'My flutter notes');
    await enrich('url', domain: 'example.org');
    await enrich('text', domain: 'example.org');

    final results = await repository
        .search(SearchQuery.raw('flutter'))
        .first;

    expect(results.map((r) => r.item.id).toSet(), {'url', 'text'});
  });

  test('breaks relevance ties by recency', () async {
    await insertItem(
      'older',
      title: 'unrelated',
      createdAt: DateTime.utc(2026, 8, 18),
    );
    await enrich('older', description: 'flutter mention');
    await insertItem(
      'newer',
      title: 'unrelated',
      createdAt: DateTime.utc(2026, 8, 19),
    );
    await enrich('newer', description: 'flutter mention');

    final results = await repository
        .search(SearchQuery.raw('flutter'))
        .first;

    expect(results.map((r) => r.item.id), ['newer', 'older']);
  });

  test('searches guest items when userId is null', () async {
    final guestRepository = SearchRepository(
      LocalItemDataSource(database),
      () => null,
    );
    await database.saveItem(
      ItemsCompanion.insert(
        id: 'guest-item',
        url: const Value('https://flutter.example'),
        type: const Value('link'),
        createdAt: DateTime.utc(2026, 8, 19),
        updatedAt: DateTime.utc(2026, 8, 19),
      ),
    );

    final results = await guestRepository
        .search(SearchQuery.raw('flutter'))
        .first;

    expect(results.map((r) => r.item.id), ['guest-item']);
  });

  test('returns no results for an empty query', () async {
    await insertItem('a', title: 'anything');
    await enrich('a', title: 'anything');

    final results = await repository.search(SearchQuery.raw('  ')).first;

    expect(results, isEmpty);
  });
}
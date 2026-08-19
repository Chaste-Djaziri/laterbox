import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/enrichment/data/local_metadata_data_source.dart';
import 'package:laterbox/features/enrichment/domain/item_metadata.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/shared/models/laterbox_item.dart';
import 'package:laterbox/shared/widgets/item_card.dart';

void main() {
  group('watchTypeCounts', () {
    late AppDatabase database;
    late LocalItemDataSource items;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      items = LocalItemDataSource(database);
    });

    tearDown(() => database.close());

    Future<void> seedItem(
      String id,
      String url,
      String type,
      double confidence,
    ) async {
      final now = DateTime.utc(2026, 8, 19);
      await database.saveItem(
        ItemsCompanion.insert(
          id: id,
          userId: const Value('user-1'),
          url: Value(url),
          type: const Value('link'),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.upsertMetadata(
        ItemMetadataCompanion.insert(
          itemId: id,
          domain: Value(Uri.parse(url).host),
          title: Value('Title for $id'),
          contentType: Value(type),
          classificationSource: Value('domainRule'),
          classificationConfidence: Value(confidence),
          status: const Value('enriched'),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    test('counts items grouped by content type, newest-first by count', () async {
      await seedItem('v1', 'https://youtube.com/watch?v=abc', 'video', 0.95);
      await seedItem('v2', 'https://youtube.com/watch?v=def', 'video', 0.9);
      await seedItem(
        'r1',
        'https://github.com/foo/bar',
        'repository',
        1.0,
      );

      final counts = await items.watchTypeCounts('user-1').first;

      expect(counts, hasLength(2));
      expect(counts.first.$1, 'video');
      expect(counts.first.$2, 2);
      expect(counts.last.$1, 'repository');
      expect(counts.last.$2, 1);
    });

    test('watchItemsByType streams only matching items', () async {
      await seedItem('v1', 'https://youtube.com/watch?v=abc', 'video', 0.95);
      await seedItem(
        'r1',
        'https://github.com/foo/bar',
        'repository',
        1.0,
      );

      final videoItems = await items.watchItemsByType('user-1', 'video').first;
      final repoItems =
          await items.watchItemsByType('user-1', 'repository').first;

      expect(videoItems, hasLength(1));
      expect(repoItems, hasLength(1));
    });
  });

  group('classification persistence', () {
    late AppDatabase database;
    late LocalMetadataDataSource metadata;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      metadata = LocalMetadataDataSource(database);
    });

    tearDown(() => database.close());

    test('round-trips through EnrichedMetadata.fromDrift', () async {
      final now = DateTime.utc(2026, 8, 19);
      await database.saveItem(
        ItemsCompanion.insert(
          id: 'gh-1',
          url: const Value('https://github.com/foo/bar'),
          type: const Value('link'),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.upsertMetadata(
        ItemMetadataCompanion.insert(
          itemId: 'gh-1',
          contentType: Value('repository'),
          classificationSource: Value('domainRule'),
          classificationConfidence: Value(1.0),
          structuredData:
              Value('{"owner":"foo","repository":"bar"}'),
          status: const Value('enriched'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final row = await metadata.metadataForItem('gh-1');
      final enriched = EnrichedMetadata.fromDrift(row!);

      expect(enriched.classification, isNotNull);
      expect(enriched.classification!.type.name, 'repository');
      expect(enriched.classification!.confidence, 1.0);
      expect(enriched.classification!.structuredData?['owner'], 'foo');
    });
  });

  group('ItemCard type affordance', () {
    late AppDatabase database;
    late LocalMetadataDataSource metadata;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
      metadata = LocalMetadataDataSource(database);
    });

    tearDown(() => database.close());

    Future<LaterBoxItem> seedVideoItem() async {
      final now = DateTime.utc(2026, 8, 19);
      await database.saveItem(
        ItemsCompanion.insert(
          id: 'yt-1',
          url: const Value('https://youtu.be/dQw4w9WgXcQ'),
          type: const Value('link'),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.upsertMetadata(
        ItemMetadataCompanion.insert(
          itemId: 'yt-1',
          domain: Value('youtu.be'),
          title: Value('A video item'),
          description: Value('Enriched from a domain rule.'),
          contentType: Value('video'),
          classificationSource: Value('domainRule'),
          classificationConfidence: Value(0.95),
          status: const Value('enriched'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final itemRow = await database.itemById('yt-1');
      final metadataRow = await metadata.metadataForItem('yt-1');
      return LaterBoxItem.fromDriftRows(itemRow!, metadataRow);
    }

    testWidgets('shows a Video badge for a classified video item', (
      tester,
    ) async {
      final item = await seedVideoItem();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ItemCard(item: item)),
        ),
      );

      expect(find.text('Video'), findsWidgets);
      expect(find.text('A video item'), findsOneWidget);
      expect(find.text('YOUTU.BE'), findsOneWidget);
    });

    testWidgets('omits the badge for an unclassified link item', (
      tester,
    ) async {
      final now = DateTime.utc(2026, 8, 19);
      await database.saveItem(
        ItemsCompanion.insert(
          id: 'plain-1',
          url: const Value('https://example.com/article'),
          type: const Value('link'),
          createdAt: now,
          updatedAt: now,
        ),
      );
      final itemRow = await database.itemById('plain-1');
      final item = LaterBoxItem.fromDriftRows(itemRow!, null);

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ItemCard(item: item))),
      );

      expect(find.text('Video'), findsNothing);
      expect(find.text('Article'), findsNothing);
      expect(find.text('EXAMPLE.COM'), findsOneWidget);
    });
  });
}

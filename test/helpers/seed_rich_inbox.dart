import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/app.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';

Future<void> seedRichItem(
  WidgetTester tester,
  AppDatabase database, {
  String previewImageUrl = 'https://example.com/cover.jpg',
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const LaterBoxApp(),
    ),
  );
  await tester.pumpAndSettle();

  await database.saveItem(
    ItemsCompanion.insert(
      id: 'item-1',
      url: const Value('https://example.com/article'),
      type: const Value('link'),
      createdAt: DateTime.utc(2026, 8, 19),
      updatedAt: DateTime.utc(2026, 8, 19),
    ),
  );
  final now = DateTime.now();
  await database.upsertMetadata(
    ItemMetadataCompanion.insert(
      itemId: 'item-1',
      domain: const Value('example.com'),
      title: const Value('Enriched Article Title'),
      previewImageUrl: Value(previewImageUrl),
      status: const Value('enriched'),
      createdAt: now,
      updatedAt: now,
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> disposeDatabase(WidgetTester tester, AppDatabase database) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await database.close();
}
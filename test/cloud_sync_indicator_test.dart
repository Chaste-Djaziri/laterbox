import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/shared/widgets/cloud_sync_indicator.dart';

void main() {
  testWidgets('renders cloud sync indicator and opens detail modal sheet', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final now = DateTime.utc(2026, 8, 20);
    await db.saveItem(
      ItemsCompanion.insert(
        id: 'item-1',
        title: const Value('Proposal'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CloudSyncIndicator(),
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CloudSyncIndicator), findsOneWidget);

    await tester.tap(find.byType(CloudSyncIndicator));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cloud Sync & Backup'), findsOneWidget);
    expect(find.text('Sync Progress'), findsOneWidget);
    expect(find.text('Sync Now'), findsOneWidget);
  });
}

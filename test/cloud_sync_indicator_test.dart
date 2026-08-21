import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/sync/sync_stats_provider.dart';
import 'package:laterbox/shared/widgets/cloud_sync_indicator.dart';

void main() {
  testWidgets('renders cloud sync indicator and opens detail modal sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          syncStatsProvider.overrideWithValue(
            const AsyncData(
              SyncStatsData(
                totalItems: 5,
                pendingItems: 1,
                totalAttachments: 2,
                pendingAttachments: 0,
              ),
            ),
          ),
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

    expect(find.byType(CloudSyncIndicator), findsOneWidget);

    await tester.tap(find.byType(CloudSyncIndicator));
    await tester.pump();

    expect(find.text('Cloud Sync & Backup'), findsOneWidget);
    expect(find.text('Sync Progress'), findsOneWidget);
    expect(find.text('Sync Now'), findsOneWidget);
  });
}

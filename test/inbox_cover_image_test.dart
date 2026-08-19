import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'helpers/seed_rich_inbox.dart';

void main() {
  testWidgets('shows a 16:9 cover image when a preview image exists', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    await mockNetworkImagesFor(() async {
      await seedRichItem(tester, database);

      expect(find.byKey(const Key('itemCardCover')), findsOneWidget);
      expect(find.text('Enriched Article Title'), findsOneWidget);

      await disposeDatabase(tester, database);
    });
  });
}
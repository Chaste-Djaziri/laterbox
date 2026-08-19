import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';

import 'helpers/seed_rich_inbox.dart';

void main() {
  testWidgets('renders a compact card without a cover image', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    await seedRichItem(tester, database, previewImageUrl: '');

    expect(find.text('EXAMPLE.COM'), findsOneWidget);
    expect(find.text('Enriched Article Title'), findsOneWidget);
    expect(find.byKey(const Key('itemCardCover')), findsNothing);

    await disposeDatabase(tester, database);
  });

  testWidgets('collapses the cover area when the preview image fails', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    await seedRichItem(tester, database);
    await tester.pump();

    expect(find.byKey(const Key('itemCardCover')), findsNothing);
    expect(find.text('Enriched Article Title'), findsOneWidget);

    await disposeDatabase(tester, database);
  });
}
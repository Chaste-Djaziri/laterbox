import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/capture/domain/capture_payload.dart';
import 'package:laterbox/features/capture/domain/capture_service.dart';
import 'package:laterbox/features/inbox/data/item_repository.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('item survives reopening the persistent web database', (_) async {
    const itemId = 'laterbox-web-persistence-acceptance';
    const marker = 'https://example.com/laterbox-web-persistence-test';

    final firstDatabase = AppDatabase();
    try {
      final captureService = CaptureService(
        ItemRepository(
          LocalItemDataSource(firstDatabase),
          userId: null,
          onSaved: () async {},
        ),
      );

      await captureService.save(CapturePayload.fromValue(marker, id: itemId));

      final saved = await firstDatabase.itemById(itemId);
      expect(saved?.url, marker);
    } finally {
      await firstDatabase.close();
    }

    final reopenedDatabase = AppDatabase();
    try {
      final reopened = await reopenedDatabase.itemById(itemId);
      expect(reopened?.url, marker);
    } finally {
      await reopenedDatabase.customStatement('DELETE FROM items WHERE id = ?', [
        itemId,
      ]);
      await reopenedDatabase.close();
    }
  });
}

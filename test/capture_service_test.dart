import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/capture/domain/capture_payload.dart';
import 'package:laterbox/features/capture/domain/capture_service.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/inbox/data/item_repository.dart';

void main() {
  test('saves a shared URL as a link capture', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final service = _service(database);

    await service.save(
      CapturePayload.fromValue(
        'https://example.com/article',
        source: CaptureSource.androidShare,
      ),
    );

    final item = (await database.watchInboxItems(null).first).single;
    expect(item.url, 'https://example.com/article');
    expect(item.textContent, isNull);
    expect(item.type, 'link');
    expect(item.syncStatus, 'pending');
  });

  test('saves shared text as a text capture', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final service = _service(database);

    await service.save(
      CapturePayload.fromValue(
        'Read this later',
        source: CaptureSource.androidShare,
      ),
    );

    final item = (await database.watchInboxItems(null).first).single;
    expect(item.url, isNull);
    expect(item.textContent, 'Read this later');
    expect(item.type, 'text');
  });

  test('classifies text versus URL payloads', () {
    final link = CapturePayload.fromValue('https://youtu.be/abc');
    expect(link.url, 'https://youtu.be/abc');
    expect(link.text, isNull);

    final note = CapturePayload.fromValue('just a note');
    expect(note.text, 'just a note');
    expect(note.url, isNull);
  });
}

CaptureService _service(AppDatabase database) {
  final local = LocalItemDataSource(database);
  final repository = ItemRepository(local, userId: null, onSaved: () async {});
  return CaptureService(repository);
}
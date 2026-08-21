import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/attachments/data/attachment_file_picker.dart';
import 'package:laterbox/features/attachments/domain/attachment_file_policy.dart';
import 'package:laterbox/features/attachments/domain/web_attachment_import_service.dart';

void main() {
  test('keeps browser file bytes locally for later R2 upload', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final ids = <String>['attachment-id', 'item-id'].iterator;
    final bytes = Uint8List.fromList(const [
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
    ]);
    final service = WebAttachmentImportService(
      database: database,
      policy: const AttachmentFilePolicy(),
      currentUserId: () => 'user-id',
      newId: () {
        ids.moveNext();
        return ids.current;
      },
      now: () => DateTime.utc(2026, 8, 21),
    );

    final result = await service.importFiles(
      files: [
        PickedAttachmentFile(
          name: 'capture.png',
          size: bytes.length,
          bytes: bytes,
        ),
      ],
      text: 'Browser capture',
    );

    expect(result.saved, isTrue);
    final attachment = await database.attachments.select().getSingle();
    expect(attachment.localPath, isNull);
    expect(attachment.localBytes, bytes);
    expect(attachment.uploadStatus, 'local');
    expect(attachment.r2ObjectKey, isNull);
  });
}

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/features/attachments/data/attachment_repository.dart';
import 'package:laterbox/features/attachments/data/attachment_storage.dart';
import 'package:laterbox/features/attachments/domain/attachment_file_policy.dart';
import 'package:laterbox/features/attachments/domain/attachment_import_service.dart';
import 'package:laterbox/features/capture/data/android_share_receiver.dart';
import 'package:laterbox/features/capture/data/ios_share_receiver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'an Android multi share becomes one item with several attachments',
    () async {
      final temporaryDirectory = await Directory.systemTemp.createTemp(
        'laterbox-native-share-',
      );
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final pdf = File('${temporaryDirectory.path}/proposal.pdf');
      final image = File('${temporaryDirectory.path}/screenshot.png');
      await pdf.writeAsBytes('%PDF-1.4\nLaterBox'.codeUnits);
      await image.writeAsBytes([
        0x89,
        0x50,
        0x4e,
        0x47,
        0x0d,
        0x0a,
        0x1a,
        0x0a,
        ...List<int>.filled(16, 0),
      ]);
      final acknowledged = <String>[];
      const channel = MethodChannel(AndroidShareReceiver.channelName);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'consumeShares') {
              return [
                {
                  'id': '30000000-0000-4000-8000-000000000001',
                  'text': 'Review tomorrow',
                  'filePaths': [pdf.path, image.path],
                  'createdAt': '2026-08-20T10:00:00Z',
                },
              ];
            }
            if (call.method == 'acknowledgeShares') {
              acknowledged.addAll(
                ((call.arguments as Map<Object?, Object?>)['ids']!
                        as List<Object?>)
                    .whereType<String>(),
              );
              return true;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final storage = AttachmentStorage(temporaryDirectory);
      final ids = [
        '30000000-0000-4000-8000-000000000010',
        '30000000-0000-4000-8000-000000000011',
        '30000000-0000-4000-8000-000000000012',
        '30000000-0000-4000-8000-000000000013',
      ].iterator;
      final service = AttachmentImportService(
        policy: const AttachmentFilePolicy(),
        storage: storage,
        repository: AttachmentRepository(database, storage),
        currentUserId: () => null,
        newId: () {
          ids.moveNext();
          return ids.current;
        },
        now: () => DateTime.utc(2026, 8, 20, 10),
      );

      const receiver = AndroidShareReceiver();
      final payload = (await receiver.consumePendingShares()).single;
      final result = await service.importFiles(
        sourcePaths: payload.filePaths,
        text: payload.text,
      );
      await receiver.acknowledge([payload.id]);

      expect(result.saved, isTrue);
      expect(result.attachmentIds, hasLength(2));
      expect(await database.watchInboxItems(null).first, hasLength(1));
      expect(acknowledged, [payload.id]);
    },
  );

  test(
    'iOS grouped payload preserves staged paths and optional text',
    () async {
      const channel = MethodChannel(IosShareReceiver.channelName);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'consumePending') {
              return [
                {
                  'id': 'ios-files-1',
                  'text': 'Quarterly proposal',
                  'filePaths': [
                    '/group/PendingAttachments/ios-files-1/proposal.pdf',
                  ],
                  'createdAt': '2026-08-20T10:00:00Z',
                },
              ];
            }
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final payload =
          (await const IosShareReceiver().consumePendingShares()).single;

      expect(payload.text, 'Quarterly proposal');
      expect(payload.filePaths, hasLength(1));
      expect(payload.hasFiles, isTrue);
    },
  );
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../data/attachment_file_picker.dart';
import '../data/attachment_repository.dart';
import '../data/attachment_storage.dart';
import '../data/attachment_storage_api.dart';
import '../domain/attachment_file_policy.dart';
import '../domain/attachment_import_service.dart';

final attachmentFilePickerProvider = Provider<AttachmentFilePicker>((ref) {
  return const NativeAttachmentFilePicker();
});

final attachmentStorageProvider = FutureProvider<AttachmentStorage>((
  ref,
) async {
  return AttachmentStorage(await getApplicationSupportDirectory());
});

final attachmentRepositoryProvider = FutureProvider<AttachmentRepository>((
  ref,
) async {
  return AttachmentRepository(
    ref.watch(appDatabaseProvider),
    await ref.watch(attachmentStorageProvider.future),
  );
});

final attachmentsForItemProvider =
    StreamProvider.family<List<Attachment>, String>((ref, itemId) async* {
      final userId = ref.watch(activeUserIdProvider);
      yield* ref
          .watch(appDatabaseProvider)
          .watchAttachmentsForItem(itemId, userId);
    });

final attachmentPreviewUrlProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, attachmentId) async {
      final client = ref.watch(supabaseClientProvider);
      if (client == null) return null;
      return AttachmentStorageApi(client).prepareDownloadUrl(attachmentId);
    });

final attachmentImportServiceProvider = FutureProvider<AttachmentImportService>(
  (ref) async {
    final storage = await ref.watch(attachmentStorageProvider.future);
    return AttachmentImportService(
      policy: const AttachmentFilePolicy(),
      storage: storage,
      repository: AttachmentRepository(ref.watch(appDatabaseProvider), storage),
      currentUserId: () => ref.read(activeUserIdProvider),
      newId: const Uuid().v4,
      now: DateTime.now,
      onSaved: () async => ref.watch(syncCoordinatorProvider).requestSync(),
    );
  },
);

final attachmentStartupProvider = FutureProvider<void>((ref) async {
  final repository = await ref.watch(attachmentRepositoryProvider.future);
  await repository.removeOrphans();
});

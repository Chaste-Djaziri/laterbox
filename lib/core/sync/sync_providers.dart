import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/attachments/data/attachment_storage.dart';
import '../../features/attachments/data/attachment_storage_api.dart';
import '../../features/attachments/data/remote_attachment_data_source.dart';
import '../../features/attachments/domain/attachment_sync_service.dart';
import '../../features/collections/data/remote_collection_data_source.dart';
import '../../features/enrichment/data/local_metadata_data_source.dart';
import '../../features/enrichment/data/remote_metadata_data_source.dart';
import '../../features/inbox/data/remote_item_data_source.dart';
import '../../features/notes/data/local_item_note_data_source.dart';
import '../../features/notes/data/remote_item_note_data_source.dart';
import '../database/database_providers.dart';
import '../supabase/supabase_provider.dart';
import 'sync_coordinator.dart';
import 'sync_service.dart';

final remoteItemDataSourceProvider = Provider<RemoteItemDataSource?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseRemoteItemDataSource(client);
});

final remoteCollectionDataSourceProvider =
    Provider<RemoteCollectionDataSource?>((ref) {
      final client = ref.watch(supabaseClientProvider);
      return client == null ? null : SupabaseRemoteCollectionDataSource(client);
    });

final remoteItemNoteDataSourceProvider = Provider<RemoteItemNoteDataSource?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseRemoteItemNoteDataSource(client);
});

final attachmentSyncServiceProvider = FutureProvider<AttachmentSyncService?>((
  ref,
) async {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  final storage = kIsWeb
      ? null
      : AttachmentStorage(await getApplicationSupportDirectory());
  return AttachmentSyncService(
    ref.watch(appDatabaseProvider),
    SupabaseRemoteAttachmentDataSource(client),
    AttachmentStorageApi(client),
    storage,
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SyncService(
    local: ref.watch(localItemDataSourceProvider),
    remote: ref.watch(remoteItemDataSourceProvider),
    currentUserId: () => client?.auth.currentUser?.id,
    localMetadata: LocalMetadataDataSource(ref.watch(appDatabaseProvider)),
    remoteMetadata: client == null
        ? null
        : SupabaseRemoteMetadataDataSource(client),
    localCollections: ref.watch(localCollectionDataSourceProvider),
    remoteCollections: ref.watch(remoteCollectionDataSourceProvider),
    localNotes: LocalItemNoteDataSource(ref.watch(appDatabaseProvider)),
    remoteNotes: ref.watch(remoteItemNoteDataSourceProvider),
    attachmentSync: () => ref.read(attachmentSyncServiceProvider.future),
  );
});

final syncCoordinatorProvider = Provider<SyncCoordinator>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final coordinator = SyncCoordinator(ref.watch(syncServiceProvider));
  if (client != null) {
    coordinator.start(
      connectivityChanges: Connectivity().onConnectivityChanged,
      authChanges: client.auth.onAuthStateChange,
    );
  }
  ref.onDispose(() => unawaited(coordinator.dispose()));
  return coordinator;
});

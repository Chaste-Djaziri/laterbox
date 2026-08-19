import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/collections/data/remote_collection_data_source.dart';
import '../../features/enrichment/data/local_metadata_data_source.dart';
import '../../features/enrichment/data/remote_metadata_data_source.dart';
import '../../features/inbox/data/remote_item_data_source.dart';
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

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/enrichment/data/enrichment_repository.dart';
import '../../features/enrichment/data/local_metadata_data_source.dart';
import '../../features/enrichment/data/remote_metadata_data_source.dart';
import '../../features/enrichment/domain/enrichment_service.dart';
import '../../features/inbox/presentation/inbox_providers.dart';
import '../auth/auth_provider.dart';
import '../database/database_providers.dart';
import '../supabase/supabase_provider.dart';
import 'enrichment_coordinator.dart';

final localMetadataDataSourceProvider = Provider<LocalMetadataDataSource>((ref) {
  return LocalMetadataDataSource(ref.watch(appDatabaseProvider));
});

final remoteMetadataDataSourceProvider = Provider<RemoteMetadataDataSource?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseRemoteMetadataDataSource(client);
});

final enrichmentRepositoryProvider = Provider<EnrichmentRepository>((ref) {
  return EnrichmentRepository(
    local: ref.watch(localMetadataDataSourceProvider),
    remote: ref.watch(remoteMetadataDataSourceProvider),
    currentUserId: () => ref.read(activeUserIdProvider),
  );
});

final enrichmentServiceProvider = Provider<EnrichmentService>((ref) {
  return EnrichmentService(repository: ref.watch(enrichmentRepositoryProvider));
});

final enrichmentCoordinatorProvider = Provider<EnrichmentCoordinator>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final coordinator = EnrichmentCoordinator(
    service: ref.watch(enrichmentServiceProvider),
    repository: ref.watch(enrichmentRepositoryProvider),
  );
  if (client != null) {
    coordinator.start(
      items: ref.watch(itemRepositoryProvider).watchInboxItems(),
      connectivityChanges: Connectivity().onConnectivityChanged,
      authChanges: client.auth.onAuthStateChange,
    );
  }
  ref.onDispose(() => unawaited(coordinator.dispose()));
  return coordinator;
});
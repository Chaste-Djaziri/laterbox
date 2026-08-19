import '../../../core/database/app_database.dart';
import '../domain/item_metadata.dart';
import 'local_metadata_data_source.dart';
import 'remote_metadata_data_source.dart';

class EnrichmentCandidate {
  const EnrichmentCandidate({required this.item, this.metadata});

  final Item item;
  final ItemMetadataData? metadata;
}

/// Data-access facade for enrichment: local persistence, cache lookups, the
/// remote edge function, and the pending-work queue.
class EnrichmentRepository {
  const EnrichmentRepository({
    required this.local,
    required this.remote,
    required this.currentUserId,
  });

  final LocalMetadataDataSource local;
  final RemoteMetadataDataSource? remote;
  final String? Function() currentUserId;

  bool get remoteAvailable => remote != null;

  Future<ItemMetadataData?> metadataForItem(String itemId) {
    return local.metadataForItem(itemId);
  }

  Future<void> ensurePending(String itemId, String url) {
    return local.ensurePending(itemId, url, currentUserId());
  }

  Future<ItemMetadataData?> enrichedForUrl(String url) {
    return local.enrichedForUrl(url);
  }

  Future<EnrichedMetadata> fetchRemote(String url) {
    final client = remote;
    if (client == null) {
      throw StateError('Enrichment is unavailable without Supabase.');
    }
    return client.fetch(url);
  }

  Future<void> markEnriching(String itemId, int attemptCount) {
    return local.markEnriching(itemId, attemptCount, currentUserId());
  }

  Future<void> saveEnriched(String itemId, EnrichedMetadata metadata) {
    return local.saveEnriched(itemId, metadata, currentUserId());
  }

  Future<void> markFailed(String itemId, String error) {
    return local.markFailed(itemId, error, currentUserId());
  }

  Future<void> markUnsupported(String itemId, String error) {
    return local.markUnsupported(itemId, error, currentUserId());
  }

  Future<List<EnrichmentCandidate>> itemsToEnrich() async {
    final rows = await local.itemsToEnrich(currentUserId());
    return rows
        .map((row) => EnrichmentCandidate(item: row.$1, metadata: row.$2))
        .toList();
  }

  Future<void> resetStuckEnriching() {
    return local.resetStuckEnriching();
  }
}
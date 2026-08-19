import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/laterbox_item.dart';
import '../data/enrichment_repository.dart';
import 'enrichment_result.dart';
import 'item_metadata.dart';
import 'url_utils.dart';

/// Orchestrates a single enrichment attempt: cache lookup, state transitions,
/// edge-function invocation, and result classification.
class EnrichmentService {
  const EnrichmentService({required this.repository});

  final EnrichmentRepository repository;

  Future<EnrichmentResult> enrich(LaterBoxItem item) async {
    final url = item.url;
    if (url == null) return const EnrichmentSkipped();

    final normalized = normalizeUrl(url);
    final existing = await repository.metadataForItem(item.id);
    if (existing?.status == 'enriching') return const EnrichmentSkipped();

    if (existing == null) {
      await repository.ensurePending(item.id, normalized);
    }

    final cached = await repository.enrichedForUrl(normalized);
    if (cached != null) {
      final metadata = EnrichedMetadata.fromDrift(cached);
      await repository.saveEnriched(item.id, metadata);
      return EnrichmentSucceeded(metadata);
    }

    final attempt = (existing?.attemptCount ?? 0) + 1;
    await repository.markEnriching(item.id, attempt);

    EnrichedMetadata metadata;
    try {
      metadata = await repository.fetchRemote(normalized);
    } on FunctionException catch (error) {
      final retryable = !(error is FunctionsHttpException && error.status == 422);
      final message = _describe(error);
      await (retryable
          ? repository.markFailed(item.id, message)
          : repository.markUnsupported(item.id, message));
      return EnrichmentFailed(
        message: message,
        retryable: retryable,
        attemptCount: attempt,
      );
    } on Object catch (error) {
      final message = error.toString();
      await repository.markFailed(item.id, message);
      return EnrichmentFailed(
        message: message,
        retryable: true,
        attemptCount: attempt,
      );
    }

    await repository.saveEnriched(item.id, metadata);
    return EnrichmentSucceeded(metadata);
  }

  String _describe(FunctionException error) {
    if (error is FunctionsHttpException) return 'HTTP ${error.status}';
    if (error is FunctionsFetchException) return 'Network error';
    return error.toString();
  }
}
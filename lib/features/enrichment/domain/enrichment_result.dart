import 'item_metadata.dart';

sealed class EnrichmentResult {
  const EnrichmentResult();
}

/// The item was not eligible for enrichment (for example it has no URL, or
/// another enrichment for it is already in flight).
class EnrichmentSkipped extends EnrichmentResult {
  const EnrichmentSkipped();
}

class EnrichmentSucceeded extends EnrichmentResult {
  const EnrichmentSucceeded(this.metadata);

  final EnrichedMetadata metadata;
}

class EnrichmentFailed extends EnrichmentResult {
  const EnrichmentFailed({
    required this.message,
    required this.retryable,
    required this.attemptCount,
  });

  final String message;
  final bool retryable;
  final int attemptCount;
}
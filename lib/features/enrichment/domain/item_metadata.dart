import '../../../core/database/app_database.dart';

/// Content returned by the `enrich-url` edge function and persisted against an
/// item. Distinct from the Drift `ItemMetadataData` row, which additionally
/// tracks enrichment lifecycle (status, attempts, timestamps).
class EnrichedMetadata {
  const EnrichedMetadata({
    this.domain,
    this.siteName,
    this.title,
    this.description,
    this.faviconUrl,
    this.previewImageUrl,
  });

  factory EnrichedMetadata.fromRemoteJson(Map<String, dynamic> json) {
    return EnrichedMetadata(
      domain: json['domain'] as String?,
      siteName: json['siteName'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      faviconUrl: json['faviconUrl'] as String?,
      previewImageUrl: json['previewImageUrl'] as String?,
    );
  }

  factory EnrichedMetadata.fromDrift(ItemMetadataData row) {
    return EnrichedMetadata(
      domain: row.domain,
      siteName: row.siteName,
      title: row.title,
      description: row.description,
      faviconUrl: row.faviconUrl,
      previewImageUrl: row.previewImageUrl,
    );
  }

  final String? domain;
  final String? siteName;
  final String? title;
  final String? description;
  final String? faviconUrl;
  final String? previewImageUrl;
}
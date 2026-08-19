import '../../../core/database/app_database.dart';
import 'content_type.dart';

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
    this.classification,
  });

  factory EnrichedMetadata.fromRemoteJson(Map<String, dynamic> json) {
    final rawClassification = json['classification'];
    return EnrichedMetadata(
      domain: json['domain'] as String?,
      siteName: json['siteName'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      faviconUrl: json['faviconUrl'] as String?,
      previewImageUrl: json['previewImageUrl'] as String?,
      classification: rawClassification == null
          ? null
          : ClassificationResult.fromJson(
              Map<String, dynamic>.from(rawClassification as Map),
            ),
    );
  }

  factory EnrichedMetadata.fromDrift(ItemMetadataData row) {
    final hasClassification =
        row.contentType != 'link' ||
        row.classificationSource != null ||
        row.classificationConfidence != 0;
    return EnrichedMetadata(
      domain: row.domain,
      siteName: row.siteName,
      title: row.title,
      description: row.description,
      faviconUrl: row.faviconUrl,
      previewImageUrl: row.previewImageUrl,
      classification:
          hasClassification ? ClassificationResult.fromDrift(row) : null,
    );
  }

  final String? domain;
  final String? siteName;
  final String? title;
  final String? description;
  final String? faviconUrl;
  final String? previewImageUrl;
  final ClassificationResult? classification;
}
import '../../core/database/app_database.dart';
import '../../features/enrichment/domain/item_metadata.dart';

class LaterBoxItem {
  const LaterBoxItem({
    required this.id,
    this.url,
    this.title,
    this.text,
    this.type = 'unknown',
    this.favorite = false,
    this.archived = false,
    required this.createdAt,
    this.metadata,
  });

  factory LaterBoxItem.fromDriftRows(
    Item item,
    ItemMetadataData? metadata,
  ) {
    return LaterBoxItem(
      id: item.id,
      url: item.url,
      title: item.title,
      text: item.textContent,
      type: item.type,
      favorite: item.favorite,
      archived: item.archived,
      createdAt: item.createdAt,
      metadata: metadata == null ? null : EnrichedMetadata.fromDrift(metadata),
    );
  }

  final String id;
  final String? url;
  final String? title;
  final String? text;
  final String type;
  final bool favorite;
  final bool archived;
  final DateTime createdAt;

  /// Enrichment content (domain, title, description, favicon) once available.
  final EnrichedMetadata? metadata;
}

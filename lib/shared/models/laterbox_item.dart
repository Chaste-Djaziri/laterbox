import 'dart:convert';

import '../../core/database/app_database.dart';
import '../../features/enrichment/domain/item_metadata.dart';
import 'item_status.dart';

/// Context around a saved selection (text immediately before and after it),
/// used to build a browser text fragment so the quote can be scrolled to and
/// highlighted when the original source is reopened.
class TextSelector {
  const TextSelector({this.before, this.after});

  factory TextSelector.fromJson(String? raw) {
    if (raw == null || raw.isEmpty) return const TextSelector();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const TextSelector();
      return TextSelector(
        before: decoded['before'] is String ? decoded['before'] as String : null,
        after: decoded['after'] is String ? decoded['after'] as String : null,
      );
    } on FormatException {
      return const TextSelector();
    }
  }

  final String? before;
  final String? after;

  bool get isEmpty => (before == null || before!.isEmpty) &&
      (after == null || after!.isEmpty);
}

class LaterBoxItem {
  const LaterBoxItem({
    required this.id,
    this.url,
    this.title,
    this.text,
    this.selector = const TextSelector(),
    this.type = 'unknown',
    this.favorite = false,
    this.status = ItemStatus.inbox,
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
      selector: TextSelector.fromJson(item.textSelector),
      type: item.type,
      favorite: item.favorite,
      status: ItemStatus.fromDatabase(item.status),
      createdAt: item.createdAt,
      metadata: metadata == null ? null : EnrichedMetadata.fromDrift(metadata),
    );
  }

  final String id;
  final String? url;
  final String? title;
  final String? text;
  final TextSelector selector;
  final String type;
  final bool favorite;
  final ItemStatus status;
  final DateTime createdAt;

  /// Enrichment content (domain, title, description, favicon) once available.
  final EnrichedMetadata? metadata;

  bool get isArchived => status == ItemStatus.archived;
  bool get isInbox => status == ItemStatus.inbox;

  LaterBoxItem copyWith({
    String? id,
    String? url,
    String? title,
    String? text,
    TextSelector? selector,
    String? type,
    bool? favorite,
    ItemStatus? status,
    DateTime? createdAt,
    EnrichedMetadata? metadata,
  }) {
    return LaterBoxItem(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      text: text ?? this.text,
      selector: selector ?? this.selector,
      type: type ?? this.type,
      favorite: favorite ?? this.favorite,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
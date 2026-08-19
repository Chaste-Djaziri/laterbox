import 'dart:async';

import '../../../core/database/app_database.dart';
import '../../../shared/models/laterbox_item.dart';
import '../../inbox/data/local_item_data_source.dart';
import '../domain/search_query.dart';
import '../domain/search_result.dart';

/// Local-first search over the Drift database. Supabase is never queried, so
/// search works offline, for guest users, and before cloud sync finishes.
class SearchRepository {
  SearchRepository(
    this._local,
    this._currentUserId,
  );

  final LocalItemDataSource _local;
  final String? Function() _currentUserId;

  Stream<List<SearchResult>> search(
    SearchQuery query, {
    String? contentType,
  }) {
    if (query.isEmpty) return Stream.value(const []);
    return _local
        .searchItemsWithMetadata(
          _currentUserId(),
          query.value,
          contentType: contentType,
        )
        .map((rows) => _rank(rows, query.value));
  }

  List<SearchResult> _rank(
    List<(Item, ItemMetadataData?, ItemNote?)> rows,
    String raw,
  ) {
    final needle = raw.trim().toLowerCase();
    final results = rows
        .map(
          (row) => SearchResult(
            item: LaterBoxItem.fromDriftRows(row.$1, row.$2),
            relevance: _score(row.$1, row.$2, row.$3, needle),
          ),
        )
        .toList();

    results.sort((a, b) {
      final byRelevance = b.relevance.compareTo(a.relevance);
      if (byRelevance != 0) return byRelevance;
      return b.item.createdAt.compareTo(a.item.createdAt);
    });
    return results;
  }

  int _score(
    Item item,
    ItemMetadataData? metadata,
    ItemNote? note,
    String needle,
  ) {
    final title =
        (metadata?.title ?? item.title ?? item.url ?? item.textContent ?? '')
            .toLowerCase();
    if (title == needle) return 100;
    if (title.startsWith(needle)) return 80;
    if (title.contains(needle)) return 60;

    final noteText = (note?.content ?? '').toLowerCase();
    if (noteText.contains(needle)) return 65;

    final domain = (metadata?.domain ?? '').toLowerCase();
    final siteName = (metadata?.siteName ?? '').toLowerCase();
    if (domain == needle || siteName == needle) return 55;
    if (domain.contains(needle) || siteName.contains(needle)) return 50;

    final description = (metadata?.description ?? '').toLowerCase();
    if (description.contains(needle)) return 40;

    final url = (item.url ?? '').toLowerCase();
    final text = (item.textContent ?? '').toLowerCase();
    if (url.contains(needle) || text.contains(needle)) return 30;

    return 10;
  }
}
import '../../../shared/models/laterbox_item.dart';

/// A matched item with a relevance score used to order search results.
class SearchResult {
  const SearchResult({required this.item, required this.relevance});

  final LaterBoxItem item;

  /// Higher is better; see `SearchRepository` for the scoring rules.
  final int relevance;
}
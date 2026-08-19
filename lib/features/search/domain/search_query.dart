/// A raw search term entered by the user. Kept as a value object so the
/// repository and screen agree on trimming semantics.
class SearchQuery {
  const SearchQuery(this.value);

  factory SearchQuery.raw(String value) => SearchQuery(value.trim());

  final String value;

  bool get isEmpty => value.isEmpty;

  String get trimmed => value.trim();
}

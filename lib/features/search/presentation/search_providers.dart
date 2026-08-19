import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/database/database_providers.dart';
import '../data/search_repository.dart';
import '../domain/search_query.dart';
import '../domain/search_result.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(
    ref.watch(localItemDataSourceProvider),
    () => ref.watch(activeUserIdProvider),
  );
});

/// Currently active content-type filter chip, if any.
final searchContentTypeProvider = StateProvider<String?>((ref) => null);

final searchResultsProvider = StreamProvider<List<SearchResult>>((ref) {
  final raw = ref.watch(searchQueryProvider);
  final type = ref.watch(searchContentTypeProvider);
  return ref
      .watch(searchRepositoryProvider)
      .search(SearchQuery.raw(raw), contentType: type);
});
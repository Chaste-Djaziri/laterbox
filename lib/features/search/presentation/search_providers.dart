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

final searchResultsProvider = StreamProvider<List<SearchResult>>((ref) {
  final raw = ref.watch(searchQueryProvider);
  return ref.watch(searchRepositoryProvider).search(SearchQuery.raw(raw));
});
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/enrichment/domain/content_type.dart';
import '../../../features/library/presentation/library_providers.dart';
import '../../../shared/models/laterbox_item.dart';
import '../../../shared/widgets/item_card.dart';
import 'search_providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) {
    ref.read(searchQueryProvider.notifier).state = value;
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);
    final recent = ref.watch(allItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.6),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _controller,
                onChanged: _setQuery,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search laterbox',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _controller.clear();
                            _setQuery('');
                          },
                        ),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                ),
             ),
             _TypeFilterChips(),
             Expanded(
               child: query.trim().isEmpty
                  ? _RecentList(items: recent)
                  : results.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator.adaptive(),
                      ),
                      error: (error, stackTrace) => Center(
                        child: Text('Search failed: $error'),
                      ),
                      data: (results) => results.isEmpty
                          ? _NoResults(query: query)
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 4, 20, 104),
                              itemCount: results.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) =>
                                  ItemCard(item: results[index].item),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({required this.items});

  final AsyncValue<List<LaterBoxItem>> items;

  @override
  Widget build(BuildContext context) {
    return items.when(
      loading: () =>
          const Center(child: CircularProgressIndicator.adaptive()),
      error: (error, stackTrace) => const _SearchHint(),
      data: (items) => items.isEmpty
          ? const _SearchHint()
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 104),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Recent',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                for (final item in items) ...[
                  ItemCard(item: item),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No results for “$query”',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _SearchHint extends StatelessWidget {
  const _SearchHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'Search your saved links, notes and metadata.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// Horizontal filter chips for the current user's content types. Selecting a
/// type re-scopes [searchResultsProvider] to that type via
/// [searchContentTypeProvider]; selecting again (or tapping "x" on a chip)
/// clears the filter. Only types that contain items are shown.
class _TypeFilterChips extends ConsumerWidget {
  const _TypeFilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(libraryTypeCountsProvider);
    final active = ref.watch(searchContentTypeProvider);
    return counts.when(
      loading: () => const SizedBox(height: 40),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (counts) {
        if (counts.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (typeString, count) in counts)
                _TypeChip(
                  type: ContentType.fromString(typeString),
                  count: count,
                  selected: active == typeString,
                  onTap: () => ref
                      .read(searchContentTypeProvider.notifier)
                      .state = active == typeString ? null : typeString,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final ContentType type;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: Icon(type.icon, size: 18),
      label: Text('${type.label} ($count)'),
      selected: selected,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
    );
  }
}
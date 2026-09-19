import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/settings/item_view_mode.dart';
import '../../../features/enrichment/domain/content_type.dart';
import '../../../features/library/presentation/library_providers.dart';
import '../../../shared/models/laterbox_item.dart';
import '../../../shared/widgets/item_card.dart';
import '../../../shared/widgets/item_list_row.dart';
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
    final viewMode = ref.watch(itemViewModeProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 8,
                16,
                16,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: _setQuery,
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search your items…',
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFFA09E95)
                              : const Color(0xFF6C6B63),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDark
                              ? const Color(0xFFA09E95)
                              : const Color(0xFF6C6B63),
                          size: 20,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 0,
                        ),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                icon: const Icon(Icons.close_rounded, size: 20),
                                onPressed: () {
                                  _controller.clear();
                                  _setQuery('');
                                },
                              ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF2A2A28)
                            : const Color(0xFFF0EDE5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Back',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                  ),
                ],
              ),
            ),
            _TypeFilterChips(),
              Expanded(
                child: query.trim().isEmpty
                    ? _RecentList(items: recent, viewMode: viewMode)
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
                                    SizedBox(height: viewMode.isCards ? 12 : 8),
                                itemBuilder: (context, index) =>
                                    viewMode.isCards
                                        ? ItemCard(item: results[index].item)
                                        : ItemListRow(item: results[index].item),
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
  const _RecentList({required this.items, required this.viewMode});

  final AsyncValue<List<LaterBoxItem>> items;
  final ItemViewMode viewMode;

  @override
  Widget build(BuildContext context) {
    return items.when(
      loading: () =>
          const Center(child: CircularProgressIndicator.adaptive()),
      error: (error, stackTrace) => const _SearchHint(),
      data: (items) => items.isEmpty
          ? const _SearchHint()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 104),
              itemCount: items.length + 1,
              separatorBuilder: (context, index) =>
                  index == 0
                      ? const SizedBox(height: 8)
                      : SizedBox(height: viewMode.isCards ? 12 : 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Text(
                    'Recent',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                  );
                }
                final item = items[index - 1];
                return viewMode.isCards
                    ? ItemCard(item: item)
                    : ItemListRow(item: item);
              },
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
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: counts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final (typeString, count) = counts[index];
                return _TypeChip(
                  type: ContentType.fromString(typeString),
                  count: count,
                  selected: active == typeString,
                  onTap: () => ref
                      .read(searchContentTypeProvider.notifier)
                      .state = active == typeString ? null : typeString,
                );
              },
            ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? Colors.white : const Color(0xFF171711))
              : (isDark ? const Color(0xFF2A2A28) : const Color(0xFFF0EDE5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? (isDark ? Colors.white : const Color(0xFF171711))
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE4E0D5)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 16,
              color: selected
                  ? (isDark ? const Color(0xFF171711) : Colors.white)
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? (isDark ? const Color(0xFF171711) : Colors.white)
                    : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? (isDark
                        ? const Color(0xFF171711).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.2))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFE4E0D5)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? (isDark ? const Color(0xFF171711) : Colors.white)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
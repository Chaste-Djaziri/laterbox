import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/enrichment/domain/content_type.dart';
import '../../features/inbox/presentation/inbox_providers.dart';

class FilterChipBar extends ConsumerWidget {
  const FilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilter = ref.watch(inboxFilterProvider);
    final allItems = ref.watch(inboxItemsProvider).asData?.value ?? [];

    int getCount(InboxFilterType filter) {
      if (filter == InboxFilterType.all) return allItems.length;
      return allItems.where((item) {
        switch (filter) {
          case InboxFilterType.starred:
            return item.favorite;
          case InboxFilterType.notes:
            return item.url == null ||
                (item.text != null && item.text!.isNotEmpty);
          case InboxFilterType.articles:
            return item.metadata?.classification?.type == ContentType.article;
          case InboxFilterType.videos:
            return item.metadata?.classification?.type == ContentType.video;
          case InboxFilterType.music:
            return item.metadata?.classification?.type == ContentType.music;
          case InboxFilterType.all:
            return true;
        }
      }).length;
    }

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: InboxFilterType.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = InboxFilterType.values[index];
          final isSelected = activeFilter == filter;
          final count = getCount(filter);

          return _FilterChipTile(
            filter: filter,
            isSelected: isSelected,
            count: count,
            onSelected: () {
              ref.read(inboxFilterProvider.notifier).state = filter;
            },
          );
        },
      ),
    );
  }
}

class _FilterChipTile extends StatefulWidget {
  const _FilterChipTile({
    required this.filter,
    required this.isSelected,
    required this.count,
    required this.onSelected,
  });

  final InboxFilterType filter;
  final bool isSelected;
  final int count;
  final VoidCallback onSelected;

  @override
  State<_FilterChipTile> createState() => _FilterChipTileState();
}

class _FilterChipTileState extends State<_FilterChipTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backgroundColor = widget.isSelected
        ? theme.colorScheme.primaryContainer
        : (_isHovered
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerLowest);

    final foregroundColor = widget.isSelected
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;

    final borderColor = widget.isSelected
        ? theme.colorScheme.primary.withOpacity(0.5)
        : (_isHovered
            ? theme.colorScheme.outline
            : theme.colorScheme.outlineVariant.withOpacity(0.5));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onSelected,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.filter.icon,
                    size: 16,
                    color: foregroundColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.filter.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (widget.count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.count}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

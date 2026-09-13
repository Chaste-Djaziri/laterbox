import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/item_view_mode.dart';

/// A toggle control to switch between Cards and List view modes, mirroring
/// the view mode switcher on LaterBox Web.
class ViewModeToggle extends ConsumerWidget {
  const ViewModeToggle({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(itemViewModeProvider);
    final notifier = ref.read(itemViewModeProvider.notifier);
    final theme = Theme.of(context);

    if (compact) {
      final nextMode =
          mode == ItemViewMode.cards ? ItemViewMode.list : ItemViewMode.cards;
      return IconButton(
        tooltip: nextMode.tooltip,
        icon: Icon(
          mode.isCards ? Icons.view_list_rounded : Icons.grid_view_rounded,
        ),
        onPressed: notifier.toggle,
      );
    }

    return Container(
      height: 36,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            icon: Icons.grid_view_rounded,
            tooltip: 'Cards view',
            isSelected: mode.isCards,
            onTap: () => notifier.setViewMode(ItemViewMode.cards),
          ),
          const SizedBox(width: 2),
          _ToggleOption(
            icon: Icons.view_list_rounded,
            tooltip: 'List view',
            isSelected: mode.isList,
            onTap: () => notifier.setViewMode(ItemViewMode.list),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 17,
            color: isSelected
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

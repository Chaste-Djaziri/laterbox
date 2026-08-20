import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';

class DesktopSidebar extends ConsumerStatefulWidget {
  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onOpenCapture,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onOpenCapture;

  @override
  ConsumerState<DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends ConsumerState<DesktopSidebar> {
  bool _isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = _isCollapsed || width < 1000;
    final isMac = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final isGuest = ref.watch(guestModeProvider);

    final String userEmail = authState.asData?.value.email ??
        (isGuest ? 'Guest Mode' : 'Account');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: isCompact ? 76 : 240,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: isMac ? 36 : 16),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 12 : 16,
              vertical: 8,
            ),
            child: Row(
              mainAxisAlignment: isCompact
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.colorScheme.primaryContainer.withOpacity(0.6),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          'assets/branding/laterbox-icon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.bookmark_rounded,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 12),
                      Text(
                        'LaterBox',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!isCompact)
                  IconButton(
                    icon: Icon(
                      Icons.keyboard_double_arrow_left_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Collapse sidebar',
                    onPressed: () => setState(() => _isCollapsed = true),
                  ),
              ],
            ),
          ),
          if (isCompact)
            IconButton(
              icon: Icon(
                Icons.keyboard_double_arrow_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Expand sidebar',
              onPressed: () => setState(() => _isCollapsed = false),
            ),
          const SizedBox(height: 12),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
            child: isCompact
                ? IconButton.filled(
                    onPressed: widget.onOpenCapture,
                    icon: const Icon(Icons.add_rounded),
                    tooltip: 'Save item',
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: widget.onOpenCapture,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text(
                      'Save Item',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 12),

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
              children: [
                _SidebarTabItem(
                  index: 0,
                  selectedIndex: widget.selectedIndex,
                  isCompact: isCompact,
                  label: 'Inbox',
                  icon: Icons.inbox_outlined,
                  selectedIcon: Icons.inbox_rounded,
                  onTap: () => widget.onDestinationSelected(0),
                ),
                const SizedBox(height: 4),
                _SidebarTabItem(
                  index: 1,
                  selectedIndex: widget.selectedIndex,
                  isCompact: isCompact,
                  label: 'Search',
                  icon: Icons.search_rounded,
                  selectedIcon: Icons.search_rounded,
                  onTap: () => widget.onDestinationSelected(1),
                ),
                const SizedBox(height: 4),
                _SidebarTabItem(
                  index: 2,
                  selectedIndex: widget.selectedIndex,
                  isCompact: isCompact,
                  label: 'Library',
                  icon: Icons.auto_stories_outlined,
                  selectedIcon: Icons.auto_stories_rounded,
                  onTap: () => widget.onDestinationSelected(2),
                ),
              ],
            ),
          ),

          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.all(isCompact ? 8 : 12),
            child: isCompact
                ? Tooltip(
                    message: userEmail,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                userEmail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                isGuest ? 'Local storage' : 'Synced',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarTabItem extends StatefulWidget {
  const _SidebarTabItem({
    required this.index,
    required this.selectedIndex,
    required this.isCompact,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.onTap,
  });

  final int index;
  final int selectedIndex;
  final bool isCompact;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final VoidCallback onTap;

  @override
  State<_SidebarTabItem> createState() => _SidebarTabItemState();
}

class _SidebarTabItemState extends State<_SidebarTabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.index == widget.selectedIndex;
    final theme = Theme.of(context);

    final colorScheme = theme.colorScheme;
    final backgroundColor = isSelected
        ? colorScheme.primaryContainer.withOpacity(0.7)
        : (_isHovered
            ? colorScheme.surfaceContainerHighest.withOpacity(0.6)
            : Colors.transparent);

    final foregroundColor = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    final content = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCompact ? 0 : 12,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border(
                    left: BorderSide(
                      color: colorScheme.primary,
                      width: 3,
                    ),
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: widget.isCompact
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                isSelected ? widget.selectedIcon : widget.icon,
                color: foregroundColor,
                size: 22,
              ),
              if (!widget.isCompact) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.isCompact) {
      return Tooltip(
        message: widget.label,
        child: content,
      );
    }

    return content;
  }
}

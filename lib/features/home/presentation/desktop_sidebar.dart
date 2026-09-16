import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/billing/billing_providers.dart';
import '../../../core/billing/entitlement.dart';
import '../../../core/billing/entitlement_presentation.dart';
import '../../../shared/widgets/cloud_sync_indicator.dart';
import '../../inbox/presentation/inbox_providers.dart';

class DesktopSidebar extends ConsumerWidget {
  const DesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onOpenCapture,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onOpenCapture;

  static const double sidebarWidth = 268.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMac = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authState = ref.watch(authStateProvider);
    final isGuest = ref.watch(guestModeProvider);
    final inboxCount = ref.watch(inboxItemsProvider).valueOrNull?.length ?? 0;
    final entitlement =
        ref.watch(entitlementProvider).valueOrNull ?? const Entitlement.free();

    final String userEmail =
        authState.asData?.value.email ?? (isGuest ? 'Guest Mode' : 'Account');

    // Palette aligned with laterbox-web design tokens (globals.css & AppSidebar.tsx)
    final sidebarBg = isDark ? const Color(0xFF161614) : const Color(0xFFF7F5EE);
    final sidebarBorder = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE4E0D5);
    final textPrimary = isDark ? Colors.white : const Color(0xFF171711);
    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE4E0D5).withValues(alpha: 0.8);

    String currentPath = '';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {}

    final navEntries = [
      _NavEntry(label: 'Home', icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, path: '/home', tabIndex: 0),
      _NavEntry(label: 'Inbox', icon: Icons.inbox_outlined, selectedIcon: Icons.inbox_rounded, path: '/inbox', tabIndex: 1, badgeCount: inboxCount),
      _NavEntry(label: 'Today', icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today_rounded, path: '/today', tabIndex: 2),
      _NavEntry(label: 'Upcoming', icon: Icons.event_outlined, selectedIcon: Icons.event_rounded, path: '/upcoming', tabIndex: 3),
      _NavEntry(label: 'Someday', icon: Icons.schedule_outlined, selectedIcon: Icons.schedule_rounded, path: '/someday', tabIndex: 4),
      _NavEntry(label: 'Library', icon: Icons.auto_stories_outlined, selectedIcon: Icons.auto_stories_rounded, path: '/library', tabIndex: 5),
      _NavEntry(label: 'Guide', icon: Icons.explore_outlined, selectedIcon: Icons.explore_rounded, path: '/tutorial'),
      _NavEntry(label: 'Apps', icon: Icons.download_rounded, selectedIcon: Icons.download_rounded, path: 'https://laterbox.dev/download', isExternal: true),
      _NavEntry(label: 'Plans', icon: Icons.workspace_premium_rounded, selectedIcon: Icons.workspace_premium_rounded, path: '/plans'),
      _NavEntry(label: 'Settings', icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded, path: '/settings', tabIndex: 6),
    ];

    return Container(
      width: DesktopSidebar.sidebarWidth,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(
            color: sidebarBorder,
            width: 1,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 160;

          return Column(
            children: [
              // Safe top padding for macOS traffic lights (40px) or standard desktop header (16px)
              SizedBox(height: isMac ? 40 : 16),

              // Header: Brand (no collapse icon)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFE6EDB0),
                        border: isDark
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 1,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.35 : 0.08,
                            ),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4.5),
                      child: Image.asset(
                        isDark
                            ? 'assets/branding/laterbox-icon-white.png'
                            : 'assets/branding/laterbox-icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.bookmark_rounded,
                          color: textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'laterbox',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Quick Capture "Save Item" Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isCompact
                    ? Tooltip(
                        message: defaultTargetPlatform == TargetPlatform.windows
                            ? 'Save Item (Ctrl + Shift + L)'
                            : 'Save Item (⌃ ⌥ Space)',
                        child: Material(
                          color: isDark ? const Color(0xFFE6EDB0) : const Color(0xFF171711),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            canRequestFocus: false,
                            onTap: onOpenCapture,
                            borderRadius: BorderRadius.circular(12),
                            hoverColor: Colors.transparent,
                            child: SizedBox(
                              width: 42,
                              height: 42,
                              child: Icon(
                                Icons.add_rounded,
                                size: 20,
                                color: isDark ? const Color(0xFF171711) : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Material(
                        color: isDark ? const Color(0xFFE6EDB0) : const Color(0xFF171711),
                        borderRadius: BorderRadius.circular(12),
                        elevation: 0,
                        child: InkWell(
                          canRequestFocus: false,
                          onTap: onOpenCapture,
                          borderRadius: BorderRadius.circular(12),
                          hoverColor: Colors.transparent,
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  size: 18,
                                  color: isDark ? const Color(0xFF171711) : Colors.white,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Save Item',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFF171711) : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),

              // Subtle Divider
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                color: dividerColor,
              ),

              // Scrollable Navigation Link Pills (no hover state)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: navEntries.length,
                  itemBuilder: (context, index) {
                    final entry = navEntries[index];
                    final isSelected = _isEntrySelected(entry, currentPath);

                    return _SidebarTabItem(
                      entry: entry,
                      isSelected: isSelected,
                      isCompact: isCompact,
                      onTap: () => _handleNavTap(context, entry),
                    );
                  },
                ),
              ),

              // Bottom Pro Plan, Cloud Sync & User Profile
              Container(
                padding: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: dividerColor, width: 1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PlanStatusCard(
                      compact: isCompact,
                      entitlement: entitlement,
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: CloudSyncIndicator(compact: isCompact),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _UserCard(
                        userEmail: userEmail,
                        isGuest: isGuest,
                        compact: isCompact,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isEntrySelected(_NavEntry entry, String currentPath) {
    if (entry.isExternal) {
      return false;
    }
    if (entry.tabIndex != null) {
      return entry.tabIndex == selectedIndex;
    }
    if (currentPath.isNotEmpty) {
      if (entry.path == '/home') {
        return currentPath == '/home' || currentPath == '/';
      }
      return currentPath.startsWith(entry.path);
    }
    return false;
  }

  void _handleNavTap(BuildContext context, _NavEntry entry) {
    if (entry.isExternal) {
      final uri = Uri.parse(entry.path);
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (entry.tabIndex != null) {
      onDestinationSelected(entry.tabIndex!);
    } else if (entry.path == '/search') {
      context.go('/search');
    } else {
      context.push(entry.path);
    }
  }
}

class _NavEntry {
  const _NavEntry({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
    this.tabIndex,
    this.badgeCount,
    this.isExternal = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  final int? tabIndex;
  final int? badgeCount;
  final bool isExternal;
}

class _SidebarTabItem extends StatefulWidget {
  const _SidebarTabItem({
    required this.entry,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final _NavEntry entry;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  State<_SidebarTabItem> createState() => _SidebarTabItemState();
}

class _SidebarTabItemState extends State<_SidebarTabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activePillBg = isDark ? const Color(0xFF2E331B) : const Color(0xFFE6EDB0);
    final activePillFg = isDark ? const Color(0xFFD7FF27) : const Color(0xFF171711);
    final inactivePillFg = isDark ? const Color(0xFFA09E95) : const Color(0xFF6C6B63);

    final badgeActiveBg = isDark ? const Color(0xFF3F4625) : const Color(0xFFD8E09E);
    final badgeInactiveBg = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFEBE7DC);

    final isHovered = _isHovered;
    final backgroundColor = widget.isSelected
        ? activePillBg
        : isHovered
            ? (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04))
            : Colors.transparent;
    final foregroundColor = widget.isSelected
        ? activePillFg
        : isHovered
            ? (isDark ? Colors.white : const Color(0xFF171711))
            : inactivePillFg;

    final content = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          canRequestFocus: false,
          borderRadius: BorderRadius.circular(12),
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: widget.onTap,
          child: Container(
          height: 42,
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 0 : 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: widget.isCompact
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      widget.isSelected ? widget.entry.selectedIcon : widget.entry.icon,
                      color: foregroundColor,
                      size: 18,
                    ),
                    if (!widget.isCompact) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: foregroundColor,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!widget.isCompact && (widget.entry.badgeCount ?? 0) > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: widget.isSelected ? badgeActiveBg : badgeInactiveBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.entry.badgeCount}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: widget.isSelected ? activePillFg : inactivePillFg,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    );

    if (widget.isCompact) {
      return Tooltip(message: widget.entry.label, child: content);
    }

    return content;
  }
}

class _PlanStatusCard extends StatelessWidget {
  const _PlanStatusCard({
    required this.compact,
    required this.entitlement,
  });

  final bool compact;
  final Entitlement entitlement;

  @override
  Widget build(BuildContext context) {
    final presentation = EntitlementPresentation.from(entitlement);
    final warning = presentation.severity == EntitlementSeverity.warning;
    final color = warning ? Colors.amber : const Color(0xFFD7FF27);

    final card = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        canRequestFocus: false,
        onTap: () {
          if (entitlement.hasProAccess) {
            context.go('/settings');
          } else {
            context.push('/plans');
          }
        },
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.transparent,
        child: Container(
        margin: EdgeInsets.symmetric(horizontal: compact ? 8 : 14),
        padding: EdgeInsets.all(compact ? 8 : 12),
        decoration: BoxDecoration(
          color: const Color(0xFF171711),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: warning ? Colors.amber.shade700 : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: compact
            ? SizedBox(
                width: 30,
                height: 30,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (presentation.progress != null)
                      CircularProgressIndicator(
                        value: presentation.progress,
                        strokeWidth: 2.5,
                        color: color,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                      ),
                    Icon(
                      Icons.workspace_premium_rounded,
                      size: 17,
                      color: color,
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 17,
                        color: color,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          presentation.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (presentation.progress != null) ...[
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: presentation.progress,
                        minHeight: 4,
                        color: color,
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    presentation.actionLabel,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
      ),
    ),
    );
    return compact ? Tooltip(message: presentation.label, child: card) : card;
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.userEmail,
    required this.isGuest,
    required this.compact,
  });

  final String userEmail;
  final bool isGuest;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark
        ? const Color(0xFF1F1F1C)
        : const Color(0xFFEBE7DC).withValues(alpha: 0.5);
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE4E0D5).withValues(alpha: 0.7);
    final textPrimary = isDark ? Colors.white : const Color(0xFF171711);
    final textMuted = isDark ? const Color(0xFFA09E95) : const Color(0xFF6C6B63);

    final avatarText = isGuest
        ? 'G'
        : (userEmail.isNotEmpty ? userEmail[0].toUpperCase() : 'U');

    if (compact) {
      return Tooltip(
        message: '$userEmail • ${isGuest ? "Sign In" : "Settings"}',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            canRequestFocus: false,
            onTap: () => isGuest ? context.push('/login') : context.go('/settings'),
            borderRadius: BorderRadius.circular(8),
            hoverColor: Colors.transparent,
            child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EDB0),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171711),
              ),
            ),
          ),
        ),
      ),
      );
    }

    if (isGuest) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6EDB0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF171711),
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
                        'Guest Mode',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Local storage',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Material(
              color: isDark ? const Color(0xFFE6EDB0) : const Color(0xFF171711),
              borderRadius: BorderRadius.circular(8),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: InkWell(
                  canRequestFocus: false,
                  onTap: () => context.push('/login'),
                  borderRadius: BorderRadius.circular(8),
                  hoverColor: Colors.transparent,
                  child: Container(
                  height: 32,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.login_rounded,
                        size: 13,
                        color: isDark ? const Color(0xFF171711) : Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Sign In / Sync',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFF171711) : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFE6EDB0),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF171711),
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: InkWell(
              canRequestFocus: false,
              onTap: () => context.go('/settings'),
              borderRadius: BorderRadius.circular(6),
              hoverColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Icon(
                  Icons.settings_outlined,
                  size: 17,
                  color: textMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

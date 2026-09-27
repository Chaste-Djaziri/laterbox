import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../capture/presentation/capture_sheet.dart';
import '../../../core/billing/billing_providers.dart';
import '../../../core/billing/entitlement.dart';
import '../../../core/billing/entitlement_presentation.dart';
import '../../inbox/presentation/inbox_providers.dart';
import '../../inbox/presentation/inbox_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import 'desktop_sidebar.dart';
import 'home_dashboard.dart';
import '../../scheduling/presentation/schedule_providers.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({
    super.key,
    required this.selectedIndex,
    this.navigationShell,
    this.child,
  });

  final int selectedIndex;
  final StatefulNavigationShell? navigationShell;
  final Widget? child;

  static const List<Widget> _screens = [
    HomeDashboard(),
    InboxScreen(),
    ScheduleScreen(view: ScheduleView.today),
    ScheduleScreen(view: ScheduleView.upcoming),
    ScheduleScreen(view: ScheduleView.someday),
    LibraryScreen(),
    SettingsScreen(),
  ];
  static const List<String> _paths = [
    '/home',
    '/inbox',
    '/today',
    '/upcoming',
    '/someday',
    '/library',
    '/settings',
  ];

  Future<void> _openCapture(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      return showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (_) => const CaptureSheet(),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => const CaptureSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = _isDesktopPlatform() || width >= 900;
    final isMacDesktop =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
    final theme = Theme.of(context);
    final desktopChromeColor = isMacDesktop
        ? const Color(0xFF2B2B2B)
        : theme.brightness == Brightness.dark
        ? const Color(0xFF161614)
        : const Color(0xFFF7F5EE);
    final effectiveIndex = (navigationShell?.currentIndex ?? selectedIndex)
        .clamp(0, _paths.length - 1);
    final Widget bodyContent =
        child ?? navigationShell ?? _screens[effectiveIndex];
    final inboxCount =
        ref
            .watch(inboxItemsProvider)
            .whenOrNull(data: (items) => items.length) ??
        0;

    void handleDestinationSelected(int index) {
      if (navigationShell != null) {
        navigationShell!.goBranch(
          index,
          initialLocation: index == navigationShell!.currentIndex,
        );
      } else {
        context.go(_paths[index]);
      }
    }

    return Scaffold(
      body: isDesktop
          ? ColoredBox(
              // The transparent native title bar reveals this same color behind
              // the traffic lights, so it joins the sidebar instead of reading
              // as a detached system strip.
              color: desktopChromeColor,
              child: Column(
                children: [
                  if (isMacDesktop) const SizedBox(height: 32),
                  Expanded(
                    child: Row(
                      children: [
                        DesktopSidebar(
                          selectedIndex: effectiveIndex,
                          onDestinationSelected: handleDestinationSelected,
                          onOpenCapture: () => _openCapture(context),
                          topInset: isMacDesktop ? 8 : null,
                        ),
                        Expanded(
                          child: ColoredBox(
                            color: theme.scaffoldBackgroundColor,
                            child: bodyContent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : bodyContent,
      bottomNavigationBar: isDesktop
          ? null
          : _isIOS(context)
          ? _IOSBottomNavigation(
              selectedIndex: _iosNavigationIndex(effectiveIndex),
              inboxCount: inboxCount,
              onDestinationSelected: (index) =>
                  handleDestinationSelected(const [0, 1, 2, 5, 6][index]),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _MobilePlanStatus(),
                NavigationBar(
                  selectedIndex: effectiveIndex == 1
                      ? 1
                      : effectiveIndex == 5
                      ? 2
                      : effectiveIndex == 6
                      ? 3
                      : 0,
                  onDestinationSelected: (index) =>
                      handleDestinationSelected(const [0, 1, 5, 6][index]),
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: inboxCount > 0,
                        label: Text('$inboxCount'),
                        child: const Icon(Icons.inbox_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: inboxCount > 0,
                        label: Text('$inboxCount'),
                        child: const Icon(Icons.inbox_rounded),
                      ),
                      label: 'Inbox',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.auto_stories_outlined),
                      selectedIcon: Icon(Icons.auto_stories_rounded),
                      label: 'Library',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: 'Settings',
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: (!isDesktop && effectiveIndex != 6)
          ? (_isIOS(context)
                ? FloatingActionButton(
                    onPressed: () => _openCapture(context),
                    tooltip: 'Save something',
                    child: const Icon(Icons.add_rounded),
                  )
                : FloatingActionButton.large(
                    onPressed: () => _openCapture(context),
                    tooltip: 'Save something',
                    child: const Icon(Icons.add_rounded, size: 32),
                  ))
          : null,
    );
  }
}

int _iosNavigationIndex(int routeIndex) {
  if (routeIndex >= 2 && routeIndex <= 4) return 2;
  if (routeIndex == 5) return 3;
  if (routeIndex == 6) return 4;
  return routeIndex == 1 ? 1 : 0;
}

class _IOSBottomNavigation extends StatelessWidget {
  const _IOSBottomNavigation({
    required this.selectedIndex,
    required this.inboxCount,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final int inboxCount;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF161614) : const Color(0xFFF7F5EE);
    final active = isDark ? const Color(0xFFD7FF27) : const Color(0xFF171711);
    final inactive = isDark ? const Color(0xFFA09E95) : const Color(0xFF6C6B63);

    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: onDestinationSelected,
      backgroundColor: surface.withValues(alpha: 0.96),
      activeColor: active,
      inactiveColor: inactive,
      border: Border(top: BorderSide(color: inactive.withValues(alpha: 0.18))),
      items: [
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.house),
          activeIcon: Icon(CupertinoIcons.house_fill),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: _IOSInboxIcon(count: inboxCount, filled: false),
          activeIcon: _IOSInboxIcon(count: inboxCount, filled: true),
          label: 'Inbox',
        ),
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.calendar),
          activeIcon: Icon(CupertinoIcons.calendar_today),
          label: 'Returns',
        ),
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.book),
          activeIcon: Icon(CupertinoIcons.book_fill),
          label: 'Library',
        ),
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.gear),
          activeIcon: Icon(CupertinoIcons.gear_solid),
          label: 'Settings',
        ),
      ],
    );
  }
}

class _IOSInboxIcon extends StatelessWidget {
  const _IOSInboxIcon({required this.count, required this.filled});

  final int count;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Icon(filled ? CupertinoIcons.tray_fill : CupertinoIcons.tray);
    }
    return Badge(
      label: Text('$count'),
      child: Icon(filled ? CupertinoIcons.tray_fill : CupertinoIcons.tray),
    );
  }
}

bool _isIOS(BuildContext context) {
  if (kIsWeb) return false;
  return Theme.of(context).platform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class _MobilePlanStatus extends ConsumerWidget {
  const _MobilePlanStatus();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement =
        ref.watch(entitlementProvider).valueOrNull ?? const Entitlement.free();
    final plan = EntitlementPresentation.from(entitlement);
    final warning = plan.severity == EntitlementSeverity.warning;
    return Material(
      color: warning
          ? Colors.amber.shade50
          : Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () {
          if (entitlement.hasProAccess) {
            context.go('/settings');
          } else {
            context.push('/plans');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: 17,
                color: warning
                    ? Colors.amber.shade900
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  plan.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                plan.actionLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: warning
                      ? Colors.amber.shade900
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isDesktopPlatform() {
  if (kIsWeb) return false;
  return switch (defaultTargetPlatform) {
    TargetPlatform.macOS ||
    TargetPlatform.linux ||
    TargetPlatform.windows => true,
    _ => false,
  };
}

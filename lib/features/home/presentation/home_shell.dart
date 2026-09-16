import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../capture/presentation/capture_sheet.dart';
import '../../../core/billing/billing_providers.dart';
import '../../../core/billing/entitlement.dart';
import '../../../core/billing/entitlement_presentation.dart';
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
    final effectiveIndex = (navigationShell?.currentIndex ?? selectedIndex)
        .clamp(0, _paths.length - 1);
    final Widget bodyContent =
        child ?? navigationShell ?? _screens[effectiveIndex];

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
          ? Row(
              children: [
                DesktopSidebar(
                  selectedIndex: effectiveIndex,
                  onDestinationSelected: handleDestinationSelected,
                  onOpenCapture: () => _openCapture(context),
                ),
                Expanded(child: bodyContent),
              ],
            )
          : bodyContent,
      bottomNavigationBar: isDesktop
          ? null
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
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.inbox_outlined),
                      selectedIcon: Icon(Icons.inbox_rounded),
                      label: 'Inbox',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.auto_stories_outlined),
                      selectedIcon: Icon(Icons.auto_stories_rounded),
                      label: 'Library',
                    ),
                    NavigationDestination(
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

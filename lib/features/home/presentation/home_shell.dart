import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../capture/presentation/capture_sheet.dart';
import '../../inbox/presentation/inbox_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../search/presentation/search_screen.dart';
import 'desktop_sidebar.dart';

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
    InboxScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];
  static const List<String> _paths = ['/inbox', '/search', '/library'];

  Future<void> _openCapture(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => const CaptureSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = _isDesktopPlatform() || width >= 900;
    final effectiveIndex = navigationShell?.currentIndex ?? selectedIndex;
    final Widget bodyContent = child ?? navigationShell ?? _screens[effectiveIndex];

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
          : NavigationBar(
              selectedIndex: effectiveIndex,
              onDestinationSelected: handleDestinationSelected,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.inbox_outlined),
                  selectedIcon: Icon(Icons.inbox_rounded),
                  label: 'Inbox',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_rounded),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories_rounded),
                  label: 'Library',
                ),
              ],
            ),
      floatingActionButton: (!isDesktop && effectiveIndex == 0)
          ? FloatingActionButton.large(
              onPressed: () => _openCapture(context),
              tooltip: 'Save something',
              child: const Icon(Icons.add_rounded, size: 32),
            )
          : null,
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

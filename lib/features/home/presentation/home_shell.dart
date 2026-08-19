import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../capture/presentation/capture_sheet.dart';
import '../../inbox/presentation/inbox_screen.dart';
import '../../library/presentation/library_screen.dart';
import '../../search/presentation/search_screen.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.selectedIndex});

  final int selectedIndex;

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

    return Scaffold(
      body: isDesktop
          ? Row(
              children: [
                _DesktopSidebar(
                  selectedIndex: selectedIndex,
                  extended: width >= 1100,
                  onDestinationSelected: (index) => context.go(_paths[index]),
                ),
                Expanded(child: _screens[selectedIndex]),
              ],
            )
          : _screens[selectedIndex],
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => context.go(_paths[index]),
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
      floatingActionButton: selectedIndex == 0
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

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.extended,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        extended: extended,
        minWidth: 76,
        minExtendedWidth: 220,
        groupAlignment: -0.7,
        leading: Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 36),
          child: Text(
            'LaterBox',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.6),
          ),
        ),
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.inbox_outlined),
            selectedIcon: Icon(Icons.inbox_rounded),
            label: Text('Inbox'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.search_rounded),
            label: Text('Search'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories_rounded),
            label: Text('Library'),
          ),
        ],
      ),
    );
  }
}

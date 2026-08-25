import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../shared/widgets/cloud_sync_indicator.dart';
import '../../../shared/widgets/filter_chip_bar.dart';
import '../../../shared/widgets/item_card.dart';
import '../../capture/presentation/capture_sheet.dart';
import 'inbox_providers.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(syncCoordinatorProvider).syncNow();
    ref.invalidate(inboxItemsProvider);
  }

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
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final platform = Theme.of(context).platform;
    final isDesktop = !kIsWeb
        ? (platform == TargetPlatform.macOS ||
              platform == TargetPlatform.linux ||
              platform == TargetPlatform.windows)
        : width >= 900;

    final rawItems = ref.watch(inboxItemsProvider);
    final filteredItems = ref.watch(filteredInboxItemsProvider);
    final auth = ref.watch(authStateProvider).asData?.value;
    final theme = Theme.of(context);
    final isMac = !kIsWeb && platform == TargetPlatform.macOS;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: width < 480
                  ? Image.asset(
                      'assets/branding/laterbox-icon.png',
                      width: 28,
                      height: 28,
                      fit: BoxFit.contain,
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/branding/laterbox-icon.png',
                          width: 26,
                          height: 26,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'laterbox',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ],
                    ),
              actions: [
                const CloudSyncIndicator(compact: true),
                IconButton(
                  onPressed: () => _openCapture(context),
                  tooltip: 'Quick Save',
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
                IconButton(
                  onPressed: () => context.go('/search'),
                  tooltip: 'Search',
                  icon: const Icon(Icons.search),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: 'Shortcuts & Menu',
                  onSelected: (value) async {
                    switch (value) {
                      case 'capture':
                        _openCapture(context);
                        break;
                      case 'kept':
                        context.go('/kept');
                        break;
                      case 'library':
                        context.go('/library');
                        break;
                      case 'tutorial':
                        context.push('/tutorial');
                        break;
                      case 'settings':
                        context.push('/settings');
                        break;
                      case 'signout':
                        await ref.read(authRepositoryProvider).signOut();
                        ref.read(guestModeProvider.notifier).state = true;
                        break;
                      case 'signin':
                        ref.read(guestModeProvider.notifier).state = false;
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'capture',
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Quick Save / Paste'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'kept',
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Kept Items'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'library',
                      child: Row(
                        children: [
                          Icon(Icons.auto_stories_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Library'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'tutorial',
                      child: Row(
                        children: [
                          Icon(Icons.help_outline_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Guide & Shortcuts'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, size: 20),
                          SizedBox(width: 12),
                          Text('Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    if (auth?.isAuthenticated ?? false)
                      const PopupMenuItem(
                        value: 'signout',
                        child: Row(
                          children: [
                            Icon(Icons.logout_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Sign out'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'signin',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Sign in'),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ),
      body: SafeArea(
        top: !isDesktop,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: isDesktop,
          child: RefreshIndicator.adaptive(
            onRefresh: _handleRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 32 : 20,
                    isDesktop ? (isMac ? 44 : 28) : 18,
                    isDesktop ? 32 : 20,
                    16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Inbox',
                                  style: theme.textTheme.headlineLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.1,
                                      ),
                                ),
                                if (rawItems.asData?.value
                                    case final list?) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${list.length} ${list.length == 1 ? 'item' : 'items'} saved',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (isDesktop)
                              Row(
                                children: [
                                  const CloudSyncIndicator(),
                                  const SizedBox(width: 12),
                                  TextButton.icon(
                                    onPressed: () => context.push('/tutorial'),
                                    icon: const Icon(
                                      Icons.help_outline_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('Tutorial'),
                                  ),
                                  const SizedBox(width: 8),
                                  if (auth?.isAuthenticated ?? false)
                                    TextButton.icon(
                                      onPressed: () async {
                                        await ref
                                            .read(authRepositoryProvider)
                                            .signOut();
                                        ref
                                                .read(
                                                  guestModeProvider.notifier,
                                                )
                                                .state =
                                            true;
                                      },
                                      icon: const Icon(
                                        Icons.logout_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('Sign out'),
                                    )
                                  else
                                    TextButton.icon(
                                      onPressed: () =>
                                          ref
                                                  .read(
                                                    guestModeProvider.notifier,
                                                  )
                                                  .state =
                                              false,
                                      icon: const Icon(
                                        Icons.person_outline_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('Sign in'),
                                    ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const FilterChipBar(),
                      ],
                    ),
                  ),
                ),
                filteredItems.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                  error: (error, stackTrace) => SliverFillRemaining(
                    child: _ErrorState(
                      onRetry: () => ref.invalidate(inboxItemsProvider),
                    ),
                  ),
                  data: (itemList) => itemList.isEmpty
                      ? const SliverFillRemaining(child: _EmptyInbox())
                      : isDesktop
                      ? SliverPadding(
                          padding: const EdgeInsets.fromLTRB(32, 0, 32, 104),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  ItemCard(item: itemList[index], isGrid: true),
                              childCount: itemList.length,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 320,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.72,
                                ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 104),
                          sliver: SliverList.separated(
                            itemCount: itemList.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) =>
                                ItemCard(item: itemList[index]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Nothing saved yet',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to save a link or note for later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Could not load your inbox.'),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

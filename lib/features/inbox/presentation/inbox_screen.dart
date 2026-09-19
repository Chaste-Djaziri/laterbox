import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/desktop/desktop_actions.dart';
import '../../../core/settings/item_view_mode.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../shared/widgets/cloud_sync_indicator.dart';
import '../../../shared/widgets/filter_chip_bar.dart';
import '../../../shared/widgets/item_card.dart';
import '../../../shared/widgets/item_list_row.dart';
import '../../../shared/widgets/view_mode_toggle.dart';
import '../../capture/presentation/capture_sheet.dart';
import 'inbox_providers.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus) {
        _searchFocusNode.unfocus();
        context.push('/search', extra: '/inbox');
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
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
      barrierColor: Colors.black.withValues(alpha: 0.65),
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (context) => const CaptureSheet(),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    ItemViewMode viewMode,
    LaterBoxAuthState? auth,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'Shortcuts & Menu',
      onSelected: (value) async {
        switch (value) {
          case 'toggle_view_mode':
            ref.read(itemViewModeProvider.notifier).toggle();
            break;
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
            context.go('/settings');
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
        PopupMenuItem(
          value: 'toggle_view_mode',
          child: Row(
            children: [
              Icon(
                viewMode.isCards
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
                size: 20,
              ),
              SizedBox(width: 12),
              Text(viewMode.isCards ? 'List view' : 'Cards view'),
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
    );
  }

  Widget _buildSearchInput(BuildContext context, ThemeData theme) {
    return InkWell(
      key: const Key('home_search_input'),
      onTap: () => context.go('/search'),
      borderRadius: BorderRadius.circular(14),
      child: IgnorePointer(
        child: TextField(
          focusNode: _searchFocusNode,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Search items, tags, notes...',
            hintStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceContainerHigh.withValues(
              alpha: 0.6,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 11,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
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
    final viewMode = ref.watch(itemViewModeProvider);
    final auth = ref.watch(authStateProvider).asData?.value;
    final theme = Theme.of(context);
    final isMac = !kIsWeb && platform == TargetPlatform.macOS;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              centerTitle: false,
              titleSpacing: 16,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/branding/laterbox-icon.png',
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Inbox',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  if (rawItems.asData?.value case final list?) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${list.length}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                const CloudSyncIndicator(compact: true),
                const SizedBox(width: 2),
                const ViewModeToggle(compact: true),
                _buildMenuButton(context, viewMode, auth),
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
                    isDesktop ? (isMac ? 44 : 28) : 12,
                    isDesktop ? 32 : 20,
                    16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isDesktop) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${list.length}',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isMac) ...[
                                    IconButton(
                                      onPressed: () => ref
                                          .read(desktopActionsProvider)
                                          .dockToNotch(),
                                      tooltip: 'Dock to Screen Notch',
                                      icon: const Icon(
                                        Icons.laptop_mac_rounded,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                  ],
                                  const CloudSyncIndicator(),
                                  const SizedBox(width: 8),
                                  ViewModeToggle(compact: !isDesktop),
                                  const SizedBox(width: 2),
                                  _buildMenuButton(context, viewMode, auth),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        _buildSearchInput(context, theme),
                        const SizedBox(height: 12),
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
                      ? (viewMode.isCards
                            ? SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  32,
                                  0,
                                  32,
                                  104,
                                ),
                                sliver: SliverGrid(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) => ItemCard(
                                      item: itemList[index],
                                      isGrid: true,
                                    ),
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
                                padding: const EdgeInsets.fromLTRB(
                                  32,
                                  0,
                                  32,
                                  104,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: itemList.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      ItemListRow(item: itemList[index]),
                                ),
                              ))
                      : (viewMode.isCards
                            ? SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  104,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: itemList.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (context, index) =>
                                      ItemCard(item: itemList[index]),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  104,
                                ),
                                sliver: SliverList.separated(
                                  itemCount: itemList.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      ItemListRow(item: itemList[index]),
                                ),
                              )),
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
              'You’re all clear',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Items appear here when their return time arrives.',
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

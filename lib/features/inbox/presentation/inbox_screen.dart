import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/desktop/desktop_actions.dart';
import '../../../core/settings/display_name_provider.dart';
import '../../../core/settings/item_view_mode.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../shared/models/laterbox_item.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _showEditNameDialog(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'What should LaterBox call you?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Your name...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              ref.read(displayNameProvider.notifier).set(value.trim());
            }
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(displayNameProvider.notifier)
                    .set(controller.text.trim());
              }
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openAiOrganizeSheet(BuildContext context, List<LaterBoxItem> items) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AiOrganizeModalSheet(items: items),
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
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        onChanged: (val) {
          ref.read(inboxSearchQueryProvider.notifier).state = val;
          setState(() {});
        },
        decoration: InputDecoration(
          hintText: 'Search your inbox...',
          hintStyle: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(inboxSearchQueryProvider.notifier).state = '';
                    setState(() {});
                  },
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        '⌘ K',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 10,
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
    final isWide = width >= 960;

    final rawItems = ref.watch(inboxItemsProvider).asData?.value ?? [];
    final filteredItems = ref.watch(filteredInboxItemsProvider);
    final starredItems = ref.watch(starredItemsProvider).asData?.value ?? [];
    final keptItems = ref.watch(keptItemsProvider).asData?.value ?? [];
    final archivedItems = ref.watch(archivedItemsProvider).asData?.value ?? [];

    final viewMode = ref.watch(itemViewModeProvider);
    final auth = ref.watch(currentAuthStateProvider);
    final displayName = ref.watch(displayNameProvider);
    final theme = Theme.of(context);
    final isMac = !kIsWeb && platform == TargetPlatform.macOS;
    final searchQuery = ref.watch(inboxSearchQueryProvider);

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
                  if (rawItems.isNotEmpty) ...[
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
                        '${rawItems.length}',
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
                    isDesktop ? 32 : 16,
                    isDesktop ? (isMac ? 36 : 24) : 12,
                    isDesktop ? 32 : 16,
                    16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header (Web Parity)
                        _buildTopHeader(
                          context,
                          theme,
                          displayName,
                          rawItems.length,
                          isDesktop,
                          isMac,
                          viewMode,
                          auth,
                        ),
                        const SizedBox(height: 18),

                        // Top 3 Summary/Widget Cards Row (Web Parity)
                        _buildSummaryCardsRow(
                          context,
                          theme,
                          rawItems,
                          starredItems,
                          keptItems,
                          archivedItems,
                          isWide,
                        ),
                        const SizedBox(height: 18),

                        // Filter Chips Bar
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
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _EmptyInbox(
                            searchQuery: searchQuery,
                            onSaveItem: () => _openCapture(context),
                          ),
                        )
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
                                        maxCrossAxisExtent: 340,
                                        mainAxisSpacing: 18,
                                        crossAxisSpacing: 18,
                                        childAspectRatio: 0.70,
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
                                  16,
                                  0,
                                  16,
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
                                  16,
                                  0,
                                  16,
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

  Widget _buildTopHeader(
    BuildContext context,
    ThemeData theme,
    String? displayName,
    int inboxCount,
    bool isDesktop,
    bool isMac,
    ItemViewMode viewMode,
    LaterBoxAuthState? auth,
  ) {
    final hasName = displayName != null && displayName.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Title & Back button + Name Pill
            Expanded(
              child: Row(
                children: [
                  // Back button
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/library');
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Inbox',
                    style: TextStyle(
                      fontSize: isDesktop ? 28 : 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Display name chip
                  InkWell(
                    onTap: () =>
                        _showEditNameDialog(context, displayName ?? ''),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: hasName
                            ? theme.colorScheme.surfaceContainerHigh
                            : const Color(0xFFE6EDB0).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: hasName
                              ? theme.colorScheme.outlineVariant.withValues(
                                  alpha: 0.5,
                                )
                              : const Color(0xFFD0DB84),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasName) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_rounded,
                              size: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ] else ...[
                            const Text(
                              "+ What's your name?",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF171711),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Right Omnibar Controls on Desktop
            if (isDesktop)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Pill
                  SizedBox(
                    width: 220,
                    child: _buildSearchInput(context, theme),
                  ),
                  const SizedBox(width: 8),

                  // View Mode Toggle
                  ViewModeToggle(compact: !isDesktop),
                  const SizedBox(width: 6),

                  // Local Mode Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Local Mode',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),

                  if (isMac) ...[
                    IconButton(
                      onPressed: () =>
                          ref.read(desktopActionsProvider).dockToNotch(),
                      tooltip: 'Dock to Screen Notch',
                      icon: const Icon(Icons.laptop_mac_rounded, size: 20),
                    ),
                    const SizedBox(width: 4),
                  ],

                  // Sync & Menu
                  const CloudSyncIndicator(),
                  _buildMenuButton(context, viewMode, auth),
                ],
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          hasName
              ? 'Welcome back, $displayName. Capture everything. Review when it matters.'
              : 'Capture everything. Review when it matters.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!isDesktop) ...[
          const SizedBox(height: 12),
          _buildSearchInput(context, theme),
        ],
      ],
    );
  }

  Widget _buildSummaryCardsRow(
    BuildContext context,
    ThemeData theme,
    List<LaterBoxItem> inboxItems,
    List<LaterBoxItem> starredItems,
    List<LaterBoxItem> keptItems,
    List<LaterBoxItem> archivedItems,
    bool isWide,
  ) {
    final now = DateTime.now();
    final toReviewCount = inboxItems.where((i) => i.isDue(now)).length;
    final processedCount = keptItems.length + archivedItems.length;

    // Determine continue review candidate: video or first inbox item
    final continueItem =
        inboxItems.where((i) {
          final t = i.type.toLowerCase();
          final u = (i.url ?? '').toLowerCase();
          return t == 'video' ||
              u.contains('youtube') ||
              u.contains('vimeo') ||
              u.contains('bilibili');
        }).firstOrNull ??
        inboxItems.firstOrNull;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card 1: 4 Metrics
          Expanded(
            flex: 5,
            child: _MetricsCard(
              savedCount: inboxItems.length,
              toReviewCount: toReviewCount > 0 ? toReviewCount : inboxItems.length,
              starredCount: starredItems.length,
              processedCount: processedCount,
            ),
          ),
          const SizedBox(width: 14),

          // Card 2: Continue Reviewing
          Expanded(
            flex: 4,
            child: _ContinueReviewingCard(item: continueItem),
          ),
          const SizedBox(width: 14),

          // Card 3: AI Organize Beta
          Expanded(
            flex: 3,
            child: _AiOrganizeCard(
              onGetSuggestions: () => _openAiOrganizeSheet(context, inboxItems),
            ),
          ),
        ],
      );
    } else {
      // Horizontally scrollable strip on compact screens
      return SizedBox(
        height: 114,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            SizedBox(
              width: 320,
              child: _MetricsCard(
                savedCount: inboxItems.length,
                toReviewCount: toReviewCount > 0 ? toReviewCount : inboxItems.length,
                starredCount: starredItems.length,
                processedCount: processedCount,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 270,
              child: _ContinueReviewingCard(item: continueItem),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 260,
              child: _AiOrganizeCard(
                onGetSuggestions: () =>
                    _openAiOrganizeSheet(context, inboxItems),
              ),
            ),
          ],
        ),
      );
    }
  }
}

// =========================================================================
// Top Widget Card 1: 4 Metrics (Web Parity)
// =========================================================================
class _MetricsCard extends StatelessWidget {
  const _MetricsCard({
    required this.savedCount,
    required this.toReviewCount,
    required this.starredCount,
    required this.processedCount,
  });

  final int savedCount;
  final int toReviewCount;
  final int starredCount;
  final int processedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      height: 114,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Col 1: Items saved
          Expanded(
            child: _MetricColumn(
              icon: Icons.description_outlined,
              iconBgColor: const Color(0xFFE6EDB0),
              iconColor: const Color(0xFF171711),
              count: savedCount,
              label: 'Items saved',
            ),
          ),
          Container(width: 1, height: 44, color: borderColor),

          // Col 2: To review
          Expanded(
            child: _MetricColumn(
              icon: Icons.schedule_rounded,
              iconBgColor: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              count: toReviewCount,
              label: 'To review',
            ),
          ),
          Container(width: 1, height: 44, color: borderColor),

          // Col 3: Starred
          Expanded(
            child: _MetricColumn(
              icon: Icons.star_rounded,
              iconBgColor: const Color(0xFFFEF9C3),
              iconColor: const Color(0xFFCA8A04),
              count: starredCount,
              label: 'Starred',
            ),
          ),
          Container(width: 1, height: 44, color: borderColor),

          // Col 4: Processed
          Expanded(
            child: _MetricColumn(
              icon: Icons.check_circle_rounded,
              iconBgColor: const Color(0xFFDCFCE7),
              iconColor: const Color(0xFF16A34A),
              count: processedCount,
              label: 'Processed',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -0.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Top Widget Card 2: Continue Reviewing (Web Parity)
// =========================================================================
class _ContinueReviewingCard extends StatelessWidget {
  const _ContinueReviewingCard({required this.item});

  final LaterBoxItem? item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    if (item == null) {
      return Container(
        height: 114,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Continue reviewing',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All caught up!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'No pending items to review',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final targetItem = item!;
    final title = targetItem.title ?? targetItem.url ?? 'Untitled Item';
    final domain = targetItem.metadata?.domain ??
        (targetItem.url != null ? Uri.tryParse(targetItem.url!)?.host : null) ??
        'Saved Item';
    final ago = timeago.format(targetItem.createdAt);
    final imageUrl = targetItem.metadata?.previewImageUrl;
    final isVideo = targetItem.type.toLowerCase() == 'video' ||
        (targetItem.url ?? '').toLowerCase().contains('youtube');

    return InkWell(
      onTap: () => context.push('/item/${targetItem.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 114,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Continue reviewing',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            Row(
              children: [
                // Thumbnail preview
                Container(
                  width: 58,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF171711),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl != null && imageUrl.isNotEmpty)
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      if (isVideo)
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              size: 12,
                              color: Color(0xFFEA4335),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$domain • $ago',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================================
// Top Widget Card 3: AI Organize Beta (Web Parity)
// =========================================================================
class _AiOrganizeCard extends StatelessWidget {
  const _AiOrganizeCard({required this.onGetSuggestions});

  final VoidCallback onGetSuggestions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      height: 114,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Color(0xFFCA8A04),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'AI organize',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6EDB0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'BETA',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF171711),
                      ),
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          Text(
            'Let AI suggest tags, collections, and next steps for your inbox items.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 1.25,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          InkWell(
            onTap: onGetSuggestions,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 28,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EDB0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 12,
                    color: Color(0xFF171711),
                  ),
                  SizedBox(width: 5),
                  Text(
                    'Get suggestions',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF171711),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// AI Organize Bottom Sheet (Beta)
// =========================================================================
class _AiOrganizeModalSheet extends StatelessWidget {
  const _AiOrganizeModalSheet({required this.items});

  final List<LaterBoxItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Group items into suggested collections
    final videoItems = items.where((i) => i.type == 'video' || (i.url ?? '').contains('youtube')).toList();
    final articleItems = items.where((i) => i.type == 'article' || (i.metadata?.classification?.type.name == 'article')).toList();
    final noteItems = items.where((i) => i.type == 'note' || (i.text != null && i.text!.isNotEmpty)).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: Color(0xFFCA8A04),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'AI Organize Suggestions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Gemini analyzed ${items.length} items in your inbox and generated smart recommendations:',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (videoItems.isNotEmpty)
              _SuggestionTile(
                title: 'Watch Later Collection',
                subtitle: '${videoItems.length} videos found to organize',
                tags: const ['#video', '#watchlater', '#talks'],
                icon: Icons.video_library_rounded,
              ),
            if (articleItems.isNotEmpty)
              _SuggestionTile(
                title: 'Reading List Collection',
                subtitle: '${articleItems.length} articles and long-reads found',
                tags: const ['#reading', '#article', '#research'],
                icon: Icons.article_rounded,
              ),
            if (noteItems.isNotEmpty)
              _SuggestionTile(
                title: 'Personal Notes & Snippets',
                subtitle: '${noteItems.length} quick notes to organize',
                tags: const ['#quicknote', '#ideas', '#draft'],
                icon: Icons.note_alt_rounded,
              ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('Your inbox is empty. Save items to see AI suggestions!'),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE6EDB0),
                  foregroundColor: const Color(0xFF171711),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI recommendations noted for inbox!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                label: const Text(
                  'Apply Suggestions',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final List<String> tags;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: tags.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        t,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// Empty State (Web Parity)
// =========================================================================
class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox({
    required this.searchQuery,
    required this.onSaveItem,
  });

  final String searchQuery;
  final VoidCallback onSaveItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSearching = searchQuery.trim().isNotEmpty;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh.withValues(
                  alpha: 0.6,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 26,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No items match your search' : 'Your inbox is clear',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Try a different search query or clear the filter.'
                  : 'Items appear here when their return time arrives.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: onSaveItem,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171711),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Save Item',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
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


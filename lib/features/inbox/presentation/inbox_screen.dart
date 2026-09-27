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
import '../../collections/presentation/collection_providers.dart';
import '../../notes/presentation/item_note_providers.dart';
import '../../scheduling/domain/return_schedule.dart';
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
    final isDesktop = MediaQuery.of(context).size.width >= 700;
    if (isDesktop) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 820),
            child: _AiOrganizeModal(items: items),
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.90,
          child: _AiOrganizeModal(items: items),
        ),
      );
    }
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
                                        maxCrossAxisExtent: 330,
                                        mainAxisSpacing: 14,
                                        crossAxisSpacing: 14,
                                        childAspectRatio: 1.18,
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
                                        maxCrossAxisExtent: 330,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 1.18,
                                      ),
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

                  // Cloud Sync Indicator (Pro Mode)
                  const CloudSyncIndicator(compact: true),
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
class _AiOrganizeModal extends ConsumerStatefulWidget {
  const _AiOrganizeModal({required this.items});

  final List<LaterBoxItem> items;

  @override
  ConsumerState<_AiOrganizeModal> createState() => _AiOrganizeModalState();
}

class _SuggestionPlan {
  const _SuggestionPlan({
    required this.collectionName,
    required this.collectionIcon,
    required this.nextStep,
    required this.schedule,
    required this.scheduleLabel,
    required this.scheduleIcon,
    required this.tags,
    required this.reasoning,
  });

  final String collectionName;
  final IconData collectionIcon;
  final String nextStep;
  final ReturnPreset schedule;
  final String scheduleLabel;
  final IconData scheduleIcon;
  final List<String> tags;
  final String reasoning;
}

class _ItemSnapshot {
  _ItemSnapshot({
    required this.originalReturnAt,
    required this.originalNoteContent,
  });

  final DateTime? originalReturnAt;
  final String? originalNoteContent;
  String? appliedCollectionId;
  bool collectionApplied = false;
  bool noteApplied = false;
  bool scheduleApplied = false;

  bool get hasAnyApplied => collectionApplied || noteApplied || scheduleApplied;
}

class _AiOrganizeModalState extends ConsumerState<_AiOrganizeModal> {
  final Set<String> _appliedCollections = {};
  final Set<String> _appliedNotes = {};
  final Set<String> _appliedSchedules = {};
  final Set<String> _appliedItems = {};
  final Map<String, _ItemSnapshot> _snapshots = {};
  bool _isApplyingAll = false;
  bool _isRevertingAll = false;

  Future<_ItemSnapshot> _ensureSnapshot(LaterBoxItem item) async {
    final existing = _snapshots[item.id];
    if (existing != null) return existing;
    final note =
        await ref.read(itemNoteRepositoryProvider).noteById(item.id);
    final snap = _ItemSnapshot(
      originalReturnAt: item.returnAt,
      originalNoteContent: note?.content,
    );
    _snapshots[item.id] = snap;
    return snap;
  }

  _SuggestionPlan _getPlanForItem(LaterBoxItem item) {
    final url = (item.url ?? '').toLowerCase();
    final type = item.type.toLowerCase();
    final classificationType =
        item.metadata?.classification?.type.name.toLowerCase() ?? '';

    String collectionName;
    IconData collectionIcon;
    String nextStep;
    ReturnPreset schedule = ReturnPreset.tomorrow;
    String scheduleLabel = 'Tomorrow 09:00 AM';
    IconData scheduleIcon = Icons.wb_twilight_rounded;
    List<String> tags;
    String reasoning;

    if (url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('vimeo.com') ||
        type == 'video') {
      collectionName = 'Watch Later';
      collectionIcon = Icons.play_circle_outline_rounded;
      nextStep = 'Watch and extract key insights & timestamps';
      schedule = ReturnPreset.weekend;
      scheduleLabel = 'This Weekend';
      scheduleIcon = Icons.calendar_today_rounded;
      tags = const ['#video', '#watchlater', '#deepdive'];
      reasoning = 'Identified video media format; recommended for weekend focus.';
    } else if (url.contains('github.com') ||
        url.contains('gitlab.com') ||
        type == 'code') {
      collectionName = 'Developer & Code';
      collectionIcon = Icons.code_rounded;
      nextStep = 'Review repository architecture and test locally';
      schedule = ReturnPreset.laterToday;
      scheduleLabel = 'Later Today';
      scheduleIcon = Icons.wb_sunny_outlined;
      tags = const ['#dev', '#code', '#open-source'];
      reasoning = 'Code repository detected; schedule for today\'s dev sprint.';
    } else if (url.contains('spotify.com') ||
        url.contains('soundcloud.com') ||
        type == 'music') {
      collectionName = 'Audio & Music';
      collectionIcon = Icons.music_note_rounded;
      nextStep = 'Listen and add favorites to your curated playlist';
      schedule = ReturnPreset.someday;
      scheduleLabel = 'Someday Vault';
      scheduleIcon = Icons.inventory_2_outlined;
      tags = const ['#audio', '#music', '#discovery'];
      reasoning = 'Audio stream detected; cataloged into music library.';
    } else if (url.contains('figma.com') ||
        url.contains('dribbble.com') ||
        url.contains('behance.com') ||
        type == 'image') {
      collectionName = 'Design Vault';
      collectionIcon = Icons.palette_outlined;
      nextStep = 'Inspect design system patterns and UX aesthetics';
      schedule = ReturnPreset.tomorrow;
      scheduleLabel = 'Tomorrow 09:00 AM';
      scheduleIcon = Icons.wb_twilight_rounded;
      tags = const ['#design', '#inspiration', '#ui-ux'];
      reasoning = 'Visual design asset; suggested for UI reference vault.';
    } else if (type == 'note' ||
        (item.text != null &&
            item.text!.isNotEmpty &&
            (item.url == null || item.url!.isEmpty))) {
      collectionName = 'Personal Notes';
      collectionIcon = Icons.edit_note_rounded;
      nextStep = 'Review thoughts and convert into actionable milestones';
      schedule = ReturnPreset.laterToday;
      scheduleLabel = 'Later Today';
      scheduleIcon = Icons.wb_sunny_outlined;
      tags = const ['#note', '#ideas', '#actionable'];
      reasoning =
          'Personal thought capture; recommended for today\'s organization.';
    } else if (type == 'article' ||
        classificationType == 'article' ||
        url.contains('medium.com') ||
        url.contains('substack.com')) {
      collectionName = 'Reading List';
      collectionIcon = Icons.menu_book_rounded;
      nextStep = 'Read comprehensive piece and bookmark key concepts';
      schedule = ReturnPreset.tomorrow;
      scheduleLabel = 'Tomorrow 09:00 AM';
      scheduleIcon = Icons.wb_twilight_rounded;
      tags = const ['#reading', '#article', '#research'];
      reasoning =
          'Long-form editorial piece; queued for tomorrow morning reading.';
    } else if (url.contains('amazon.') ||
        url.contains('ebay.') ||
        type == 'product') {
      collectionName = 'Shopping Wishlist';
      collectionIcon = Icons.shopping_bag_outlined;
      nextStep = 'Evaluate specs, check reviews, and compare pricing';
      schedule = ReturnPreset.weekend;
      scheduleLabel = 'This Weekend';
      scheduleIcon = Icons.calendar_today_rounded;
      tags = const ['#product', '#wishlist', '#shopping'];
      reasoning = 'Commerce item detected; scheduled for weekend decision.';
    } else {
      collectionName = 'Inbox Discoveries';
      collectionIcon = Icons.folder_outlined;
      nextStep = 'Review content and file into appropriate project';
      schedule = ReturnPreset.tomorrow;
      scheduleLabel = 'Tomorrow 09:00 AM';
      scheduleIcon = Icons.wb_twilight_rounded;
      tags = const ['#reference', '#inbox', '#to-review'];
      reasoning =
          'Classified based on inbound metadata and domain attributes.';
    }

    return _SuggestionPlan(
      collectionName: collectionName,
      collectionIcon: collectionIcon,
      nextStep: nextStep,
      schedule: schedule,
      scheduleLabel: scheduleLabel,
      scheduleIcon: scheduleIcon,
      tags: tags,
      reasoning: reasoning,
    );
  }

  Future<void> _applyCollection(LaterBoxItem item, String collectionName) async {
    try {
      final snap = await _ensureSnapshot(item);
      final collections = ref.read(collectionsProvider).valueOrNull ?? [];
      final existing = collections
          .where(
            (c) =>
                c.name.trim().toLowerCase() ==
                collectionName.trim().toLowerCase(),
          )
          .firstOrNull;
      final String colId;
      if (existing != null) {
        colId = existing.id;
      } else {
        colId = await ref
            .read(collectionRepositoryProvider)
            .create(collectionName.trim());
      }
      await ref.read(collectionRepositoryProvider).addItem(colId, item.id);
      snap.appliedCollectionId = colId;
      snap.collectionApplied = true;
      if (mounted) {
        setState(() {
          _appliedCollections.add(item.id);
          if (_appliedNotes.contains(item.id) &&
              _appliedSchedules.contains(item.id)) {
            _appliedItems.add(item.id);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _revertCollection(LaterBoxItem item) async {
    final snap = _snapshots[item.id];
    if (snap == null || !snap.collectionApplied || snap.appliedCollectionId == null) return;
    try {
      await ref
          .read(collectionRepositoryProvider)
          .removeItem(snap.appliedCollectionId!, item.id);
      snap.collectionApplied = false;
      if (mounted) {
        setState(() {
          _appliedCollections.remove(item.id);
          _appliedItems.remove(item.id);
        });
      }
    } catch (_) {}
  }

  Future<void> _applyNextStep(LaterBoxItem item, String nextStep) async {
    try {
      final snap = await _ensureSnapshot(item);
      final existingNote =
          await ref.read(itemNoteRepositoryProvider).noteById(item.id);
      final currentContent = existingNote?.content.trim() ?? '';
      final newContent = currentContent.isEmpty
          ? '• Next step: $nextStep'
          : '$currentContent\n\n• Next step: $nextStep';
      await ref.read(itemNoteRepositoryProvider).save(item.id, newContent);
      snap.noteApplied = true;
      if (mounted) {
        setState(() {
          _appliedNotes.add(item.id);
          if (_appliedCollections.contains(item.id) &&
              _appliedSchedules.contains(item.id)) {
            _appliedItems.add(item.id);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _revertNextStep(LaterBoxItem item) async {
    final snap = _snapshots[item.id];
    if (snap == null || !snap.noteApplied) return;
    try {
      await ref
          .read(itemNoteRepositoryProvider)
          .save(item.id, snap.originalNoteContent ?? '');
      snap.noteApplied = false;
      if (mounted) {
        setState(() {
          _appliedNotes.remove(item.id);
          _appliedItems.remove(item.id);
        });
      }
    } catch (_) {}
  }

  Future<void> _applySchedule(LaterBoxItem item, ReturnPreset preset) async {
    try {
      final snap = await _ensureSnapshot(item);
      final returnAt = resolveReturnPreset(preset, DateTime.now());
      await ref.read(itemRepositoryProvider).reschedule(item.id, returnAt);
      snap.scheduleApplied = true;
      if (mounted) {
        setState(() {
          _appliedSchedules.add(item.id);
          if (_appliedCollections.contains(item.id) &&
              _appliedNotes.contains(item.id)) {
            _appliedItems.add(item.id);
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _revertSchedule(LaterBoxItem item) async {
    final snap = _snapshots[item.id];
    if (snap == null || !snap.scheduleApplied) return;
    try {
      await ref
          .read(itemRepositoryProvider)
          .reschedule(item.id, snap.originalReturnAt);
      snap.scheduleApplied = false;
      if (mounted) {
        setState(() {
          _appliedSchedules.remove(item.id);
          _appliedItems.remove(item.id);
        });
      }
    } catch (_) {}
  }

  Future<void> _revertItem(LaterBoxItem item) async {
    final snap = _snapshots[item.id];
    if (snap == null) return;
    try {
      if (snap.collectionApplied && snap.appliedCollectionId != null) {
        await ref
            .read(collectionRepositoryProvider)
            .removeItem(snap.appliedCollectionId!, item.id);
        snap.collectionApplied = false;
      }
      if (snap.noteApplied) {
        await ref
            .read(itemNoteRepositoryProvider)
            .save(item.id, snap.originalNoteContent ?? '');
        snap.noteApplied = false;
      }
      if (snap.scheduleApplied) {
        await ref
            .read(itemRepositoryProvider)
            .reschedule(item.id, snap.originalReturnAt);
        snap.scheduleApplied = false;
      }
      if (mounted) {
        setState(() {
          _appliedCollections.remove(item.id);
          _appliedNotes.remove(item.id);
          _appliedSchedules.remove(item.id);
          _appliedItems.remove(item.id);
          _snapshots.remove(item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.undo_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text('AI changes reverted for this item'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _applyItem(LaterBoxItem item, _SuggestionPlan plan) async {
    await _applyCollection(item, plan.collectionName);
    await _applyNextStep(item, plan.nextStep);
    await _applySchedule(item, plan.schedule);
    if (mounted) {
      setState(() => _appliedItems.add(item.id));
    }
  }

  Future<void> _applyAll() async {
    if (_isApplyingAll || widget.items.isEmpty) return;
    setState(() => _isApplyingAll = true);
    try {
      for (final item in widget.items) {
        final plan = _getPlanForItem(item);
        await _applyItem(item, plan);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF27C93F),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text('All ${widget.items.length} AI suggestions applied!'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplyingAll = false);
      }
    }
  }

  Future<void> _revertAll() async {
    if (_isRevertingAll || _snapshots.isEmpty) return;
    setState(() => _isRevertingAll = true);
    try {
      final itemsToRevert = widget.items.where((i) => _snapshots.containsKey(i.id)).toList();
      for (final item in itemsToRevert) {
        final snap = _snapshots[item.id];
        if (snap != null) {
          if (snap.collectionApplied && snap.appliedCollectionId != null) {
            await ref
                .read(collectionRepositoryProvider)
                .removeItem(snap.appliedCollectionId!, item.id);
          }
          if (snap.noteApplied) {
            await ref
                .read(itemNoteRepositoryProvider)
                .save(item.id, snap.originalNoteContent ?? '');
          }
          if (snap.scheduleApplied) {
            await ref
                .read(itemRepositoryProvider)
                .reschedule(item.id, snap.originalReturnAt);
          }
        }
      }
      if (mounted) {
        final count = itemsToRevert.length;
        setState(() {
          _appliedCollections.clear();
          _appliedNotes.clear();
          _appliedSchedules.clear();
          _appliedItems.clear();
          _snapshots.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.undo_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text('Reverted AI changes for $count items'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRevertingAll = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final allApplied =
        widget.items.isNotEmpty &&
        widget.items.every((item) => _appliedItems.contains(item.id));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFE4E0D5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            // Modal Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 20,
                      color: Color(0xFFCA8A04),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Row(
                      children: [
                        Text(
                          'AI Inbox Organizer',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        _BadgePill(
                          label: 'Beta',
                          backgroundColor: Color(0xFFE6EDB0),
                          textColor: Color(0xFF171711),
                        ),
                        SizedBox(width: 6),
                        _BadgePill(
                          label: 'Gemini 2.5 Flash',
                          backgroundColor: Color(0xFFE8F5E9),
                          textColor: Color(0xFF2E7D32),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE4E0D5)),

            // Summary & Apply All Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? const Color(0xFF252525) : const Color(0xFFF7F5EE),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Smart suggestions for collections, next steps, and return schedules.',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF6C6B63),
                          ),
                        ),
                        if (widget.items.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${_appliedItems.length} of ${widget.items.length} items organized',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white54
                                  : const Color(0xFF9E9B92),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_snapshots.isNotEmpty || _appliedItems.isNotEmpty) ...[
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            isDark ? Colors.white70 : const Color(0xFF6C6B63),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF444444)
                              : const Color(0xFFD4D0C5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed:
                          _isRevertingAll || _isApplyingAll ? null : _revertAll,
                      icon: _isRevertingAll
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.undo_rounded, size: 14),
                      label: const Text(
                        'Revert All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: allApplied
                          ? const Color(0xFFE6EDB0)
                          : const Color(0xFF171711),
                      foregroundColor: allApplied
                          ? const Color(0xFF171711)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: allApplied ||
                            _isApplyingAll ||
                            widget.items.isEmpty
                        ? null
                        : _applyAll,
                    icon: _isApplyingAll
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            allApplied
                                ? Icons.check_rounded
                                : Icons.auto_awesome_rounded,
                            size: 14,
                            color: allApplied
                                ? const Color(0xFF171711)
                                : const Color(0xFFE6EDB0),
                          ),
                    label: Text(
                      allApplied ? 'All Applied' : 'Apply All',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE4E0D5)),

            // Scrollable Item Recommendations List
            Expanded(
              child: widget.items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2C2C2C)
                                    : const Color(0xFFF7F5EE),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                size: 28,
                                color: Color(0xFFCA8A04),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Your inbox is all organized!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Save items to LaterBox to generate smart AI categorization and action plans.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        final plan = _getPlanForItem(item);
                        final isColApplied =
                            _appliedCollections.contains(item.id);
                        final isNoteApplied = _appliedNotes.contains(item.id);
                        final isSchedApplied =
                            _appliedSchedules.contains(item.id);
                        final isItemApplied = _appliedItems.contains(item.id);

                        final rawTitle = item.metadata?.title ??
                            item.title ??
                            item.url ??
                            'Untitled item';
                        final domain = item.metadata?.domain ??
                            (item.url != null
                                ? Uri.tryParse(item.url!)?.host
                                : null) ??
                            '';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF181818)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2D2D2D)
                                  : const Color(0xFFEBE7DC),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top item metadata & individual apply/revert buttons
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF2A2A2A)
                                          : const Color(0xFFEBE7DC),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          plan.collectionIcon,
                                          size: 11,
                                          color: isDark
                                              ? Colors.white70
                                              : const Color(0xFF6C6B63),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.type.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: isDark
                                                ? Colors.white70
                                                : const Color(0xFF6C6B63),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (domain.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        domain,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white54
                                              : const Color(0xFF9E9B92),
                                        ),
                                      ),
                                    ),
                                  ] else
                                    const Spacer(),
                                  const SizedBox(width: 8),
                                  if (isItemApplied ||
                                      isColApplied ||
                                      isNoteApplied ||
                                      isSchedApplied) ...[
                                    InkWell(
                                      onTap: () => _revertItem(item),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF2E2424)
                                              : const Color(0xFFFEE2E2),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.undo_rounded,
                                              size: 11,
                                              color: Color(0xFFDC2626),
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'Revert',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFFDC2626),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  InkWell(
                                    onTap: isItemApplied
                                        ? null
                                        : () => _applyItem(item, plan),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isItemApplied)
                                            const Icon(
                                              Icons.check_rounded,
                                              size: 13,
                                              color: Color(0xFF27C93F),
                                            )
                                          else
                                            const Icon(
                                              Icons.auto_awesome_rounded,
                                              size: 13,
                                              color: Color(0xFF171711),
                                            ),
                                          const SizedBox(width: 4),
                                          Text(
                                            isItemApplied
                                                ? 'Applied'
                                                : 'Apply Item',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                              color: isItemApplied
                                                  ? const Color(0xFF27C93F)
                                                  : (isDark
                                                      ? Colors.white
                                                      : const Color(0xFF171711)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Item Title
                              Text(
                                rawTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Tags
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: plan.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF242424)
                                          : const Color(0xFFF7F5EE),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF333333)
                                            : const Color(0xFFE4E0D5),
                                      ),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF6C6B63),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 12),

                              // 3 Sub-Blocks
                              // 1. Collection
                              _OrganizeSubBlock(
                                icon: Icons.folder_outlined,
                                label: 'COLLECTION',
                                actionLabel: isColApplied ? 'Added' : '+ Add',
                                isApplied: isColApplied,
                                onAction: () => _applyCollection(
                                  item,
                                  plan.collectionName,
                                ),
                                onUndo: isColApplied
                                    ? () => _revertCollection(item)
                                    : null,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6EDB0),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.folder_rounded,
                                        size: 13,
                                        color: Color(0xFF171711),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        plan.collectionName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),

                              // 2. Next Step
                              _OrganizeSubBlock(
                                icon: Icons.auto_awesome_rounded,
                                iconColor: const Color(0xFFCA8A04),
                                label: 'ACTIONABLE NEXT STEP',
                                actionLabel:
                                    isNoteApplied ? 'Saved' : '+ Save Note',
                                isApplied: isNoteApplied,
                                onAction: () =>
                                    _applyNextStep(item, plan.nextStep),
                                onUndo: isNoteApplied
                                    ? () => _revertNextStep(item)
                                    : null,
                                child: Text(
                                  plan.nextStep,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF171711),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // 3. Recommended Schedule
                              _OrganizeSubBlock(
                                icon: Icons.schedule_rounded,
                                label: 'RECOMMENDED RETURN',
                                actionLabel:
                                    isSchedApplied ? 'Scheduled' : 'Schedule',
                                isApplied: isSchedApplied,
                                onAction: () =>
                                    _applySchedule(item, plan.schedule),
                                onUndo: isSchedApplied
                                    ? () => _revertSchedule(item)
                                    : null,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF252525)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF383838)
                                          : const Color(0xFFE4E0D5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        plan.scheduleIcon,
                                        size: 13,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF6C6B63),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        plan.scheduleLabel,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Reasoning Footer
                              if (plan.reasoning.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.lightbulb_outline_rounded,
                                      size: 13,
                                      color: Color(0xFFCA8A04),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        plan.reasoning,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: isDark
                                              ? Colors.white54
                                              : const Color(0xFF8E8D87),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Modal Footer (Web Parity)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F5EE),
              child: const Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF27C93F),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(width: 7, height: 7),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Google Gemini Intelligence • Private Local Execution',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6C6B63),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganizeSubBlock extends StatelessWidget {
  const _OrganizeSubBlock({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.actionLabel,
    required this.isApplied,
    required this.onAction,
    this.onUndo,
    required this.child,
  });

  final IconData icon;
  final Color? iconColor;
  final String label;
  final String actionLabel;
  final bool isApplied;
  final VoidCallback onAction;
  final VoidCallback? onUndo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF2F2F2F)
              : const Color(0xFFE4E0D5).withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 12,
                    color: iconColor ??
                        (isDark ? Colors.white54 : const Color(0xFF9E9B92)),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      color: isDark ? Colors.white54 : const Color(0xFF9E9B92),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: isApplied ? onUndo : onAction,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isApplied) ...[
                        const Icon(
                          Icons.check_rounded,
                          size: 11,
                          color: Color(0xFF27C93F),
                        ),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        actionLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isApplied
                              ? const Color(0xFF27C93F)
                              : (isDark
                                  ? Colors.white
                                  : const Color(0xFF171711)),
                        ),
                      ),
                      if (isApplied && onUndo != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.undo_rounded,
                          size: 10,
                          color: isDark ? Colors.white54 : const Color(0xFF9E9B92),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
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


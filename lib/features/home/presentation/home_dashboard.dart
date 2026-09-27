import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/models/laterbox_item.dart';
import '../../../shared/widgets/item_card.dart';
import '../../../shared/widgets/item_list_row.dart';
import '../../attachments/data/attachment_file_picker.dart';
import '../../enrichment/domain/url_utils.dart';
import '../../capture/presentation/capture_sheet.dart';
import '../../inbox/presentation/inbox_providers.dart';
import '../../library/presentation/library_providers.dart';
import '../../scheduling/presentation/schedule_providers.dart';
import '../../scheduling/presentation/return_time_picker.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/settings/display_name_provider.dart';
import '../../../core/sync/sync_providers.dart';

Future<void> openDashboardCapture(
  BuildContext context, {
  bool browseFiles = false,
  List<PickedAttachmentFile> files = const [],
}) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) =>
          CaptureSheet(browseFiles: browseFiles, initialFiles: files),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CaptureSheet(browseFiles: browseFiles, initialFiles: files),
  );
}

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({super.key});

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final platform = Theme.of(context).platform;
    final isDesktopPlatform = switch (platform) {
      TargetPlatform.macOS ||
      TargetPlatform.linux ||
      TargetPlatform.windows => true,
      _ => false,
    };
    final isDesktop = isDesktopPlatform || width >= 900;
    final isMac = !kIsWeb && platform == TargetPlatform.macOS;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final all = ref.watch(allItemsProvider);
    final now =
        ref.watch(scheduleClockProvider).valueOrNull ??
        ref.watch(scheduleNowProvider)();
    final hour = now.toLocal().hour;
    final email = ref.watch(currentAuthStateProvider).email;
    final displayName = ref.watch(displayNameProvider);
    final firstName = displayName?.isNotEmpty == true
        ? displayName!
        : email?.split('@').first ?? '';
    final hasName = firstName.trim().isNotEmpty;
    final timeGreeting = hour < 12
        ? (hasName ? 'Good morning,' : 'Good morning.')
        : hour < 18
        ? (hasName ? 'Good afternoon,' : 'Good afternoon.')
        : (hasName ? 'Good evening,' : 'Good evening.');
    return Scaffold(
      appBar: isDesktop
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(148),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 8,
                  16,
                  20,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      isDark
                          ? const Color(0xFF171711)
                          : const Color(0xFFF7F5EE),
                      isDark
                          ? const Color(0xFF171711)
                          : const Color(0xFFF7F5EE),
                      isDark
                          ? const Color(0xFF171711).withValues(alpha: 0.0)
                          : const Color(0xFFF7F5EE).withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => showDisplayNamePrompt(context, ref),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeGreeting,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF171711),
                              ),
                            ),
                            if (hasName)
                              Text(
                                firstName,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF171711),
                                  letterSpacing: -1,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout_rounded),
                      onPressed: () async {
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) context.go('/welcome');
                      },
                    ),
                  ],
                ),
              ),
            ),
      body: all.when(
        loading: () =>
            const Center(child: CircularProgressIndicator.adaptive()),
        error: (error, _) =>
            const Center(child: Text('Could not load your items.')),
        data: (items) {
          final due = items.where((item) => item.isDue(now)).toList()
            ..sort(
              (a, b) => (a.returnAt ?? a.createdAt).compareTo(
                b.returnAt ?? b.createdAt,
              ),
            );
          final upcoming = scheduleItems(items, ScheduleView.upcoming, now);
          final today = scheduleItems(items, ScheduleView.today, now);
          final someday = scheduleItems(items, ScheduleView.someday, now);
          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1000;
              final main = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ItemSection(
                    title: 'Ready for you',
                    items: due.take(5).toList(),
                    empty: 'You’re all clear. Items will return here when it’s time.',
                    route: '/inbox',
                    action: 'View Inbox (${due.length})',
                  ),
                  const SizedBox(height: 24),
                  _ItemSection(
                    title: 'Coming up',
                    items: upcoming.take(3).toList(),
                    empty: 'Choose a return time to see what’s coming up.',
                    route: '/upcoming',
                    action: 'View upcoming (${upcoming.length})',
                  ),
                ],
              );
              final side = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _QuickDrop(),
                  const SizedBox(height: 24),
                  _Panel(
                    title: 'Next return',
                    child: upcoming.isEmpty
                        ? const Text('No scheduled returns yet.')
                        : _ScheduledRow(item: upcoming.first),
                  ),
                  const SizedBox(height: 24),
                  _Panel(
                    title: 'Someday',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${someday.length} items safely out of your head.',
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => context.go('/someday'),
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Open Someday'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
              return RefreshIndicator.adaptive(
                onRefresh: () => ref.read(syncCoordinatorProvider).syncNow(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    24,
                    isDesktop ? (isMac ? 40 : 28) : 0,
                    24,
                    24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isDesktop)
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      showDisplayNamePrompt(context, ref),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        timeGreeting,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF171711),
                                            ),
                                      ),
                                      if (hasName)
                                        Text(
                                          firstName,
                                          style: theme.textTheme.headlineLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF171711),
                                                letterSpacing: -1,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Sign out',
                                  icon: const Icon(Icons.logout_rounded),
                                  onPressed: () async {
                                    await ref
                                        .read(authRepositoryProvider)
                                        .signOut();
                                    if (context.mounted) {
                                      context.go('/welcome');
                                    }
                                  },
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          if (!isDesktop)
                            GestureDetector(
                              onTap: () =>
                                  context.push('/search', extra: '/home'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF2A2A28)
                                      : const Color(0xFFF0EDE5),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      color: isDark
                                          ? const Color(0xFFA09E95)
                                          : const Color(0xFF6C6B63),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Search your items…',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFFA09E95)
                                              : const Color(0xFF6C6B63),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (!isDesktop) const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _Summary(
                                  label: 'Waiting in Inbox',
                                  count: due.length,
                                  route: '/inbox',
                                  icon: Icons.inbox_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _Summary(
                                  label: 'Returning today',
                                  count: today.length,
                                  route: '/today',
                                  icon: Icons.today_outlined,
                                  timeLabel:
                                      today.isNotEmpty &&
                                          today.first.returnAt != null
                                      ? 'Next: ${returnTimeLabel(context, today.first.returnAt)}'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _Summary(
                            label: 'Upcoming',
                            count: upcoming.length,
                            route: '/upcoming',
                            icon: Icons.event_outlined,
                            timeLabel:
                                upcoming.isNotEmpty &&
                                    upcoming.first.returnAt != null
                                ? 'Next: ${returnTimeLabel(context, upcoming.first.returnAt)}'
                                : null,
                          ),
                          const SizedBox(height: 28),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: main),
                                const SizedBox(width: 24),
                                Expanded(child: side),
                              ],
                            )
                          else ...[
                            main,
                            const SizedBox(height: 24),
                            side,
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key, required this.view});
  final ScheduleView view;

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  final _searchController = TextEditingController();
  InboxFilterType _filter = InboxFilterType.all;
  bool _grid = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.view) {
      ScheduleView.today => 'Today',
      ScheduleView.upcoming => 'Upcoming',
      ScheduleView.someday => 'Someday',
    };
    final config = switch (widget.view) {
      ScheduleView.today => (
        '⚡ Returned Today',
        'When later becomes now.',
        'LaterBox brings your saved items back right on schedule.',
        'Drop item',
        'No items due today',
        'Nothing scheduled for today yet. Relax, or pick something from your Inbox or Someday Vault.',
      ),
      ScheduleView.upcoming => (
        '📅 Scheduled Timeline',
        'Returning on schedule.',
        'Everything you’ve postponed, arranged by when it returns.',
        'Schedule item',
        'No upcoming returns scheduled',
        'Postponed items with future return times will appear here chronologically.',
      ),
      ScheduleView.someday => (
        '✦ Someday Vault',
        'Some things don’t need a deadline.',
        'Keep ideas and references safe without cluttering your daily view.',
        'Save to Someday',
        'Someday Vault is clear',
        'Items saved without a specific return date will wait here safely until you feel like exploring them.',
      ),
    };
    final scheduled = ref.watch(scheduledItemsProvider(widget.view));
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;
    return scheduled.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (_, _) =>
          const Scaffold(body: Center(child: Text('Could not load items.'))),
      data: (items) {
        final query = _searchController.text.trim().toLowerCase();
        final visible = items.where((item) {
          if (_filter != InboxFilterType.all && !_filter.matches(item)) {
            return false;
          }
          if (query.isEmpty) return true;
          return [
            item.title,
            item.text,
            item.url,
            item.metadata?.title,
            item.metadata?.description,
            item.metadata?.domain,
          ].whereType<String>().any(
            (text) => text.toLowerCase().contains(query),
          );
        }).toList();
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 40 : 20,
                vertical: isDesktop ? 32 : 20,
              ),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Back to Dashboard',
                            onPressed: () => context.go('/home'),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                ),
                                hintText: 'Filter ${title.toLowerCase()}...',
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                          if (isDesktop) ...[
                            const SizedBox(width: 12),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: true,
                                  icon: Icon(Icons.grid_view_rounded),
                                  tooltip: 'Grid view',
                                ),
                                ButtonSegment(
                                  value: false,
                                  icon: Icon(Icons.view_list_rounded),
                                  tooltip: 'List view',
                                ),
                              ],
                              selected: {_grid},
                              onSelectionChanged: (value) =>
                                  setState(() => _grid = value.first),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 34),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          config.$1,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  config.$2,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  config.$3,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        height: 1.45,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: () => openDashboardCapture(context),
                            icon: const Icon(Icons.add_rounded),
                            label: Text(config.$4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final filter in const [
                              InboxFilterType.all,
                              InboxFilterType.articles,
                              InboxFilterType.videos,
                              InboxFilterType.music,
                              InboxFilterType.notes,
                              InboxFilterType.files,
                            ])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(
                                    filter == InboxFilterType.all
                                        ? 'All (${items.length})'
                                        : filter.label,
                                  ),
                                  avatar: Icon(filter.icon, size: 16),
                                  selected: _filter == filter,
                                  onSelected: (_) =>
                                      setState(() => _filter = filter),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (visible.isEmpty)
                        _ScheduleEmptyState(
                          title:
                              query.isNotEmpty || _filter != InboxFilterType.all
                              ? 'No matching items'
                              : config.$5,
                          detail:
                              query.isNotEmpty || _filter != InboxFilterType.all
                              ? 'Try clearing your search or selecting another format.'
                              : config.$6,
                          onAdd: () => openDashboardCapture(context),
                        )
                      else if (_grid && isDesktop)
                        LayoutBuilder(
                          builder: (context, constraints) => GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: constraints.maxWidth >= 960
                                      ? 3
                                      : 2,
                                  mainAxisExtent: 270,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            itemCount: visible.length,
                            itemBuilder: (_, index) =>
                                ItemCard(item: visible[index], isGrid: true),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, index) =>
                              _ScheduledRow(item: visible[index]),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScheduleEmptyState extends StatelessWidget {
  const _ScheduleEmptyState({
    required this.title,
    required this.detail,
    required this.onAdd,
  });
  final String title, detail;
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(48),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      children: [
        Icon(
          Icons.schedule_rounded,
          size: 34,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          detail,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Item to LaterBox'),
        ),
      ],
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.label,
    required this.count,
    required this.route,
    required this.icon,
    this.timeLabel,
  });
  final String label;
  final int count;
  final String route;
  final IconData icon;
  final String? timeLabel;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.go(route),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 6),
                  Text(
                    '$count items',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (timeLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      timeLabel!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      Card(
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      ),
    ],
  );
}

class _ItemSection extends StatelessWidget {
  const _ItemSection({
    required this.title,
    required this.items,
    required this.empty,
    required this.route,
    required this.action,
  });
  final String title, empty, route, action;
  final List<LaterBoxItem> items;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(onPressed: () => context.go(route), child: Text(action)),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              empty,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ItemCardRow(item: item),
          ),
      ],
    );
  }
}

class _ItemCardRow extends StatelessWidget {
  const _ItemCardRow({required this.item});
  final LaterBoxItem item;

  IconData get _typeIcon => switch (item.type) {
    'file' => Icons.description_outlined,
    'task' => Icons.check_circle_outline,
    'note' => Icons.notes_outlined,
    _ => Icons.link,
  };

  Color _iconBg(BuildContext context) => switch (item.type) {
    'file' => const Color(0xFF001E36),
    'task' => Theme.of(context).colorScheme.surfaceContainerHighest,
    'note' => const Color(0xFFE8F5E9),
    _ => Theme.of(context).colorScheme.primaryContainer,
  };

  Color _iconFg(BuildContext context) => switch (item.type) {
    'file' => const Color(0xFF31A8FF),
    'task' => Theme.of(context).colorScheme.onSurface,
    'note' => const Color(0xFF2E7D32),
    _ => Theme.of(context).colorScheme.onPrimaryContainer,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rawTitle =
        item.metadata?.title ??
        item.title ??
        item.url ??
        item.text ??
        'Untitled';
    final title = cleanMetaText(rawTitle) ?? rawTitle;
    final subtitle =
        item.metadata?.domain ??
        Uri.tryParse(item.url ?? '')?.host.replaceFirst('www.', '') ??
        (item.type == 'file'
            ? 'File'
            : item.type == 'task'
            ? 'Task'
            : 'Note');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/item/${item.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF2A2A28)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFF0EDE4),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _iconBg(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(_typeIcon, size: 18, color: _iconFg(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.returnAt != null) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    returnTimeLabel(context, item.returnAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduledRow extends ConsumerWidget {
  const _ScheduledRow({required this.item});
  final LaterBoxItem item;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ItemListRow(item: item),
      Row(
        children: [
          Expanded(
            child: Text(
              returnTimeLabel(context, item.returnAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (item.type == 'task' && item.isActive)
            TextButton.icon(
              onPressed: () =>
                  ref.read(itemRepositoryProvider).archive(item.id),
              icon: const Icon(Icons.task_alt, size: 18),
              label: const Text('Done'),
            ),
        ],
      ),
    ],
  );
}

class _QuickDrop extends StatefulWidget {
  const _QuickDrop();
  @override
  State<_QuickDrop> createState() => _QuickDropState();
}

class _QuickDropState extends State<_QuickDrop> {
  bool dragging = false;
  @override
  Widget build(BuildContext context) {
    final enabled =
        kIsWeb ||
        switch (defaultTargetPlatform) {
          TargetPlatform.macOS ||
          TargetPlatform.windows ||
          TargetPlatform.linux => true,
          _ => false,
        };
    return DropTarget(
      enable: enabled,
      onDragEntered: (_) => setState(() => dragging = true),
      onDragExited: (_) => setState(() => dragging = false),
      onDragDone: (details) async {
        setState(() => dragging = false);
        try {
          final files = <PickedAttachmentFile>[];
          for (final file in details.files) {
            files.add(
              PickedAttachmentFile(
                name: file.name,
                size: await file.length(),
                path: kIsWeb ? null : file.path,
                bytes: kIsWeb ? await file.readAsBytes() : null,
              ),
            );
          }
          if (!context.mounted) return;
          await openDashboardCapture(context, files: files);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not read dropped files. Try Browse Files.',
                ),
              ),
            );
          }
        }
      },
      child: _Panel(
        title: 'Quick Drop',
        child: Column(
          children: [
            Icon(
              dragging ? Icons.file_download : Icons.upload_file,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              enabled
                  ? 'Drop files here, or save a link or thought.'
                  : 'Save a file, link, task, or idea.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => openDashboardCapture(context),
              icon: const Icon(Icons.add),
              label: const Text('Drop something'),
            ),
            TextButton(
              onPressed: () => openDashboardCapture(context, browseFiles: true),
              child: const Text('Browse Files'),
            ),
          ],
        ),
      ),
    );
  }
}

void showDisplayNamePrompt(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What should we call you?',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Optional — tap anywhere to dismiss.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Display name'),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  ref.read(displayNameProvider.notifier).set(value.trim());
                }
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
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
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}

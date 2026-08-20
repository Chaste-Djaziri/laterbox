import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/filter_chip_bar.dart';
import '../../../shared/widgets/item_card.dart';
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = !kIsWeb
        ? (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows)
        : width >= 900;

    final rawItems = ref.watch(inboxItemsProvider);
    final filteredItems = ref.watch(filteredInboxItemsProvider);
    final auth = ref.watch(authStateProvider).asData?.value;
    final theme = Theme.of(context);
    final isMac = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

    return Scaffold(
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text(
                'LaterBox',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              actions: [
                if (auth?.isAuthenticated ?? false)
                  IconButton(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      ref.read(guestModeProvider.notifier).state = true;
                    },
                    tooltip: 'Sign out',
                    icon: const Icon(Icons.logout_rounded),
                  )
                else
                  IconButton(
                    onPressed: () =>
                        ref.read(guestModeProvider.notifier).state = false,
                    tooltip: 'Sign in',
                    icon: const Icon(Icons.person_outline_rounded),
                  ),
                const SizedBox(width: 8),
              ],
            ),
      body: SafeArea(
        top: !isDesktop,
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: isDesktop,
          child: CustomScrollView(
            controller: _scrollController,
            cacheExtent: 800,
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
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.1,
                                ),
                              ),
                              if (rawItems.asData?.value case final list?) ...[
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
                            if (auth?.isAuthenticated ?? false)
                              TextButton.icon(
                                onPressed: () async {
                                  await ref.read(authRepositoryProvider).signOut();
                                  ref.read(guestModeProvider.notifier).state = true;
                                },
                                icon: const Icon(Icons.logout_rounded, size: 18),
                                label: const Text('Sign out'),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => ref
                                    .read(guestModeProvider.notifier)
                                    .state = false,
                                icon: const Icon(Icons.person_outline_rounded, size: 18),
                                label: const Text('Sign in'),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/item_card.dart';
import 'inbox_providers.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(inboxItemsProvider);
    final auth = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LaterBox',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.6),
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
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inbox',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: items.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  error: (error, stackTrace) => _ErrorState(
                    onRetry: () => ref.invalidate(inboxItemsProvider),
                  ),
                  data: (items) => items.isEmpty
                      ? const _EmptyInbox()
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 104),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) =>
                              ItemCard(item: items[index]),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/laterbox_item.dart';
import '../../../shared/widgets/item_card.dart';

/// A filtered item list behind a Library row or collection tile. The caller
/// supplies the live [provider] so this stays a dumb, reusable screen.
class LibrarySectionScreen extends ConsumerWidget {
  const LibrarySectionScreen({
    super.key,
    required this.title,
    required this.provider,
  });

  final String title;
  final StreamProvider<List<LaterBoxItem>> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.6),
        ),
      ),
      body: SafeArea(
        top: false,
        child: items.when(
          loading: () => const Center(
            child: CircularProgressIndicator.adaptive(),
          ),
          error: (error, stackTrace) => Center(
            child: Text('Could not load items: $error'),
          ),
          data: (items) => items.isEmpty
              ? Center(
                  child: Text(
                    'Nothing here yet.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      ItemCard(item: items[index]),
                ),
        ),
      ),
    );
  }
}
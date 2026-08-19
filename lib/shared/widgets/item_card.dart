import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../features/detail/presentation/item_detail_screen.dart';
import '../models/laterbox_item.dart';
import 'item_actions.dart';

/// The canonical card used to render a saved item in the Inbox, Search,
/// Library and any future list. A card shows a cover image when enrichment
/// provided one, otherwise it stays compact. Tapping opens the item detail
/// screen; a long press surfaces the lifecycle actions.
class ItemCard extends ConsumerWidget {
  const ItemCard({super.key, required this.item});

  final LaterBoxItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = item.url == null ? null : Uri.tryParse(item.url!);
    final eyebrow =
        item.metadata?.domain ?? uri?.host.replaceFirst('www.', '') ?? 'Note';
    final title =
        item.metadata?.title ?? item.title ?? item.url ?? item.text ?? 'Untitled';
    final description = item.metadata?.description;
    final faviconUrl = item.metadata?.faviconUrl;
    final coverUrl = item.metadata?.previewImageUrl;

    return Semantics(
      label: '$eyebrow, $title, saved ${timeago.format(item.createdAt)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ItemDetailScreen(itemId: item.id),
              ),
            );
          },
          onLongPress: () => showItemActions(context, ref, item),
          child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coverUrl != null && coverUrl.isNotEmpty)
              ItemCoverImage(url: coverUrl),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardGlyph(eyebrow: eyebrow, faviconUrl: faviconUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (description != null && description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          timeago.format(item.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ],
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

/// 16:9 cover shown on rich cards. Text renders immediately; the image fades
/// in once decoded and the whole area collapses if loading fails.
class ItemCoverImage extends StatefulWidget {
  const ItemCoverImage({super.key, required this.url});

  final String url;

  @override
  State<ItemCoverImage> createState() => _ItemCoverImageState();
}

class _ItemCoverImageState extends State<ItemCoverImage> {
  bool _failed = false;

  @override
  void didUpdateWidget(covariant ItemCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _failed = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();
    return AspectRatio(
      key: const Key('itemCardCover'),
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Image.network(
          widget.url,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _failed = true);
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _CardGlyph extends StatelessWidget {
  const _CardGlyph({required this.eyebrow, this.faviconUrl});

  final String eyebrow;
  final String? faviconUrl;

  @override
  Widget build(BuildContext context) {
    final initial = eyebrow.isEmpty ? '?' : eyebrow[0].toUpperCase();
    final fallback = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );

    if (faviconUrl == null || faviconUrl!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          fallback,
          Positioned.fill(
            child: Image.network(
              faviconUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../features/attachments/presentation/attachment_providers.dart';
import '../../features/enrichment/domain/content_type.dart';
import '../../features/enrichment/domain/url_utils.dart';
import '../../features/inbox/presentation/inbox_providers.dart';
import '../models/laterbox_item.dart';
import '../models/item_status.dart';
import 'item_actions.dart';

/// A compact list row representation of a saved item, mirroring the web
/// `ItemListRow` component. Ideal for high-density reading and scanning.
class ItemListRow extends ConsumerStatefulWidget {
  const ItemListRow({
    super.key,
    required this.item,
  });

  final LaterBoxItem item;

  @override
  ConsumerState<ItemListRow> createState() => _ItemListRowState();
}

class _ItemListRowState extends ConsumerState<ItemListRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;
    final uri = widget.item.url == null ? null : Uri.tryParse(widget.item.url!);
    final isFile = widget.item.type == 'file';
    final isStarred = widget.item.favorite;

    final rawEyebrow = widget.item.metadata?.domain ??
        uri?.host.replaceFirst('www.', '') ??
        (isFile ? 'File' : 'Note');
    final eyebrow = cleanMetaText(rawEyebrow) ?? rawEyebrow;

    final rawTitle = widget.item.metadata?.title ??
        widget.item.title ??
        widget.item.url ??
        widget.item.text ??
        'Untitled';
    final title = cleanMetaText(rawTitle) ?? rawTitle;

    final faviconUrl = widget.item.metadata?.faviconUrl;
    final coverUrl = widget.item.metadata?.previewImageUrl;
    final repository = ref.read(itemRepositoryProvider);

    final borderColor = _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : theme.colorScheme.outline;

    final backgroundColor = _isHovered
        ? theme.colorScheme.surfaceContainerLow
        : theme.colorScheme.surfaceContainerLowest;

    return Semantics(
      label: '$eyebrow, $title, saved ${timeago.format(widget.item.createdAt)}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onHover: (hovered) => setState(() => _isHovered = hovered),
          onTap: () => context.push('/item/${widget.item.id}'),
          onLongPress: () => showItemActions(context, ref, widget.item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 16 : 12,
              vertical: isDesktop ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                _ItemTypeLeadingIcon(
                  item: widget.item,
                  faviconUrl: faviconUrl,
                  imageUrl: coverUrl,
                  isFile: isFile,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (isStarred) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: Colors.amber,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              eyebrow,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '·',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            timeago.format(widget.item.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          if (isFile) ...[
                            const SizedBox(width: 6),
                            _FileAttachmentBadge(itemId: widget.item.id),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: isStarred ? 'Unstar' : 'Star',
                      icon: Icon(
                        isStarred
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: isStarred
                            ? Colors.amber
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          repository.setFavorite(widget.item.id, !isStarred),
                    ),
                    if (widget.item.isActive)
                      IconButton(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Keep',
                        icon: Icon(
                          Icons.bookmark_add_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => repository.keep(widget.item.id),
                      )
                    else if (widget.item.status == ItemStatus.saved)
                      IconButton(
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Archive',
                        icon: Icon(
                          Icons.archive_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => repository.archive(widget.item.id),
                      ),
                    IconButton(
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      tooltip: 'More options',
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () =>
                          showItemActions(context, ref, widget.item),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemTypeLeadingIcon extends StatelessWidget {
  const _ItemTypeLeadingIcon({
    required this.item,
    required this.faviconUrl,
    this.imageUrl,
    required this.isFile,
  });

  final LaterBoxItem item;
  final String? faviconUrl;
  final String? imageUrl;
  final bool isFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNote =
        item.type == 'note' || (item.url == null && (item.text?.isNotEmpty ?? false));
    final type = item.metadata?.classification?.type ??
        (isFile ? ContentType.file : (isNote ? null : ContentType.link));

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFaviconOrFallback(context, type, isNote: isNote),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: _buildFaviconOrFallback(context, type, isNote: isNote),
    );
  }

  Widget _buildFaviconOrFallback(
    BuildContext context,
    ContentType? type, {
    required bool isNote,
  }) {
    if (faviconUrl != null && faviconUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          faviconUrl!,
          width: 20,
          height: 20,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackIcon(context, type, isNote: isNote),
        ),
      );
    }
    return _buildFallbackIcon(context, type, isNote: isNote);
  }

  Widget _buildFallbackIcon(
    BuildContext context,
    ContentType? type, {
    required bool isNote,
  }) {
    final theme = Theme.of(context);
    if (isFile) {
      return Icon(
        Icons.attach_file_rounded,
        size: 18,
        color: theme.colorScheme.primary,
      );
    }
    if (isNote) {
      return const Icon(
        Icons.sticky_note_2_outlined,
        size: 18,
        color: Colors.amber,
      );
    }
    return switch (type) {
      ContentType.video => const Icon(
          Icons.play_circle_outline_rounded,
          size: 18,
          color: Colors.redAccent,
        ),
      ContentType.music => const Icon(
          Icons.music_note_rounded,
          size: 18,
          color: Colors.green,
        ),
      ContentType.article => Icon(
          Icons.article_outlined,
          size: 18,
          color: theme.colorScheme.onSurface,
        ),
      _ => Icon(
          Icons.link_rounded,
          size: 18,
          color: theme.colorScheme.onSurfaceVariant,
        ),
    };
  }
}

class _FileAttachmentBadge extends ConsumerWidget {
  const _FileAttachmentBadge({required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments =
        ref.watch(attachmentsForItemProvider(itemId)).valueOrNull ?? const [];
    if (attachments.isEmpty) return const SizedBox.shrink();

    final count = attachments.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        count == 1 ? '1 file' : '$count files',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../features/enrichment/domain/content_type.dart';
import '../models/laterbox_item.dart';
import 'item_actions.dart';

/// The canonical card used to render a saved item in the Inbox, Search,
/// Library and any future list. A card shows a cover image when enrichment
/// provided one, otherwise it stays compact. Tapping opens the item detail
/// screen; a long press surfaces the lifecycle actions.
class ItemCard extends ConsumerStatefulWidget {
  const ItemCard({
    super.key,
    required this.item,
    this.isGrid = false,
  });

  final LaterBoxItem item;
  final bool isGrid;

  @override
  ConsumerState<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends ConsumerState<ItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;
    final cardPadding = isDesktop ? (widget.isGrid ? 10.0 : 16.0) : 18.0;
    final cardRadius = isDesktop ? 16.0 : 20.0;
    final uri = widget.item.url == null ? null : Uri.tryParse(widget.item.url!);
    final eyebrow =
        widget.item.metadata?.domain ?? uri?.host.replaceFirst('www.', '') ?? 'Note';
    final title =
        widget.item.metadata?.title ??
        widget.item.title ??
        widget.item.url ??
        widget.item.text ??
        'Untitled';
    final capturedText = widget.item.text?.trim();
    final isCaptured = capturedText != null && capturedText.isNotEmpty;
    final description =
        isCaptured ? capturedText : widget.item.metadata?.description?.trim();
    final faviconUrl = widget.item.metadata?.faviconUrl;
    final coverUrl = widget.item.metadata?.previewImageUrl;
    final theme = Theme.of(context);

    final borderColor = _isHovered
        ? theme.colorScheme.primary.withOpacity(0.6)
        : theme.colorScheme.outline;

    final backgroundColor = _isHovered
        ? theme.colorScheme.surfaceContainerLow
        : theme.colorScheme.surfaceContainerLowest;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.isGrid ? double.infinity : (isDesktop ? 800 : double.infinity),
        ),
        child: Semantics(
          label: '$eyebrow, $title, saved ${timeago.format(widget.item.createdAt)}',
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              transform: _isHovered && isDesktop
                  ? (Matrix4.identity()..translate(0, -2, 0))
                  : Matrix4.identity(),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(cardRadius),
                  onTap: () => context.go('/item/${widget.item.id}'),
                  onLongPress: () => showItemActions(context, ref, widget.item),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(cardRadius),
                      border: Border.all(color: borderColor, width: 1),
                      boxShadow: _isHovered && isDesktop
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.shadow.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (coverUrl != null && coverUrl.isNotEmpty)
                          ItemCoverImage(url: coverUrl)
                        else if (widget.isGrid)
                          const AspectRatio(
                            aspectRatio: 16 / 9,
                            child: _LaterBoxLogoPlaceholder(),
                          ),
                        Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: widget.isGrid
                              ? _GridCardContent(
                                  eyebrow: eyebrow,
                                  faviconUrl: faviconUrl,
                                  title: title,
                                  description: description,
                                  isCaptured: isCaptured,
                                  item: widget.item,
                                  isHovered: _isHovered,
                                )
                              : _ListCardContent(
                                  eyebrow: eyebrow,
                                  faviconUrl: faviconUrl,
                                  title: title,
                                  description: description,
                                  isCaptured: isCaptured,
                                  item: widget.item,
                                  isDesktop: isDesktop,
                                  isHovered: _isHovered,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LaterBoxLogoPlaceholder extends StatelessWidget {
  const _LaterBoxLogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Image.asset(
            'assets/branding/laterbox-icon.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.bookmark_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

class _GridCardContent extends StatelessWidget {
  const _GridCardContent({
    required this.eyebrow,
    this.faviconUrl,
    required this.title,
    this.description,
    required this.isCaptured,
    required this.item,
    required this.isHovered,
  });

  final String eyebrow;
  final String? faviconUrl;
  final String title;
  final String? description;
  final bool isCaptured;
  final LaterBoxItem item;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription = description != null && description!.trim().isNotEmpty;
    final displayDescription = hasDescription
        ? (isCaptured ? '“$description”' : description!.trim())
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _CardGlyph(
              eyebrow: eyebrow,
              faviconUrl: faviconUrl,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                eyebrow.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isHovered)
              Consumer(
                builder: (context, ref, _) => IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'More actions',
                  onPressed: () => showItemActions(context, ref, item),
                ),
              ),
          ],
        ),
        ItemTypeBadge(item: item),
        const SizedBox(height: 4),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 1.2,
          ),
        ),
        if (displayDescription != null) ...[
          const SizedBox(height: 3),
          Text(
            displayDescription,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.25,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          timeago.format(item.createdAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _ListCardContent extends StatelessWidget {
  const _ListCardContent({
    required this.eyebrow,
    this.faviconUrl,
    required this.title,
    this.description,
    required this.isCaptured,
    required this.item,
    required this.isDesktop,
    required this.isHovered,
  });

  final String eyebrow;
  final String? faviconUrl;
  final String title;
  final String? description;
  final bool isCaptured;
  final LaterBoxItem item;
  final bool isDesktop;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CardGlyph(
          eyebrow: eyebrow,
          faviconUrl: faviconUrl,
          size: isDesktop ? 40 : 44,
        ),
        SizedBox(width: isDesktop ? 12 : 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      eyebrow.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  if (isDesktop && isHovered)
                    Consumer(
                      builder: (context, ref, _) => IconButton(
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'More actions',
                        onPressed: () => showItemActions(
                          context,
                          ref,
                          item,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ItemTypeBadge(item: item),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  isCaptured ? '“$description”' : description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                timeago.format(item.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
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

class _ItemCoverImageState extends State<ItemCoverImage>
    with AutomaticKeepAliveClientMixin {
  bool _failed = false;
  bool _usingProxy = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant ItemCoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _failed = false;
        _usingProxy = false;
      });
    }
  }

  String _getEffectiveUrl() {
    if (_usingProxy) {
      final clean = widget.url.replaceFirst(RegExp(r'^https?://'), '');
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(clean)}';
    }
    return widget.url;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_failed) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: _LaterBoxLogoPlaceholder(),
      );
    }

    final theme = Theme.of(context);
    final currentUrl = _getEffectiveUrl();

    return AspectRatio(
      key: const Key('itemCardCover'),
      aspectRatio: 16 / 9,
      child: Container(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Image.network(
          currentUrl,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            if (frame == null) {
              return const _LaterBoxLogoPlaceholder();
            }
            return AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (!_usingProxy) {
                setState(() => _usingProxy = true);
              } else if (!_failed) {
                setState(() => _failed = true);
              }
            });
            return const _LaterBoxLogoPlaceholder();
          },
        ),
      ),
    );
  }
}

class _CardGlyph extends StatelessWidget {
  const _CardGlyph({required this.eyebrow, this.faviconUrl, this.size = 44});

  final String eyebrow;
  final String? faviconUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = eyebrow.isEmpty ? '?' : eyebrow[0].toUpperCase();
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size * 0.27),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style:
            (size < 44
                    ? Theme.of(context).textTheme.titleSmall
                    : Theme.of(context).textTheme.titleMedium)
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
      ),
    );

    if (faviconUrl == null || faviconUrl!.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.27),
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

/// A small type pill shown on [ItemCard]. Only non-link/unknown classifications
/// render; their confidence must be strong enough to be meaningful (>= 0.5).
class ItemTypeBadge extends StatelessWidget {
  const ItemTypeBadge({super.key, required this.item});

  final LaterBoxItem item;

  @override
  Widget build(BuildContext context) {
    final classification = item.metadata?.classification;
    if (classification == null) return const SizedBox.shrink();
    final type = classification.type;
    if (type == ContentType.link || type == ContentType.unknown) {
      return const SizedBox.shrink();
    }
    if (classification.confidence < 0.5) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(type.icon, size: 14),
            const SizedBox(width: 4),
            Text(
              type.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../features/attachments/presentation/attachment_preview.dart';
import '../../features/attachments/presentation/attachment_providers.dart';
import '../../features/enrichment/domain/content_type.dart';
import '../../features/enrichment/domain/url_utils.dart';
import '../../features/inbox/presentation/inbox_providers.dart';
import '../../features/scheduling/presentation/return_time_picker.dart';
import '../models/laterbox_item.dart';
import 'item_actions.dart';

/// The canonical card used to render a saved item in the Inbox, Search,
/// Library and any future list. A card shows a cover image when enrichment
/// provided one, otherwise it stays compact. Tapping opens the item detail
/// screen; a long press surfaces the lifecycle actions.
class ItemCard extends ConsumerStatefulWidget {
  const ItemCard({super.key, required this.item, this.isGrid = false});

  final LaterBoxItem item;
  final bool isGrid;

  @override
  ConsumerState<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends ConsumerState<ItemCard> {
  bool _isHovered = false;

  bool get _isPsd {
    final ext = widget.item.url?.split('.').last.toLowerCase();
    final title = (widget.item.metadata?.title ?? widget.item.title ?? '').toLowerCase();
    return ext == 'psd' || ext == 'psb' || title.endsWith('.psd');
  }

  bool get _isPdf {
    final ext = widget.item.url?.split('.').last.toLowerCase();
    final title = (widget.item.metadata?.title ?? widget.item.title ?? '').toLowerCase();
    return ext == 'pdf' || title.endsWith('.pdf');
  }

  bool get _isVideo {
    final url = widget.item.url ?? '';
    return widget.item.type == 'video' ||
        url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('vimeo.com');
  }

  bool get _isMusic {
    final url = widget.item.url ?? '';
    return widget.item.type == 'music' ||
        url.contains('spotify.com') ||
        url.contains('music.apple.com');
  }

  bool get _isNote {
    return widget.item.type == 'note' ||
        (widget.item.url == null && widget.item.text != null && widget.item.text!.isNotEmpty);
  }

  bool get _isArticle {
    final domain = widget.item.metadata?.domain ?? '';
    return widget.item.type == 'article' ||
        domain.contains('notion.so') ||
        domain.contains('medium.com');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;
    final cardPadding = isDesktop ? (widget.isGrid ? 10.0 : 16.0) : 18.0;
    final cardRadius = isDesktop ? 16.0 : 20.0;
    final uri = widget.item.url == null ? null : Uri.tryParse(widget.item.url!);
    final isFile = widget.item.type == 'file';
    final rawEyebrow =
        widget.item.metadata?.domain ??
        uri?.host.replaceFirst('www.', '') ??
        (isFile ? 'File' : 'Note');
    final eyebrow = cleanMetaText(rawEyebrow) ?? rawEyebrow;
    final rawTitle =
        widget.item.metadata?.title ??
        widget.item.title ??
        widget.item.url ??
        widget.item.text ??
        'Untitled';
    final title = cleanMetaText(rawTitle) ?? rawTitle;
    final capturedText = widget.item.text?.trim();
    final isCaptured = capturedText != null && capturedText.isNotEmpty;
    final description = isCaptured
        ? capturedText
        : cleanMetaText(widget.item.metadata?.description?.trim());
    final faviconUrl = widget.item.metadata?.faviconUrl;
    final coverUrl = widget.item.metadata?.previewImageUrl;
    final attachments = isFile
        ? ref.watch(attachmentsForItemProvider(widget.item.id)).value
        : null;
    final attachmentStorage = isFile && !kIsWeb
        ? ref.watch(attachmentStorageProvider).value
        : null;
    final previewAttachment = attachments?.firstOrNull;
    final needsRemotePreview =
        previewAttachment != null &&
        previewAttachment.mimeType.startsWith('image/') &&
        previewAttachment.r2ObjectKey != null;
    final remoteImageUrl = needsRemotePreview
        ? ref.watch(attachmentPreviewUrlProvider(previewAttachment.id)).valueOrNull
        : null;
    final theme = Theme.of(context);

    final borderColor = _isHovered
        ? theme.colorScheme.primary.withValues(alpha: 0.6)
        : theme.colorScheme.outline;

    final backgroundColor = _isHovered
        ? theme.colorScheme.surfaceContainerLow
        : theme.colorScheme.surfaceContainerLowest;

    return RepaintBoundary(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.isGrid
                ? double.infinity
                : (isDesktop ? 800 : double.infinity),
          ),
          child: Semantics(
            label: widget.item.returnAt != null
                ? '$eyebrow, $title, returns ${returnTimeLabel(context, widget.item.returnAt)}'
                : '$eyebrow, $title, saved ${timeago.format(widget.item.createdAt)}',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              transform: _isHovered && isDesktop
                  ? Matrix4.translationValues(0.0, -2.0, 0.0)
                  : Matrix4.identity(),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(cardRadius),
                  onHover: (hovered) => setState(() => _isHovered = hovered),
                  onTap: () => context.push('/item/${widget.item.id}'),
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
                                color: theme.colorScheme.shadow.withValues(
                                  alpha: 0.08,
                                ),
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
                        if (attachments != null && attachments.isNotEmpty)
                          AttachmentCardPreview(
                            attachments: attachments,
                            storage: attachmentStorage,
                            remoteImageUrl: remoteImageUrl,
                          )
                        else if (_isPsd || _isPdf || _isVideo || _isMusic)
                          _ContentBanner(
                            item: widget.item,
                            isPsd: _isPsd,
                            isPdf: _isPdf,
                            isVideo: _isVideo,
                            isMusic: _isMusic,
                            isNote: _isNote,
                            isArticle: _isArticle,
                          )
                        else if (coverUrl != null && coverUrl.isNotEmpty)
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
                                  imageUrl: coverUrl,
                                  title: title,
                                  description: description,
                                  isCaptured: isCaptured,
                                  item: widget.item,
                                  isHovered: _isHovered,
                                )
                              : _ListCardContent(
                                  eyebrow: eyebrow,
                                  faviconUrl: faviconUrl,
                                  imageUrl: coverUrl,
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
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
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
    this.imageUrl,
    required this.title,
    this.description,
    required this.isCaptured,
    required this.item,
    required this.isHovered,
  });

  final String eyebrow;
  final String? faviconUrl;
  final String? imageUrl;
  final String title;
  final String? description;
  final bool isCaptured;
  final LaterBoxItem item;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDescription =
        description != null && description!.trim().isNotEmpty;
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
              imageUrl: imageUrl,
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
                builder: (context, ref, _) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        item.isArchived
                            ? Icons.mark_email_unread_outlined
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      tooltip: item.isArchived
                          ? 'Mark as unseen'
                          : 'Mark as seen',
                      onPressed: () {
                        final repo = ref.read(itemRepositoryProvider);
                        if (item.isArchived) {
                          repo.markUnseen(item.id);
                        } else {
                          repo.markSeen(item.id);
                        }
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.more_horiz_rounded, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'More actions',
                      onPressed: () => showItemActions(context, ref, item),
                    ),
                  ],
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
          item.returnAt != null
              ? returnTimeLabel(context, item.returnAt)
              : timeago.format(item.createdAt),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
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
    this.imageUrl,
    required this.title,
    this.description,
    required this.isCaptured,
    required this.item,
    required this.isDesktop,
    required this.isHovered,
  });

  final String eyebrow;
  final String? faviconUrl;
  final String? imageUrl;
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
          imageUrl: imageUrl,
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
                      builder: (context, ref, _) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              item.isArchived
                                  ? Icons.mark_email_unread_outlined
                                  : Icons.check_circle_outline_rounded,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            tooltip: item.isArchived
                                ? 'Mark as unseen'
                                : 'Mark as seen',
                            onPressed: () {
                              final repo = ref.read(itemRepositoryProvider);
                              if (item.isArchived) {
                                repo.markUnseen(item.id);
                              } else {
                                repo.markSeen(item.id);
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(
                              Icons.more_horiz_rounded,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            tooltip: 'More actions',
                            onPressed: () =>
                                showItemActions(context, ref, item),
                          ),
                        ],
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
                item.returnAt != null
                    ? returnTimeLabel(context, item.returnAt)
                    : timeago.format(item.createdAt),
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
  const _CardGlyph({
    required this.eyebrow,
    this.faviconUrl,
    this.imageUrl,
    this.size = 44,
  });

  final String eyebrow;
  final String? faviconUrl;
  final String? imageUrl;
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

    // If an image preview is available (e.g. cover/thumbnail), display it nicely
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      final effectiveImageUrl = kIsWeb
          ? 'https://images.weserv.nl/?url=${Uri.encodeComponent(imageUrl!.replaceFirst(RegExp(r'^https?://'), ''))}'
          : imageUrl!;

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(size * 0.27),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            fallback,
            Positioned.fill(
              child: Image.network(
                effectiveImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  if (faviconUrl != null && faviconUrl!.isNotEmpty) {
                    final effectiveFaviconUrl = kIsWeb
                        ? 'https://images.weserv.nl/?url=${Uri.encodeComponent(faviconUrl!.replaceFirst(RegExp(r'^https?://'), ''))}'
                        : faviconUrl!;
                    return Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(size * 0.12),
                      child: Image.network(
                        effectiveFaviconUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      );
    }

    if (faviconUrl == null || faviconUrl!.isEmpty) return fallback;
    final effectiveFaviconUrl = kIsWeb
        ? 'https://images.weserv.nl/?url=${Uri.encodeComponent(faviconUrl!.replaceFirst(RegExp(r'^https?://'), ''))}'
        : faviconUrl!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.27),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          fallback,
          Positioned.fill(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(size * 0.12),
              child: Image.network(
                effectiveFaviconUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rich content-type banner matching the web ItemCard visual style.
class _ContentBanner extends StatelessWidget {
  const _ContentBanner({
    required this.item,
    required this.isPsd,
    required this.isPdf,
    required this.isVideo,
    required this.isMusic,
    required this.isNote,
    required this.isArticle,
  });

  final LaterBoxItem item;
  final bool isPsd, isPdf, isVideo, isMusic, isNote, isArticle;

  @override
  Widget build(BuildContext context) {
    if (isPsd) return _PsdBanner();
    if (isPdf) return _PdfBanner();
    if (isVideo) return _VideoBanner(item: item);
    if (isMusic) return _MusicBanner(item: item);
    return const SizedBox.shrink();
  }
}

class _PsdBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E1B4B),
            Color(0xFF701A75),
            Color(0xFFEC4899),
            Color(0xFF84CC16),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black26, Colors.transparent, Colors.black26],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Design File',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF001E36),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Ps',
                style: TextStyle(
                  color: Color(0xFF31A8FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PdfBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      color: const Color(0xFFF8F7F4),
      child: Stack(
        children: [
          Center(
            child: Container(
              width: 100,
              height: 80,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE4E0D5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final w in [1.0, 0.83, 0.67, 1.0, 0.75])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: FractionallySizedBox(
                        widthFactor: w,
                        child: Container(
                          height: 5,
                          color: const Color(0xFFE4E0D5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Document',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                'PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoBanner extends StatelessWidget {
  const _VideoBanner({required this.item});
  final LaterBoxItem item;

  @override
  Widget build(BuildContext context) {
    final coverUrl = item.metadata?.previewImageUrl;
    final domain = item.metadata?.domain ?? '';

    return Container(
      height: 140,
      color: const Color(0xFF171714),
      child: Stack(
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(Icons.play_circle_outline_rounded,
                      color: Colors.white24, size: 48),
                ),
              ),
            )
          else
            const Center(
              child: Icon(Icons.play_circle_outline_rounded,
                  color: Colors.white24, size: 48),
            ),
          if (domain.isNotEmpty)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  domain,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEA4335),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'Video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

class _MusicBanner extends StatelessWidget {
  const _MusicBanner({required this.item});
  final LaterBoxItem item;

  @override
  Widget build(BuildContext context) {
    final coverUrl = item.metadata?.previewImageUrl;

    return Container(
      height: 140,
      color: const Color(0xFF171714),
      child: Stack(
        children: [
          if (coverUrl != null && coverUrl.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF065F46), Color(0xFF134E4A)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.music_note_rounded,
                        color: Color(0xFF34D399), size: 48),
                  ),
                ),
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF065F46), Color(0xFF134E4A)],
                ),
              ),
              child: const Center(
                child: Icon(Icons.music_note_rounded,
                    color: Color(0xFF34D399), size: 48),
              ),
            ),
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_note_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 5),
                  Text(
                    'Music',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

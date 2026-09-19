import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/database/app_database.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../shared/models/laterbox_item.dart';
import '../../../shared/utils/media_embed_helper.dart';
import '../../../shared/widgets/item_actions.dart';
import '../../../shared/widgets/item_card.dart';
import '../../../shared/widgets/media_embed_hero.dart';
import '../../attachments/data/attachment_storage_api.dart';
import '../../attachments/presentation/attachment_preview.dart';
import '../../attachments/presentation/attachment_providers.dart';
import '../../collections/presentation/collection_providers.dart';
import '../../inbox/presentation/inbox_providers.dart';
import '../../notes/presentation/item_note_section.dart';
import 'detail_providers.dart';
import '../../scheduling/presentation/return_time_picker.dart';

/// The permanent home for a single item: rich preview, open-original, and the
/// full set of lifecycle actions without cluttering the cards.
class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  @override
  Widget build(BuildContext context) {
    ref.listen(itemDetailProvider(widget.itemId), (previous, next) {
      final wasPresent = previous?.value != null;
      final nowAbsent = next.value == null;
      if (wasPresent && nowAbsent && mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/inbox');
        }
      }
    });

    final item = ref.watch(itemDetailProvider(widget.itemId)).value;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/inbox');
            }
          },
        ),
        actions: [
          if (item != null) ...[
            IconButton(
              tooltip: item.favorite ? 'Remove from favorites' : 'Favorite',
              icon: Icon(
                item.favorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: item.favorite
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              onPressed: () {
                ref
                    .read(itemRepositoryProvider)
                    .setFavorite(item.id, !item.favorite);
              },
            ),
            IconButton(
              tooltip: item.isArchived ? 'Mark as unseen' : 'Mark as seen',
              icon: Icon(
                item.isArchived
                    ? Icons.mark_email_unread_outlined
                    : Icons.check_circle_outline_rounded,
              ),
              onPressed: () {
                final repo = ref.read(itemRepositoryProvider);
                if (item.isArchived) {
                  repo.markUnseen(item.id);
                } else {
                  repo.markSeen(item.id);
                }
              },
            ),
            IconButton(
              tooltip: 'More actions',
              onPressed: () => showItemActions(context, ref, item),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: item == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _ItemDetailBody(item: item),
    );
  }
}

class _ItemDetailBody extends ConsumerWidget {
  const _ItemDetailBody({required this.item});

  final LaterBoxItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawText = item.text?.trim();
    final embeddedUrlMatch = rawText != null
        ? RegExp(r'(https?://[^\s]+)').firstMatch(rawText)
        : null;
    final effectiveUrl = item.url ?? embeddedUrlMatch?.group(0);
    final uri = effectiveUrl == null ? null : Uri.tryParse(effectiveUrl);
    final isFile = item.type == 'file';
    final eyebrow =
        item.metadata?.domain ??
        uri?.host.replaceFirst('www.', '') ??
        (isFile ? 'File' : 'Note');
    final cleanCapturedText =
        (rawText != null &&
            effectiveUrl != null &&
            rawText.contains(effectiveUrl))
        ? rawText
              .replaceFirst(effectiveUrl, '')
              .trim()
              .replaceAll(RegExp(r'^["“”\s]+|["“”\s]+$'), '')
        : rawText;
    final isCaptured =
        cleanCapturedText != null && cleanCapturedText.isNotEmpty;
    final effectiveItem = (item.url == null && effectiveUrl != null)
        ? item.copyWith(url: effectiveUrl, text: cleanCapturedText)
        : (cleanCapturedText != null && cleanCapturedText != item.text
              ? item.copyWith(text: cleanCapturedText)
              : item);
    final sourceTitle = item.metadata?.title ?? item.title;
    final title =
        item.metadata?.title ??
        item.title ??
        effectiveUrl ??
        cleanCapturedText ??
        'Untitled';
    final description = item.metadata?.description;

    final ext = (effectiveUrl ?? '').split('.').last.toLowerCase();
    final titleLower = title.toLowerCase();
    final isPsd =
        ext == 'psd' || ext == 'psb' || titleLower.endsWith('.psd');
    final isPdf =
        ext == 'pdf' || titleLower.endsWith('.pdf');
    final isVideo =
        item.type == 'video' ||
        (effectiveUrl != null &&
            (effectiveUrl.contains('youtube.com') ||
                effectiveUrl.contains('youtu.be') ||
                effectiveUrl.contains('vimeo.com')));
    final isMusic =
        item.type == 'music' ||
        (effectiveUrl != null &&
            (effectiveUrl.contains('spotify.com') ||
                effectiveUrl.contains('music.apple.com')));
    final isNote =
        item.type == 'note' ||
        (item.url == null &&
            item.text != null &&
            item.text!.isNotEmpty);
    final isArticle =
        item.type == 'article' ||
        (eyebrow.contains('notion.so') || eyebrow.contains('medium.com'));
    final collections = ref.watch(collectionsForItemProvider(item.id)).value;
    final embedInfo = MediaEmbedHelper.parse(effectiveUrl);
    final attachmentsState = isFile
        ? ref.watch(attachmentsForItemProvider(item.id))
        : null;
    final storageState = isFile && !kIsWeb
        ? ref.watch(attachmentStorageProvider)
        : null;
    final attachments = attachmentsState?.value;
    final attachmentStorage = storageState?.value;
    final remoteImageUrls = <String, String>{};
    for (final attachment in attachments ?? const <Attachment>[]) {
      if (attachment.mimeType.startsWith('image/') &&
          attachment.r2ObjectKey != null &&
          (attachmentStorage == null || attachment.localPath == null)) {
        final url = ref
            .watch(attachmentPreviewUrlProvider(attachment.id))
            .valueOrNull;
        if (url != null) remoteImageUrls[attachment.id] = url;
      }
    }
    final hasAttachmentPreview = attachments != null && attachments.isNotEmpty;
    Future<String> resolveRemotePath(Attachment attachment) async {
      if (kIsWeb) {
        final client = ref.read(supabaseClientProvider);
        if (client != null && attachment.r2ObjectKey != null) {
          try {
            return await AttachmentStorageApi(client)
                .prepareDownloadUrl(attachment.id);
          } catch (error) {
            debugPrint(
              '[LaterBox Detail] resolve remote download failed: $error',
            );
            throw StateError('Attachment is not available for download.');
          }
        }
        throw StateError('Attachment is not available for remote download.');
      }
      final service = await ref.read(attachmentSyncServiceProvider.future);
      if (service == null) {
        throw StateError('Attachment sync is unavailable.');
      }
      return service.download(attachment);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: ReturnTimePicker(
            value: item.returnAt,
            onChanged: (time) =>
                ref.read(itemRepositoryProvider).reschedule(item.id, time),
          ),
        ),
        if (item.type == 'task' && item.isActive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FilledButton.icon(
              onPressed: () =>
                  ref.read(itemRepositoryProvider).archive(item.id),
              icon: const Icon(Icons.task_alt),
              label: const Text('Done'),
            ),
          ),
        if (hasAttachmentPreview)
          AttachmentDetailPreview(
            attachments: attachments,
            storage: attachmentStorage,
            showList: false,
            resolveRemotePath: resolveRemotePath,
            remoteImageUrls: remoteImageUrls,
          )
        else if (isPsd)
          _ContentBanner(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1e1b4b),
                        Color(0xFF701a75),
                        Color(0xFFec4899),
                        Color(0xFF84cc16),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black54,
                          Colors.transparent,
                          Colors.black26,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: _BannerBadge(
                    icon: Icons.circle,
                    iconSize: 8,
                    label: 'Design File',
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF001e36),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                      boxShadow: const [
                        BoxShadow(blurRadius: 8, color: Colors.black26),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Ps',
                        style: TextStyle(
                          color: Color(0xFF31a8ff),
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (isPdf)
          _ContentBanner(
            child: Container(
              width: double.infinity,
              height: 220,
              color: const Color(0xFFf8f7f4),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 220,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFe4e0d5)),
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 12,
                            color: Colors.black12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          5,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFe4e0d5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              width: switch (i) {
                                0 => double.infinity,
                                1 => 180,
                                2 => 150,
                                3 => double.infinity,
                                _ => 160,
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _BannerBadge(
                      icon: Icons.circle,
                      iconSize: 8,
                      label: 'PDF Document',
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFef4444),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(blurRadius: 8, color: Colors.black26),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'PDF',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (isVideo)
          _ContentBanner(
            child: Container(
              width: double.infinity,
              height: 260,
              color: Colors.black,
              child: Stack(
                children: [
                  if (item.metadata?.previewImageUrl case final img?)
                    Image.network(
                      img,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 260,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF262626), Color(0xFF0a0a0a)],
                          ),
                        ),
                        child: const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 48,
                          color: Colors.white38,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 260,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF262626), Color(0xFF0a0a0a)],
                        ),
                      ),
                      child: const Icon(
                        Icons.play_circle_outline_rounded,
                        size: 48,
                        color: Colors.white38,
                      ),
                    ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black54,
                            Colors.transparent,
                            Colors.black26,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _BannerBadge(
                      icon: Icons.language_rounded,
                      label: eyebrow,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFea4335),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(blurRadius: 4, color: Colors.black26),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            'Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (isMusic)
          _ContentBanner(
            child: Container(
              width: double.infinity,
              height: 260,
              color: const Color(0xFF171717),
              child: Stack(
                children: [
                  if (item.metadata?.previewImageUrl case final img?)
                    Image.network(
                      img,
                      width: double.infinity,
                      height: 260,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: double.infinity,
                        height: 260,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF065f46), Color(0xFF134e4a)],
                          ),
                        ),
                        child: const Icon(
                          Icons.music_note_rounded,
                          size: 48,
                          color: Color(0xFF34d399),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 260,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF065f46), Color(0xFF134e4a)],
                        ),
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        size: 48,
                        color: Color(0xFF34d399),
                      ),
                    ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black54,
                            Colors.transparent,
                            Colors.black26,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _BannerBadge(
                      icon: Icons.music_note_rounded,
                      label: 'Music',
                    ),
                  ),
                  const Positioned.fill(
                    child: Center(
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFF2F2F2),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          size: 28,
                          color: Color(0xFF171711),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (isNote)
          _ContentBanner(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: const Color(0xFFfbfaf6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFe6edb0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Icon(
                      Icons.sticky_note_2_rounded,
                      color: Color(0xFF171711),
                      size: 22,
                    ),
                  ),
                  _BannerBadge(
                    icon: Icons.circle,
                    iconSize: 8,
                    label: 'Note',
                    filled: true,
                  ),
                ],
              ),
            ),
          )
        else if (isArticle)
          _ContentBanner(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: const Color(0xFFfbfaf6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFe4e0d5)),
                      boxShadow: const [
                        BoxShadow(blurRadius: 2, color: Colors.black12),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              'N',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          eyebrow,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171711),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BannerBadge(
                    icon: Icons.circle,
                    iconSize: 8,
                    label: 'Article',
                    filled: true,
                  ),
                ],
              ),
            ),
          )
        else if (embedInfo != null)
          MediaEmbedHero(
            embedInfo: embedInfo,
            fallbackCoverUrl: item.metadata?.previewImageUrl,
          )
        else if (item.metadata?.previewImageUrl case final cover?)
          ItemCoverImage(url: cover),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              if (isCaptured) ...[
                Text(
                  'Selected text',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '“$cleanCapturedText”',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Source',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                if (sourceTitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    sourceTitle,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
                if (effectiveUrl != null) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => openOriginalForItem(context, effectiveItem),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        effectiveUrl,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else if (sourceTitle == null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'laterbox note',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
              if (effectiveUrl != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => openOriginalForItem(context, effectiveItem),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text('Open original'),
                ),
              ],
            ],
          ),
        ),
        if (hasAttachmentPreview)
          AttachmentDetailPreview(
            attachments: attachments,
            storage: attachmentStorage,
            showGallery: false,
            resolveRemotePath: resolveRemotePath,
            remoteImageUrls: remoteImageUrls,
          )
        else if (isFile)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child:
                  attachmentsState?.hasError == true ||
                      storageState?.hasError == true
                  ? const Text('Attachment previews could not be loaded.')
                  : attachmentsState?.isLoading == true ||
                        storageState?.isLoading == true
                  ? const CircularProgressIndicator.adaptive()
                  : const Text('No attachments are available for this item.'),
            ),
          ),
        const SizedBox(height: 12),
        const Divider(height: 32),
        ItemNoteSection(itemId: item.id),
        const SizedBox(height: 12),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: const Text('Collection'),
                subtitle: Text(
                  (collections?.isEmpty ?? true)
                      ? 'Not in a collection'
                      : collections!
                            .map((collection) => collection.name)
                            .join(', '),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showCollectionPicker(context, ref, item.id),
              ),
              ListTile(
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Saved'),
                subtitle: Text(
                  '${timeago.format(item.createdAt)} · '
                  '${_formatDate(item.createdAt)}',
                ),
              ),
              if (effectiveUrl != null)
                ListTile(
                  leading: const Icon(Icons.link_rounded),
                  title: const Text('URL'),
                  subtitle: Text(
                    effectiveUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () => openOriginalForItem(context, effectiveItem),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _ContentBanner extends StatelessWidget {
  const _ContentBanner({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: child,
    );
  }
}

class _BannerBadge extends StatelessWidget {
  const _BannerBadge({
    required this.label,
    this.icon,
    this.iconSize = 12,
    this.filled = false,
  });
  final String label;
  final IconData? icon;
  final double iconSize;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? const Color(0xFFebe7dc) : Colors.black54,
        borderRadius: BorderRadius.circular(20),
        boxShadow: filled ? null : const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: filled ? const Color(0xFF171711) : Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: filled ? const Color(0xFF171711) : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

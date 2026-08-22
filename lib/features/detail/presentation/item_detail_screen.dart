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
import '../../notes/presentation/item_note_section.dart';
import 'detail_providers.dart';

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
          if (item != null)
            IconButton(
              tooltip: 'More actions',
              onPressed: () => showItemActions(context, ref, item),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
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
    final uri = item.url == null ? null : Uri.tryParse(item.url!);
    final isFile = item.type == 'file';
    final eyebrow =
        item.metadata?.domain ??
        uri?.host.replaceFirst('www.', '') ??
        (isFile ? 'File' : 'Note');
    final capturedText = item.text?.trim();
    final isCaptured = capturedText != null && capturedText.isNotEmpty;
    final sourceTitle = item.metadata?.title ?? item.title;
    final title =
        item.metadata?.title ??
        item.title ??
        item.url ??
        item.text ??
        'Untitled';
    final description = item.metadata?.description;
    final collections = ref.watch(collectionsForItemProvider(item.id)).value;
    final embedInfo = MediaEmbedHelper.parse(item.url);
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
            .value;
        if (url != null) remoteImageUrls[attachment.id] = url;
      }
    }
    final hasAttachmentPreview = attachments != null && attachments.isNotEmpty;
    Future<String> resolveRemotePath(Attachment attachment) async {
      if (kIsWeb) {
        final client = ref.read(supabaseClientProvider);
        if (client != null && attachment.r2ObjectKey != null) {
          return AttachmentStorageApi(client).prepareDownloadUrl(attachment.id);
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
        if (hasAttachmentPreview)
          AttachmentDetailPreview(
            attachments: attachments,
            storage: attachmentStorage,
            showList: false,
            resolveRemotePath: resolveRemotePath,
            remoteImageUrls: remoteImageUrls,
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
                  '“$capturedText”',
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
                if (item.url != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.url!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (sourceTitle == null && item.url == null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'LaterBox note',
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
              if (item.url != null) ...[
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => openOriginalForItem(context, item),
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
              if (item.url != null)
                ListTile(
                  leading: const Icon(Icons.link_rounded),
                  title: const Text('URL'),
                  subtitle: Text(item.url!, maxLines: 1),
                  onTap: () => openOriginalForItem(context, item),
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

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/database/app_database.dart';
import '../data/attachment_storage.dart';

class AttachmentCardPreview extends StatelessWidget {
  const AttachmentCardPreview({
    super.key,
    required this.attachments,
    this.storage,
    this.remoteImageUrl,
  });

  final List<Attachment> attachments;
  final AttachmentStorage? storage;
  final String? remoteImageUrl;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final attachment = attachments.first;
    final additionalCount = attachments.length - 1;
    final path = _resolvedPath(storage, attachment);

    return Semantics(
      image: attachment.mimeType.startsWith('image/'),
      label: _semanticLabel(attachment, attachments.length),
      child: AspectRatio(
        key: const Key('attachmentCardPreview'),
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (attachment.mimeType.startsWith('image/'))
              _LocalImage(
                path: path,
                remoteUrl: remoteImageUrl,
                attachment: attachment,
              )
            else
              _FilePreviewSurface(attachment: attachment),
            if (additionalCount > 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.inverseSurface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '+$additionalCount',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class AttachmentDetailPreview extends StatelessWidget {
  const AttachmentDetailPreview({
    super.key,
    required this.attachments,
    required this.storage,
    this.showGallery = true,
    this.showList = true,
    this.resolveRemotePath,
    this.remoteImageUrls = const {},
  });

  final List<Attachment> attachments;
  final AttachmentStorage? storage;
  final bool showGallery;
  final bool showList;
  final Future<String> Function(Attachment attachment)? resolveRemotePath;
  final Map<String, String> remoteImageUrls;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    final images = attachments
        .where((attachment) => attachment.mimeType.startsWith('image/'))
        .toList();
    final files = attachments
        .where((attachment) => !attachment.mimeType.startsWith('image/'))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showGallery && images.isNotEmpty)
          _ImageGallery(
            images: images,
            storage: storage,
            remoteImageUrls: remoteImageUrls,
          ),
        if (showList) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              attachments.length == 1
                  ? 'Attachment'
                  : '${attachments.length} attachments',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          for (final attachment in [...images, ...files])
            _AttachmentRow(
              attachment: attachment,
              path: _resolvedPath(storage, attachment),
              resolveRemotePath: resolveRemotePath,
            ),
        ],
      ],
    );
  }
}

class _ImageGallery extends StatefulWidget {
  const _ImageGallery({
    required this.images,
    required this.storage,
    required this.remoteImageUrls,
  });

  final List<Attachment> images;
  final AttachmentStorage? storage;
  final Map<String, String> remoteImageUrls;

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final selected = widget.images[_selectedIndex];
    final selectedPath = _resolvedPath(widget.storage, selected);

    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 520),
          child: Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: _LocalImage(
              path: selectedPath,
              remoteUrl: widget.remoteImageUrls[selected.id],
              attachment: selected,
              fit: BoxFit.contain,
            ),
          ),
        ),
        if (widget.images.length > 1)
          SizedBox(
            height: 88,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final attachment = widget.images[index];
                final selected = index == _selectedIndex;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: 'Preview ${attachment.originalFileName}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 72,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outlineVariant,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: _LocalImage(
                        path: _resolvedPath(widget.storage, attachment),
                        remoteUrl: widget.remoteImageUrls[attachment.id],
                        attachment: attachment,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.attachment,
    required this.path,
    required this.resolveRemotePath,
  });

  final Attachment attachment;
  final String? path;
  final Future<String> Function(Attachment attachment)? resolveRemotePath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _fileColor(context, attachment),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_fileIcon(attachment)),
        ),
        title: Text(
          attachment.originalFileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${_typeLabel(attachment)} · ${formatAttachmentBytes(attachment.byteSize)}',
        ),
        trailing: IconButton(
          tooltip: 'Open ${attachment.originalFileName}',
          icon: const Icon(Icons.open_in_new_rounded),
          onPressed: path == null && resolveRemotePath == null
              ? null
              : () => _open(context),
        ),
        onTap: path == null && resolveRemotePath == null
            ? null
            : () => _open(context),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    try {
      final resolved = path ?? await resolveRemotePath!(attachment);
      if (context.mounted) {
        await openLocalAttachment(context, resolved, attachment.mimeType);
      }
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not download this attachment.')),
        );
      }
    }
  }
}

class _LocalImage extends StatelessWidget {
  const _LocalImage({
    required this.path,
    this.remoteUrl,
    required this.attachment,
    this.fit = BoxFit.cover,
  });

  final String? path;
  final String? remoteUrl;
  final Attachment attachment;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final localBytes = attachment.localBytes;
    if (localBytes != null) {
      return Image.memory(
        localBytes,
        key: ValueKey('attachmentImage:${attachment.id}:memory'),
        fit: fit,
        gaplessPlayback: true,
        semanticLabel: attachment.originalFileName,
        errorBuilder: (context, error, stackTrace) =>
            _FilePreviewSurface(attachment: attachment, unavailable: true),
      );
    }
    final path = this.path;
    if (!kIsWeb && path != null) {
      return Image.file(
        File(path),
        key: ValueKey('attachmentImage:${attachment.id}:$path'),
        fit: fit,
        gaplessPlayback: true,
        semanticLabel: attachment.originalFileName,
        errorBuilder: (context, error, stackTrace) =>
            _FilePreviewSurface(attachment: attachment, unavailable: true),
      );
    }
    final remoteUrl = this.remoteUrl;
    if (remoteUrl == null) {
      return _FilePreviewSurface(attachment: attachment, unavailable: true);
    }
    return Image.network(
      remoteUrl,
      key: ValueKey('attachmentImage:${attachment.id}:remote'),
      fit: fit,
      gaplessPlayback: true,
      semanticLabel: attachment.originalFileName,
      errorBuilder: (context, error, stackTrace) =>
          _FilePreviewSurface(attachment: attachment, unavailable: true),
    );
  }
}

String? _resolvedPath(AttachmentStorage? storage, Attachment attachment) {
  final localPath = attachment.localPath;
  return localPath == null || storage == null
      ? null
      : storage.resolveLocalPath(localPath);
}

class _FilePreviewSurface extends StatelessWidget {
  const _FilePreviewSurface({
    required this.attachment,
    this.unavailable = false,
  });

  final Attachment attachment;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _fileColor(context, attachment),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_fileIcon(attachment), size: 44),
              const SizedBox(height: 12),
              Text(
                attachment.originalFileName,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                unavailable
                    ? 'Preview unavailable'
                    : '${_typeLabel(attachment)} · ${formatAttachmentBytes(attachment.byteSize)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openLocalAttachment(
  BuildContext context,
  String path,
  String mimeType,
) async {
  final file = File(path);
  if (!await file.exists()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This local file is unavailable.')),
      );
    }
    return;
  }
  var opened = false;
  try {
    opened = await openAttachmentPath(path, mimeType);
  } on PlatformException {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this attachment.')),
    );
  }
}

@visibleForTesting
Future<bool> openAttachmentPath(
  String path,
  String mimeType, {
  bool? useAndroidChannel,
}) async {
  if (useAndroidChannel ?? Platform.isAndroid) {
    return await const MethodChannel('laterbox/file_open').invokeMethod<bool>(
          'openFile',
          {'path': path, 'mimeType': mimeType},
        ) ??
        false;
  }
  return launchUrl(Uri.file(path), mode: LaunchMode.externalApplication);
}

String formatAttachmentBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kilobytes = bytes / 1024;
  if (kilobytes < 1024) return '${kilobytes.toStringAsFixed(1)} KB';
  final megabytes = kilobytes / 1024;
  return '${megabytes.toStringAsFixed(1)} MB';
}

String _semanticLabel(Attachment attachment, int count) {
  final suffix = count == 1 ? '' : ', $count attachments total';
  return '${attachment.originalFileName}, ${_typeLabel(attachment)}$suffix';
}

String _typeLabel(Attachment attachment) => switch (attachment.fileExtension) {
  'jpg' || 'jpeg' => 'JPEG image',
  'png' => 'PNG image',
  'webp' => 'WebP image',
  'heic' => 'HEIC image',
  'pdf' => 'PDF document',
  'txt' => 'Text document',
  'md' => 'Markdown document',
  'doc' => 'Word document',
  'docx' => 'Word document',
  _ => attachment.fileExtension.toUpperCase(),
};

IconData _fileIcon(Attachment attachment) => switch (attachment.fileExtension) {
  'pdf' => Icons.picture_as_pdf_rounded,
  'txt' || 'md' => Icons.notes_rounded,
  'doc' || 'docx' => Icons.description_rounded,
  'jpg' || 'jpeg' || 'png' || 'webp' || 'heic' => Icons.image_rounded,
  _ => Icons.insert_drive_file_rounded,
};

Color _fileColor(BuildContext context, Attachment attachment) {
  final colors = Theme.of(context).colorScheme;
  return switch (attachment.fileExtension) {
    'pdf' => colors.errorContainer,
    'doc' || 'docx' => colors.primaryContainer,
    'txt' || 'md' => colors.tertiaryContainer,
    _ => colors.surfaceContainerHighest,
  };
}

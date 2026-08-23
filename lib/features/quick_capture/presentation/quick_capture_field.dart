import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../attachments/data/attachment_file_picker.dart';

/// The quick capture input. Keyboard shortcuts (`⌘↵` / `Esc`) are handled by
/// [QuickCaptureScreen] around this widget so they work regardless of focus.
class QuickCaptureField extends StatefulWidget {
  const QuickCaptureField({
    super.key,
    required this.controller,
    required this.sourceLabel,
    required this.selectedFiles,
    required this.onChanged,
    required this.onSave,
    required this.onPickAttachments,
    required this.onRemoveAttachment,
    this.isSaving = false,
  });

  final TextEditingController controller;

  /// Frontmost app at capture time, shown when content came from a selection.
  final String? sourceLabel;

  final List<PickedAttachmentFile> selectedFiles;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;
  final VoidCallback onPickAttachments;
  final ValueChanged<int> onRemoveAttachment;
  final bool isSaving;

  @override
  State<QuickCaptureField> createState() => _QuickCaptureFieldState();
}

class _QuickCaptureFieldState extends State<QuickCaptureField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _handleTextChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;

    final current = widget.controller.text;
    final selection = widget.controller.selection;

    if (selection.isValid && selection.start >= 0 && selection.end >= 0) {
      final newText = current.replaceRange(selection.start, selection.end, text);
      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start + text.length),
      );
    } else {
      widget.controller.text = current.isEmpty ? text : '$current\n$text';
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
    }
    widget.onChanged(widget.controller.text);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'svg'].contains(ext)) {
      return Icons.image_rounded;
    }
    if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
      return Icons.video_file_rounded;
    }
    if (['mp3', 'm4a', 'wav', 'aac', 'flac'].contains(ext)) {
      return Icons.audio_file_rounded;
    }
    if (['pdf'].contains(ext)) {
      return Icons.picture_as_pdf_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceLabel = widget.sourceLabel;
    final hasText = widget.controller.text.isNotEmpty;
    final hasFiles = widget.selectedFiles.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Bar
              Row(
                children: [
                  Icon(
                    Icons.quickreply_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'laterbox quick capture',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Paste Button
                  IconButton(
                    onPressed: _pasteFromClipboard,
                    tooltip: 'Paste from clipboard',
                    icon: const Icon(Icons.content_paste_rounded, size: 16),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  // Attach Files Button
                  IconButton(
                    onPressed: widget.onPickAttachments,
                    tooltip: 'Attach images, PDFs or documents',
                    icon: const Icon(Icons.attach_file_rounded, size: 16),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(6),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    defaultTargetPlatform == TargetPlatform.windows
                        ? 'Ctrl+Enter'
                        : '⌘↵',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: (hasText || hasFiles) && !widget.isSaving
                        ? widget.onSave
                        : null,
                    icon: widget.isSaving
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 14),
                    label: Text(widget.isSaving ? 'Saving…' : 'Save'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ],
              ),

              if (sourceLabel != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 13,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Selected from $sourceLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Main Text Input with clear button
              Stack(
                alignment: Alignment.topRight,
                children: [
                  TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    minLines: 2,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      hintText: 'Paste a link, note, or attach files…',
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.fromLTRB(
                        12,
                        10,
                        hasText ? 36 : 12,
                        10,
                      ),
                    ),
                    onChanged: widget.onChanged,
                  ),
                  if (hasText)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        onPressed: () {
                          widget.controller.clear();
                          widget.onChanged('');
                          _focusNode.requestFocus();
                        },
                        tooltip: 'Clear text',
                        icon: const Icon(Icons.close_rounded, size: 16),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                ],
              ),

              // Selected Attachment Chips (scrollable if many)
              if (widget.selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 72),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (var i = 0; i < widget.selectedFiles.length; i++)
                          _AttachmentChip(
                            file: widget.selectedFiles[i],
                            icon: _getFileIcon(widget.selectedFiles[i].name),
                            formattedSize: _formatFileSize(widget.selectedFiles[i].size),
                            onDelete: () => widget.onRemoveAttachment(i),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.file,
    required this.icon,
    required this.formattedSize,
    required this.onDelete,
  });

  final PickedAttachmentFile file;
  final IconData icon;
  final String formattedSize;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($formattedSize)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onDelete,
            borderRadius: BorderRadius.circular(4),
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

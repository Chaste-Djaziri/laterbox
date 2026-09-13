import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attachments/data/attachment_file_picker.dart';
import '../../attachments/domain/attachment_import_result.dart';
import '../../attachments/presentation/attachment_providers.dart';
import '../domain/capture_payload.dart';
import '../domain/capture_providers.dart';

class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  final List<PickedAttachmentFile> _selectedFiles = [];
  List<AttachmentImportFailure> _fileFailures = const [];
  bool _saving = false;

  late final AnimationController _sendAnimController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _sendAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.42),
    ).animate(
      CurvedAnimation(
        parent: _sendAnimController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _sendAnimController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(
      CurvedAnimation(
        parent: _sendAnimController,
        curve: Curves.easeInOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _sendAnimController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _chooseFiles() async {
    final platform = Theme.of(context).platform;
    final isMobile = !kIsWeb &&
        (platform == TargetPlatform.iOS || platform == TargetPlatform.android);

    final AttachmentPickerSource? source;
    if (isMobile) {
      source = await showModalBottomSheet<AttachmentPickerSource>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose attachment source',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.folder_open_rounded,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: const Text(
                      'Files',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle:
                        const Text('Browse PDFs, documents, archives & files'),
                    onTap: () => Navigator.of(context)
                        .pop(AttachmentPickerSource.files),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.photo_library_rounded,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: const Text(
                      'Photo & Video Gallery',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle:
                        const Text('Pick photos and videos from your gallery'),
                    onTap: () => Navigator.of(context)
                        .pop(AttachmentPickerSource.gallery),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      source = AttachmentPickerSource.files;
    }

    if (source == null || !mounted) return;

    try {
      final files = await ref
          .read(attachmentFilePickerProvider)
          .pickFiles(source: source);
      if (!mounted || files.isEmpty) return;
      setState(() {
        for (final file in files) {
          final duplicate = _selectedFiles.any(
            (selected) =>
                selected.name == file.name && selected.size == file.size,
          );
          if (!duplicate) _selectedFiles.add(file);
        }
        _fileFailures = const [];
        _error = null;
      });
    } catch (error, stackTrace) {
      debugPrint('[LaterBox Attachments] file picker failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) setState(() => _error = 'Could not open the file picker.');
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.trim().isNotEmpty) {
      final current = _controller.text;
      if (current.isEmpty) {
        _controller.text = text.trim();
      } else {
        _controller.text = '$current\n${text.trim()}';
      }
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      setState(() => _error = null);
    }
  }

  bool _isImageFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return const {'png', 'jpg', 'jpeg', 'gif', 'webp', 'heic', 'svg'}.contains(ext);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    // Validate empty input upfront if no files are selected
    if (_selectedFiles.isEmpty) {
      try {
        CapturePayload.fromValue(
          _controller.text,
          source: CaptureSource.manual,
        );
      } on FormatException catch (error) {
        setState(() {
          _saving = false;
          _error = error.message;
        });
        return;
      }
    }

    // Trigger smooth outgoing chat animation
    final animFuture = _sendAnimController.forward();

    var popped = false;
    try {
      if (_selectedFiles.isNotEmpty) {
        final result = kIsWeb
            ? await ref
                  .read(webAttachmentImportServiceProvider)
                  .importFiles(files: _selectedFiles, text: _controller.text)
            : await (await ref.read(attachmentImportServiceProvider.future))
                  .importFiles(
                    sourcePaths: _selectedFiles
                        .map((file) => file.path)
                        .whereType<String>()
                        .toList(),
                    text: _controller.text,
                  );
        if (!mounted) return;
        if (!result.saved) {
          _sendAnimController.reverse();
          setState(() {
            _fileFailures = result.failures;
            _saving = false;
          });
          return;
        }

        await animFuture;
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        popped = true;
        Navigator.of(context).pop();
        if (result.failures.isNotEmpty) {
          messenger.showSnackBar(
            SnackBar(content: Text(_partialSuccessMessage(result))),
          );
        }
        return;
      }

      await ref
          .read(captureServiceProvider)
          .save(
            CapturePayload.fromValue(
              _controller.text,
              source: CaptureSource.manual,
            ),
          );

      await animFuture;
      if (mounted) {
        popped = true;
        Navigator.of(context).pop();
      }
    } on FormatException catch (error) {
      _sendAnimController.reverse();
      setState(() => _error = error.message);
    } catch (_) {
      _sendAnimController.reverse();
      setState(() => _error = 'Could not save this item. Try again.');
    } finally {
      if (mounted && !popped) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => Navigator.of(context).pop(),
          ),
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 20 + keyboardHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(top: 4, bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),

              // Header bar
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.all_inbox_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Save to laterbox',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Notes, web links, or attachments',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Chat-Style Composer with fly-away send animation
              SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _error != null
                              ? theme.colorScheme.error
                              : theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.7),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Text input
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              enabled: !_saving,
                              minLines: 3,
                              maxLines: 7,
                              textInputAction: TextInputAction.newline,
                              keyboardType: TextInputType.multiline,
                              autocorrect: true,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                height: 1.45,
                              ),
                              decoration: InputDecoration.collapsed(
                                hintText:
                                    'Write a note, paste a link, or attach files...',
                                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.65),
                                  fontSize: 15,
                                ),
                              ),
                              onSubmitted: _saving ? null : (_) => _save(),
                            ),
                          ),

                          // Selected files preview chips
                          if (_selectedFiles.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _selectedFiles.map((file) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _isImageFile(file.name)
                                              ? Icons.image_outlined
                                              : Icons.insert_drive_file_outlined,
                                          size: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 160,
                                          ),
                                          child: Text(
                                            file.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: _saving
                                              ? null
                                              : () => setState(() {
                                                    _selectedFiles.remove(file);
                                                    _fileFailures = const [];
                                                  }),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          child: Icon(
                                            Icons.close_rounded,
                                            size: 14,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],

                          // Subtle divider between message input and composer controls
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.35),
                          ),

                          // Composer action bar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                            child: Row(
                              children: [
                                // Choose files button (keeps 'Choose files' text for tests)
                                TextButton.icon(
                                  onPressed: _saving ? null : _chooseFiles,
                                  icon: const Icon(
                                    Icons.attach_file_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Choose files'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor:
                                        theme.colorScheme.onSurfaceVariant,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),

                                // Clipboard paste shortcut
                                IconButton(
                                  onPressed:
                                      _saving ? null : _pasteFromClipboard,
                                  tooltip: 'Paste from clipboard',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.content_paste_rounded,
                                    size: 18,
                                  ),
                                ),

                                const Spacer(),

                                // Chat-style Save send button
                                FilledButton(
                                  onPressed: _saving ? null : _save,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _saving
                                      ? const SizedBox.square(
                                          dimension: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Save',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13.5,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.arrow_upward_rounded,
                                              size: 16,
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
              ),

              // Error banner
              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Attachment failures list if any
              if (_fileFailures.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        theme.colorScheme.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Couldn’t add:',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ..._fileFailures.map(
                        (failure) => Text(
                          '• ${failure.displayName} — ${_failureReason(failure.code)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _partialSuccessMessage(AttachmentImportResult result) {
    final lines = <String>[
      'Saved ${result.attachmentIds.length} '
          '${result.attachmentIds.length == 1 ? 'file' : 'files'}',
      '',
      'Couldn’t add:',
      ...result.failures.map(
        (failure) =>
            '• ${failure.displayName} — ${_failureReason(failure.code)}',
      ),
    ];
    return lines.join('\n');
  }

  String _failureReason(AttachmentImportFailureCode code) => switch (code) {
    AttachmentImportFailureCode.unsupportedType => 'unsupported file type',
    AttachmentImportFailureCode.tooLarge =>
      'files larger than 100 MB aren’t supported yet',
    AttachmentImportFailureCode.emptyFile => 'the file is empty',
    AttachmentImportFailureCode.unreadable => 'the file could not be read',
    AttachmentImportFailureCode.mimeMismatch =>
      'the file contents do not match its type',
    AttachmentImportFailureCode.sourceChanged =>
      'the file changed while it was being copied',
    AttachmentImportFailureCode.copyFailed => 'the file could not be copied',
    AttachmentImportFailureCode.verificationFailed =>
      'the copied file could not be verified',
    AttachmentImportFailureCode.databaseFailed =>
      'the attachment could not be saved',
  };
}

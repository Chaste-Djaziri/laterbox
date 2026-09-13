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
      duration: const Duration(milliseconds: 320),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.65),
    ).animate(
      CurvedAnimation(
        parent: _sendAnimController,
        curve: Curves.easeOutCubic,
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
      end: 0.90,
    ).animate(
      CurvedAnimation(
        parent: _sendAnimController,
        curve: Curves.easeOutCubic,
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

  Future<void> _chooseFiles({AttachmentPickerSource? initialSource}) async {
    final platform = Theme.of(context).platform;
    final isMobile = !kIsWeb &&
        (platform == TargetPlatform.iOS || platform == TargetPlatform.android);

    final AttachmentPickerSource? source;
    if (initialSource != null) {
      source = initialSource;
    } else if (isMobile) {
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
    final isDark = theme.brightness == Brightness.dark;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    final pillBgColor = isDark
        ? const Color(0xFF26262B)
        : const Color(0xFFF2F3F6);
    final sendBtnBgColor = isDark
        ? Colors.white
        : const Color(0xFF0F172A);
    final sendIconColor = isDark
        ? const Color(0xFF0F172A)
        : Colors.white;

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
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.translucent,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {}, // Prevent taps inside the bar from dismissing
              behavior: HitTestBehavior.opaque,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + keyboardHeight),
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Attached files preview row (above pill)
                            if (_selectedFiles.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: _selectedFiles.map((file) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF333338)
                                              : Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.12),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _isImageFile(file.name)
                                                  ? Icons.image_rounded
                                                  : Icons.insert_drive_file_rounded,
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
                                                style: theme
                                                    .textTheme.labelMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: _saving
                                                  ? null
                                                  : () => setState(() {
                                                        _selectedFiles
                                                            .remove(file);
                                                        _fileFailures =
                                                            const [];
                                                      }),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: 15,
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
                              ),
                            ],

                            // Error banner (above pill)
                            if (_error != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        size: 16,
                                        color: theme.colorScheme.error,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          _error!,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onErrorContainer,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // Attachment failures list if any
                            if (_fileFailures.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Couldn’t add:',
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.error,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      ..._fileFailures.map(
                                        (failure) => Text(
                                          '• ${failure.displayName} — ${_failureReason(failure.code)}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onErrorContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            // The Chat Input Bar + Circular Send Button (Exact Image 1 layout)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Pill input bar
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: pillBgColor,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.12),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Plus (+) Button to attach files/images
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _saving
                                                ? null
                                                : () => _chooseFiles(),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            child: Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.add_rounded,
                                                    size: 26,
                                                    color: isDark
                                                        ? Colors.grey.shade400
                                                        : Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(
                                                    width: 32,
                                                    height: 32,
                                                    child: Center(
                                                      child: Text(
                                                        'Choose files',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.transparent,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Text Field
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 4,
                                              right: 12,
                                              top: 2,
                                              bottom: 2,
                                            ),
                                            child: TextField(
                                              controller: _controller,
                                              focusNode: _focusNode,
                                              enabled: !_saving,
                                              minLines: 1,
                                              maxLines: 5,
                                              keyboardType:
                                                  TextInputType.multiline,
                                              textInputAction:
                                                  TextInputAction.newline,
                                              style: TextStyle(
                                                fontSize: 16,
                                                height: 1.35,
                                                color: isDark
                                                    ? Colors.white
                                                    : const Color(0xFF0F172A),
                                              ),
                                              decoration:
                                                  InputDecoration.collapsed(
                                                hintText:
                                                    'Type your message...',
                                                hintStyle: TextStyle(
                                                  color: isDark
                                                      ? Colors.grey.shade500
                                                      : Colors.grey.shade500,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              onSubmitted: _saving
                                                  ? null
                                                  : (_) => _save(),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                // Circular Send Button ("send being save")
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _saving ? null : _save,
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: sendBtnBgColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.16),
                                            blurRadius: 12,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _saving
                                            ? SizedBox.square(
                                                dimension: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: sendIconColor,
                                                ),
                                              )
                                            : Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Transform.rotate(
                                                    angle: -0.2,
                                                    child: Icon(
                                                      Icons.send_rounded,
                                                      color: sendIconColor,
                                                      size: 22,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                    width: 48,
                                                    height: 48,
                                                    child: Center(
                                                      child: Text(
                                                        'Save',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.transparent,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

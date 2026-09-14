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

  String? _sentMessageText;
  List<PickedAttachmentFile> _sentFiles = const [];

  late final AnimationController _sendAnimController;
  late final Animation<Offset> _inputSlideAnimation;
  late final Animation<double> _inputFadeAnimation;
  late final Animation<double> _bubbleFadeAnimation;
  late final Animation<double> _bubbleScaleAnimation;
  late final Animation<Offset> _bubbleSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _sendAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    // Input Bar animations: quickly slide down and fade away (0% - 22% of duration)
    _inputFadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 78,
      ),
    ]).animate(_sendAnimController);

    _inputSlideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.0, 0.35),
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 22,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(0.0, 0.35)),
        weight: 78,
      ),
    ]).animate(_sendAnimController);

    // Sent Chat Bubble animations on dimmed overlay:
    // 1. Pop into view on the dimmed overlay with spring (12% - 44% of duration)
    // 2. Rest prominently on the empty dimmed overlay (44% - 72% of duration)
    // 3. Float up and dissolve as overlay closes (72% - 100% of duration)
    _bubbleFadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 28,
      ),
    ]).animate(_sendAnimController);

    _bubbleScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: ConstantTween<double>(0.65),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.65, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 56,
      ),
    ]).animate(_sendAnimController);

    _bubbleSlideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: ConstantTween<Offset>(const Offset(0.05, 0.40)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: const Offset(0.05, 0.40),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 32,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.0, -0.28),
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 28,
      ),
    ]).animate(_sendAnimController);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
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

  bool _isMoreThanTwoLines(String text, double availableWidth) {
    if ('\n'.allMatches(text).length >= 2) return true;
    if (text.length < 30) return false;

    final span = TextSpan(
      text: text,
      style: const TextStyle(fontSize: 16, height: 1.35),
    );
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      maxLines: 10,
    );
    tp.layout(maxWidth: availableWidth > 50 ? availableWidth : 260);
    final isMore = tp.computeLineMetrics().length > 2;
    tp.dispose();
    return isMore;
  }

  Widget _buildPlusButton(bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving ? null : () => _chooseFiles(),
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 26,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
    );
  }

  Widget _buildTextField(bool isDark) {
    return TextField(
      key: const ValueKey('chat_capture_text_field'),
      controller: _controller,
      focusNode: _focusNode,
      enabled: !_saving,
      minLines: 1,
      maxLines: 6,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: TextStyle(
        fontSize: 16,
        height: 1.35,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 0,
        ),
        hintText: 'Type your message...',
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      onSubmitted: _saving ? null : (_) => _save(),
    );
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

    // Capture sent payload for the overlay chat bubble animation
    setState(() {
      _sentMessageText = _controller.text;
      _sentFiles = List.of(_selectedFiles);
    });

    // Dismiss keyboard so full dimmed overlay is visible
    _focusNode.unfocus();

    // Trigger smooth outgoing chat animation on dimmed overlay
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
            _sentMessageText = null;
            _sentFiles = const [];
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
      setState(() {
        _sentMessageText = null;
        _sentFiles = const [];
        _error = error.message;
      });
    } catch (_) {
      _sendAnimController.reverse();
      setState(() {
        _sentMessageText = null;
        _sentFiles = const [];
        _error = 'Could not save this item. Try again.';
      });
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
    // Green-themed like the app (uses the app's signature green primaryContainer and onPrimaryContainer)
    final sendBtnBgColor = theme.colorScheme.primaryContainer;
    final sendIconColor = theme.colorScheme.onPrimaryContainer;

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
          onTap: _saving ? null : () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // 1. Sent message chat bubble on the empty dimmed overlay
              if (_sentMessageText != null || _sentFiles.isNotEmpty)
                Positioned.fill(
                  child: IgnorePointer(
                    child: SafeArea(
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 0, 16, 76),
                          child: SlideTransition(
                            position: _bubbleSlideAnimation,
                            child: FadeTransition(
                              opacity: _bubbleFadeAnimation,
                              child: ScaleTransition(
                                scale: _bubbleScaleAnimation,
                                child: _buildSentMessageBubble(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. Input pill composer (slides down and fades out on send)
              Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {}, // Prevent taps inside the bar from dismissing
                  behavior: HitTestBehavior.opaque,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(16, 8, 16, 16 + keyboardHeight),
                      child: SlideTransition(
                        position: _inputSlideAnimation,
                        child: FadeTransition(
                          opacity: _inputFadeAnimation,
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

                            // The Chat Input Bar + Circular Send Button (Image 1 layout)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final availableWidth =
                                    constraints.maxWidth - 48 - 10 - 28;
                                final isMoreThanTwoLines = _isMoreThanTwoLines(
                                  _controller.text,
                                  availableWidth > 50 ? availableWidth : 260,
                                );
                                final pillBorderRadius =
                                    isMoreThanTwoLines ? 20.0 : 999.0;
                                final pillMinHeight =
                                    isMoreThanTwoLines ? 96.0 : 48.0;
                                final pillMaxHeight =
                                    isMoreThanTwoLines ? 160.0 : 64.0;

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Pill input bar
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeOutCubic,
                                        clipBehavior: Clip.antiAlias,
                                        constraints: BoxConstraints(
                                          minHeight: pillMinHeight,
                                          maxHeight: pillMaxHeight,
                                        ),
                                        decoration: BoxDecoration(
                                          color: pillBgColor,
                                          borderRadius: BorderRadius.circular(
                                              pillBorderRadius),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.12),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.topLeft,
                                          children: [
                                            // Text field: permanently mounted in the same slot to preserve IME connection & continuous typing
                                            AnimatedPadding(
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              curve: Curves.easeOutCubic,
                                              padding: isMoreThanTwoLines
                                                  ? const EdgeInsets.fromLTRB(
                                                      14, 10, 14, 42)
                                                  : const EdgeInsets.fromLTRB(
                                                      44, 6, 12, 6),
                                              child: _buildTextField(isDark),
                                            ),

                                            // Plus button: smoothly glides between center-left and bottom-left
                                            Positioned.fill(
                                              child: AnimatedAlign(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                curve: Curves.easeOutCubic,
                                                alignment: isMoreThanTwoLines
                                                    ? Alignment.bottomLeft
                                                    : Alignment.centerLeft,
                                                child: Padding(
                                                  padding: isMoreThanTwoLines
                                                      ? const EdgeInsets.only(
                                                          left: 4, bottom: 4)
                                                      : const EdgeInsets.only(
                                                          left: 4),
                                                  child:
                                                      _buildPlusButton(isDark),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    // Circular Send Button ("send being save", green-themed like app)
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _saving ? null : _save,
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: sendBtnBgColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.14),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: _saving
                                                ? SizedBox.square(
                                                    dimension: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: sendIconColor,
                                                    ),
                                                  )
                                                : Stack(
                                                    alignment:
                                                        Alignment.center,
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
                                                              color: Colors
                                                                  .transparent,
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
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildSentMessageBubble() {
    final message = _sentMessageText ?? '';
    final hasFiles = _sentFiles.isNotEmpty;
    final hasText = message.trim().isNotEmpty;

    return Semantics(
      label: 'Sent message',
      child: KeyedSubtree(
        key: const ValueKey('sent_chat_bubble'),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
            minWidth: 72,
          ),
          child: CustomPaint(
            painter: const SentChatBubblePainter(
              color: Color(0xFF34C759), // Iconic iMessage / app vibrant green
            ),
            child: ClipPath(
              clipper: const SentChatBubbleClipper(),
              child: Container(
                color: const Color(0xFF34C759),
                padding: const EdgeInsets.fromLTRB(16, 11, 23, 11),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasFiles) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _sentFiles.map((f) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isImageFile(f.name)
                                      ? Icons.image_rounded
                                      : Icons.insert_drive_file_rounded,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 130),
                                  child: Text(
                                    f.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      if (hasText) const SizedBox(height: 6),
                    ],
                    if (hasText)
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
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

/// Outgoing iMessage-style speech bubble with bottom-right tail
class SentChatBubbleClipper extends CustomClipper<Path> {
  const SentChatBubbleClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    const r = 18.0;
    const tailWidth = 7.0;
    final w = size.width;
    final h = size.height;

    // Start at top-left
    path.moveTo(r, 0);
    // Top line
    path.lineTo(w - tailWidth - r, 0);
    // Top-right corner
    path.arcToPoint(
      Offset(w - tailWidth, r),
      radius: const Radius.circular(r),
    );
    // Right line down towards tail
    path.lineTo(w - tailWidth, h - 14);
    // Outer curve sweeping to the tail tip
    path.quadraticBezierTo(w - 1, h - 3, w, h);
    // Bottom curve sweeping from tail tip back to bottom line
    path.quadraticBezierTo(w - 7, h, w - tailWidth - 14, h);
    // Bottom line
    path.lineTo(r, h);
    // Bottom-left corner
    path.arcToPoint(
      Offset(0, h - r),
      radius: const Radius.circular(r),
    );
    // Left line
    path.lineTo(0, r);
    // Top-left corner
    path.arcToPoint(
      const Offset(r, 0),
      radius: const Radius.circular(r),
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class SentChatBubblePainter extends CustomPainter {
  final Color color;
  const SentChatBubblePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const clipper = SentChatBubbleClipper();
    final path = clipper.getClip(size);
    // Subtle drop shadow for depth on dimmed overlay
    canvas.drawShadow(
      path,
      Colors.black.withValues(alpha: 0.32),
      8,
      false,
    );
    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SentChatBubblePainter oldDelegate) =>
      color != oldDelegate.color;
}

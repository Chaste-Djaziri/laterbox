import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/desktop/desktop_actions.dart';
import '../../../core/desktop/desktop_providers.dart';
import '../../../core/desktop/quick_capture_controller.dart';
import '../../attachments/data/attachment_file_picker.dart';
import '../../attachments/presentation/attachment_providers.dart';
import '../../attachments/domain/web_attachment_import_service.dart';
import 'quick_capture_field.dart';
import 'quick_capture_success.dart';

/// Full-window widget shown while quick capture is active.
///
/// Owns the text controller so the Save button and platform submit shortcuts
/// call exactly one path that reads the actual current field value.
class QuickCaptureScreen extends ConsumerStatefulWidget {
  const QuickCaptureScreen({super.key});

  @override
  ConsumerState<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends ConsumerState<QuickCaptureScreen> {
  final _textController = TextEditingController();
  final List<PickedAttachmentFile> _selectedFiles = [];
  bool _didInitializePrefill = false;
  bool _isSavingAttachments = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    ref.read(quickCaptureControllerProvider).updateDraft(_textController.text);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInitializePrefill) {
      _didInitializePrefill = true;
      final prefill = ref.read(quickCaptureControllerProvider).prefillText;
      if (prefill != null && prefill.isNotEmpty && _textController.text.isEmpty) {
        _textController.text = prefill;
      }
    }
  }

  Future<void> _pickAttachments() async {
    try {
      final files = await ref
          .read(attachmentFilePickerProvider)
          .pickFiles(source: AttachmentPickerSource.files);
      if (!mounted || files.isEmpty) return;

      setState(() {
        for (final file in files) {
          final isDuplicate = _selectedFiles.any(
            (existing) =>
                existing.name == file.name && existing.size == file.size,
          );
          if (!isDuplicate) {
            _selectedFiles.add(file);
          }
        }
      });
    } catch (error, stackTrace) {
      debugPrint('[LaterBox QuickCapture] pick attachments failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _removeAttachment(int index) {
    if (index >= 0 && index < _selectedFiles.length) {
      setState(() {
        _selectedFiles.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    final value = _textController.text.trim();
    final hasFiles = _selectedFiles.isNotEmpty;

    debugPrint(
      '[LaterBox QuickCapture] submit: ${value.length} chars, ${_selectedFiles.length} files',
    );
    if (value.isEmpty && !hasFiles) {
      debugPrint('[LaterBox QuickCapture] submit ignored (empty)');
      return;
    }

    try {
      if (hasFiles) {
        setState(() => _isSavingAttachments = true);
        final result = kIsWeb
            ? await ref
                  .read(webAttachmentImportServiceProvider)
                  .importFiles(files: _selectedFiles, text: value)
            : await (await ref.read(attachmentImportServiceProvider.future))
                  .importFiles(
                    sourcePaths: _selectedFiles
                        .map((f) => f.path)
                        .whereType<String>()
                        .toList(),
                    text: value,
                  );
        if (!mounted) return;
        if (!result.saved) {
          debugPrint('[LaterBox QuickCapture] attachment import not saved: ${result.failures}');
          setState(() => _isSavingAttachments = false);
          return;
        }
        await ref.read(desktopActionsProvider).finishQuickCapture();
        return;
      }

      await ref.read(quickCaptureControllerProvider).saveValue(value);
      debugPrint('[LaterBox QuickCapture] saved');
      await ref.read(desktopActionsProvider).finishQuickCapture();
    } catch (error, stackTrace) {
      debugPrint('[LaterBox QuickCapture] SAVE FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() => _isSavingAttachments = false);
      }
    }
  }

  Future<void> _close() async {
    await ref.read(quickCaptureControllerProvider).close();
    await ref.read(desktopActionsProvider).finishQuickCapture();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(quickCaptureControllerProvider);
    final sourceApplication = controller.sourceApplication;
    final isSaving = controller.isSaving || _isSavingAttachments;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _submit,
        const SingleActivator(LogicalKeyboardKey.escape): _close,
      },
      child: Focus(
        autofocus: true,
        child: switch (controller.status) {
          QuickCaptureStatus.success => const QuickCaptureSuccess(),
          QuickCaptureStatus.active ||
          QuickCaptureStatus.saving => QuickCaptureField(
            controller: _textController,
            sourceLabel: sourceApplication,
            selectedFiles: _selectedFiles,
            onChanged: controller.updateDraft,
            onSave: _submit,
            onPickAttachments: _pickAttachments,
            onRemoveAttachment: _removeAttachment,
            isSaving: isSaving,
          ),
          QuickCaptureStatus.idle => const SizedBox.shrink(),
        },
      ),
    );
  }
}

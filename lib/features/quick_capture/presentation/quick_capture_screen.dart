import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/desktop/desktop_actions.dart';
import '../../../core/desktop/desktop_providers.dart';
import '../../../core/desktop/quick_capture_controller.dart';
import 'quick_capture_field.dart';
import 'quick_capture_success.dart';

/// Full-window widget shown while quick capture is active.
///
/// Owns the text controller so both the Save button and `⌘↵` call exactly one
/// submit path that reads the actual current field value.
class QuickCaptureScreen extends ConsumerStatefulWidget {
  const QuickCaptureScreen({super.key});

  @override
  ConsumerState<QuickCaptureScreen> createState() => _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends ConsumerState<QuickCaptureScreen> {
  final _textController = TextEditingController();
  bool _didInitializePrefill = false;

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
      if (prefill != null) {
        _textController.text = prefill;
      }
    }
  }

  Future<void> _submit() async {
    final value = _textController.text.trim();
    debugPrint('[LaterBox QuickCapture] submit: ${value.length} chars');
    if (value.isEmpty) {
      debugPrint('[LaterBox QuickCapture] submit ignored (empty)');
      return;
    }

    try {
      await ref.read(quickCaptureControllerProvider).saveValue(value);
      debugPrint('[LaterBox QuickCapture] saved');
      await ref.read(desktopActionsProvider).finishQuickCapture();
    } catch (error, stackTrace) {
      debugPrint('[LaterBox QuickCapture] SAVE FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): _submit,
        const SingleActivator(LogicalKeyboardKey.escape): _close,
      },
      child: Focus(
        autofocus: true,
        child: switch (controller.status) {
          QuickCaptureStatus.success => const QuickCaptureSuccess(),
          QuickCaptureStatus.active ||
          QuickCaptureStatus.saving =>
            QuickCaptureField(
              key: ValueKey(controller.prefillText),
              controller: _textController,
              sourceLabel: sourceApplication,
              onChanged: controller.updateDraft,
              onSave: _submit,
            ),
          QuickCaptureStatus.idle => const SizedBox.shrink(),
        },
      ),
    );
  }
}
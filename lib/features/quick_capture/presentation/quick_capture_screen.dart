import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/desktop/desktop_providers.dart';
import '../../../core/desktop/quick_capture_controller.dart';
import 'quick_capture_field.dart';
import 'quick_capture_success.dart';

/// Full-window widget shown while quick capture is active.
///
/// Owns the capture-wide keyboard shortcuts (`⌘↵` save, `Esc` close) so they
/// work no matter which control inside the window has focus.
class QuickCaptureScreen extends ConsumerWidget {
  const QuickCaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quickCaptureControllerProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
          debugPrint('[LaterBox Desktop] ⌘Enter');
          unawaited(controller.save());
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          debugPrint('[LaterBox Desktop] escape');
          unawaited(controller.close());
        },
      },
      child: Focus(
        autofocus: true,
        child: switch (controller.status) {
          QuickCaptureStatus.success => const QuickCaptureSuccess(),
          QuickCaptureStatus.active ||
          QuickCaptureStatus.saving =>
            QuickCaptureField(
              key: ValueKey(controller.prefillText),
              initialText: controller.prefillText,
              onChanged: controller.updateDraft,
              onSave: () => controller.save(),
            ),
          QuickCaptureStatus.idle => const SizedBox.shrink(),
        },
      ),
    );
  }
}
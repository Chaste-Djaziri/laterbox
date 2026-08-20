import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/desktop/desktop_providers.dart';
import '../../../core/desktop/quick_capture_controller.dart';
import 'quick_capture_field.dart';
import 'quick_capture_success.dart';

/// Full-window widget shown while quick capture is active.
///
/// The app router swaps to this widget when the capture controller is active,
/// so the native window is either the capture UI or the regular app.
class QuickCaptureScreen extends ConsumerWidget {
  const QuickCaptureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(quickCaptureControllerProvider);

    switch (controller.status) {
      case QuickCaptureStatus.success:
        return const QuickCaptureSuccess();
      case QuickCaptureStatus.active:
      case QuickCaptureStatus.saving:
        return QuickCaptureField(
          key: ValueKey(controller.prefillText),
          initialText: controller.prefillText,
          onChanged: controller.updateDraft,
          onSave: () => controller.save(),
          onCancel: () => controller.close(),
        );
      case QuickCaptureStatus.idle:
        return const SizedBox.shrink();
    }
  }
}
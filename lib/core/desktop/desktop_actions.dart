import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'desktop_providers.dart';

/// Single owner of every desktop action.
///
/// The global hotkey and the tray both call the same two methods here; no
/// other code decides what “quick capture” or “open laterbox” means.
/// Services only ever receive callbacks that lead back to this object.
class DesktopActions {
  DesktopActions(this.ref);

  final Ref ref;

  /// ⌥Space / tray “Quick Capture”: enter capture mode, then show the window.
  Future<void> openQuickCapture() async {
    debugPrint('[LaterBox Desktop] openQuickCapture requested');

    try {
      final controller = ref.read(quickCaptureControllerProvider);
      final desktop = ref.read(desktopServiceProvider);

      debugPrint('[LaterBox Desktop] entering quick capture mode');
      await controller.open();
      debugPrint('[LaterBox Desktop] controller opened');

      await desktop.showQuickCapture();
      debugPrint('[LaterBox Desktop] openQuickCapture complete');
    } catch (error, stackTrace) {
      debugPrint('[LaterBox Desktop] openQuickCapture FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Tray “Open LaterBox”: close any capture state and show the main window.
  Future<void> openLaterBox() async {
    debugPrint('[LaterBox Desktop] openLaterBox requested');

    try {
      final controller = ref.read(quickCaptureControllerProvider);
      final desktop = ref.read(desktopServiceProvider);

      await controller.close();
      await desktop.showMainWindow();
      debugPrint('[LaterBox Desktop] openLaterBox complete');
    } catch (error, stackTrace) {
      debugPrint('[LaterBox Desktop] openLaterBox FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

final desktopActionsProvider = Provider<DesktopActions>((ref) {
  return DesktopActions(ref);
});
import 'desktop_capabilities.dart';

/// No-op desktop service for web and mobile.
///
/// Mirrors the call surface of `DesktopService` (io) so shared code can
/// compile on every platform.
class DesktopService {
  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  Future<bool> initialize({
    required void Function() onQuickCapture,
    required void Function() onOpenLaterBox,
  }) async {
    return false;
  }

  Future<bool> registerQuickCaptureHotkey({
    required void Function() onTriggered,
  }) async {
    return false;
  }

  Future<void> unregisterQuickCaptureHotkey() async {}

  Future<void> showQuickCaptureWindow() async {}

  Future<void> restoreMainWindow() async {}

  Future<void> showMainWindow() async {}

  Future<void> hideMainWindow() async {}

  Future<void> quit() async {}

  void addWindowBlurListener(void Function() onBlur) {}

  void addWindowCloseListener(void Function() onClose) {}

  Future<void> dispose() async {}
}

/// Whether this platform has a working native desktop service.
bool get desktopServiceAvailable => isDesktopSupported;
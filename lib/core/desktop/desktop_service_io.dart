import 'dart:ui';

import 'package:window_manager/window_manager.dart';

import 'desktop_capabilities.dart';
import 'global_hotkey_service_io.dart';
import 'tray_service_io.dart';

const captureWindowSize = Size(600, 240);
const captureWindowMinimumSize = Size(400, 160);
const defaultMainWindowSize = Size(1100, 720);
const defaultMainWindowMinimumSize = Size(480, 400);

/// Native desktop integration: window control, the global quick capture
/// hotkey and the menu-bar tray.
///
/// Only compiled on platforms with `dart.library.io`.
class DesktopService {
  static bool _initialized = false;

  final GlobalHotkeyService _hotkeyService = GlobalHotkeyService();
  final TrayService _trayService = TrayService();
  final _WindowListenerImpl _listener = _WindowListenerImpl();

  Size? _defaultWindowSize;
  bool _inCaptureMode = false;

  /// Must be called once before `runApp` on desktop platforms.
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    await windowManager.ensureInitialized();
    _initialized = true;
  }

  bool get isInitialized => _initialized;

  bool get isCaptureMode => _inCaptureMode;

  Future<bool> initialize({
    required void Function() onQuickCapture,
    required void Function() onOpenLaterBox,
  }) async {
    windowManager.addListener(_listener);

    _defaultWindowSize = await _readDefaultWindowSize();
    await windowManager.setMinimumSize(defaultMainWindowMinimumSize);
    await windowManager.setPreventClose(true);

    final hotkeyRegistered =
        await registerQuickCaptureHotkey(onTriggered: onQuickCapture);
    await _trayService.init(
      onQuickCapture: onQuickCapture,
      onOpenLaterBox: onOpenLaterBox,
      onQuit: quit,
    );
    return hotkeyRegistered;
  }

  Future<Size?> _readDefaultWindowSize() async {
    try {
      final size = await windowManager.getSize();
      if (size.width > 0 && size.height > 0) return size;
    } on Exception {
      return null;
    }
    return null;
  }

  Future<bool> registerQuickCaptureHotkey({
    required void Function() onTriggered,
  }) {
    return _hotkeyService.register(onTriggered: onTriggered);
  }

  Future<void> unregisterQuickCaptureHotkey() {
    return _hotkeyService.unregister();
  }

  /// Switches the window into quick capture mode and shows it.
  Future<void> showQuickCaptureWindow() async {
    _inCaptureMode = true;
    await windowManager.setSize(captureWindowSize);
    await windowManager.setMinimumSize(captureWindowMinimumSize);
    await windowManager.setAlwaysOnTop(true);
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
  }

  /// Restores the regular app window and shows it.
  Future<void> restoreMainWindow() async {
    _inCaptureMode = false;
    await windowManager.setAlwaysOnTop(false);
    await windowManager.setMinimumSize(defaultMainWindowMinimumSize);
    final size = _defaultWindowSize ?? defaultMainWindowSize;
    await windowManager.setSize(size);
    await windowManager.center();
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> showMainWindow() async {
    if (_inCaptureMode) {
      await restoreMainWindow();
      return;
    }
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hideMainWindow() async {
    await windowManager.hide();
  }

  Future<void> quit() async {
    await _hotkeyService.unregisterAll();
    await _trayService.destroy();
    windowManager.removeListener(_listener);
    await windowManager.destroy();
  }

  void addWindowBlurListener(void Function() onBlur) {
    _listener.onBlurListeners.add(onBlur);
  }

  void addWindowCloseListener(void Function() onClose) {
    _listener.onCloseListeners.add(onClose);
  }

  Future<void> dispose() async {
    windowManager.removeListener(_listener);
    await _hotkeyService.unregisterAll();
    await _trayService.destroy();
  }
}

class _WindowListenerImpl extends WindowListener {
  final List<void Function()> onBlurListeners = [];
  final List<void Function()> onCloseListeners = [];

  @override
  void onWindowBlur() {
    for (final listener in onBlurListeners) {
      listener();
    }
  }

  @override
  void onWindowClose() {
    for (final listener in onCloseListeners) {
      listener();
    }
  }
}

/// Whether this platform has a working native desktop service.
bool get desktopServiceAvailable => isDesktopSupported;
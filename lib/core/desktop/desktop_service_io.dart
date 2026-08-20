import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop_capabilities.dart';
import 'global_hotkey_service_io.dart';
import 'tray_service_io.dart';

const captureWindowSize = Size(620, 240);
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
  ///
  /// Initializes the native window API and clears any stale hotkeys left over
  /// from previous `flutter run` / hot-restart sessions.
  static Future<void> ensureInitialized() async {
    if (!Platform.isMacOS && !Platform.isWindows && !Platform.isLinux) {
      return;
    }
    debugPrint('[LaterBox Desktop] initialization starting');
    if (_initialized) return;
    await windowManager.ensureInitialized();
    await hotKeyManager.unregisterAll();
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

  /// Switches the window into quick capture mode and shows it on top.
  ///
  /// The controller must enter capture mode *before* this is called so the
  /// first visible frame is already the quick capture UI.
  Future<void> showQuickCapture() async {
    debugPrint('[LaterBox Desktop] showing quick capture');
    _inCaptureMode = true;

    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.setSize(captureWindowSize, animate: false);
    await windowManager.setMinimumSize(captureWindowMinimumSize);
    await windowManager.center();
    // Temporarily float above Safari/Finder/other apps.
    await windowManager.setAlwaysOnTop(true);
    await windowManager.show();
    await windowManager.focus();

    debugPrint('[LaterBox Desktop] quick capture window shown');
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
    debugPrint('[LaterBox Desktop] window blur');
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
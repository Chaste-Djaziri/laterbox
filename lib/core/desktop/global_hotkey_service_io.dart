import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// System-wide quick capture hotkey: `Option/Alt + Space`.
final quickCaptureHotKey = HotKey(
  key: LogicalKeyboardKey.space,
  modifiers: [HotKeyModifier.alt],
);

/// Registers the system-wide quick capture hotkey using `hotkey_manager`.
class GlobalHotkeyService {
  HotKey? _registered;

  /// Registers [quickCaptureHotKey]. Returns `true` when the hotkey was
  /// successfully registered, `false` when it could not be taken (for example
  /// because another application already uses it).
  Future<bool> register({required void Function() onTriggered}) async {
    await unregister();
    try {
      await hotKeyManager.register(
        quickCaptureHotKey,
        keyDownHandler: (_) => onTriggered(),
      );
      _registered = quickCaptureHotKey;
      return true;
    } on PlatformException {
      _registered = null;
      return false;
    }
  }

  Future<void> unregister() async {
    final hotKey = _registered;
    if (hotKey == null) return;
    await hotKeyManager.unregister(hotKey);
    _registered = null;
  }

  Future<void> unregisterAll() async {
    await hotKeyManager.unregisterAll();
    _registered = null;
  }
}
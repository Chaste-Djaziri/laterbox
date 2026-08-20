import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

/// System-wide quick capture hotkey: `Option/Alt + Space`.
///
/// A `PhysicalKeyboardKey` (rather than a logical key) keeps the hotkey
/// stable across keyboard layouts.
final quickCaptureHotKey = HotKey(
  key: PhysicalKeyboardKey.space,
  modifiers: const [HotKeyModifier.alt],
  scope: HotKeyScope.system,
);

/// Registers the system-wide quick capture hotkey using `hotkey_manager`.
class GlobalHotkeyService {
  HotKey? _registered;

  /// Registers [quickCaptureHotKey]. Returns `true` when the hotkey was
  /// successfully registered, `false` when it could not be taken (for example
  /// because another application already uses it).
  Future<bool> register({required Future<void> Function() onTriggered}) async {
    await unregister();
    try {
      await hotKeyManager.register(
        quickCaptureHotKey,
        keyDownHandler: (_) {
          debugPrint('[LaterBox Desktop] ⌥Space fired');
          onTriggered().catchError(
            (Object error, StackTrace stackTrace) {
              debugPrint('[LaterBox Desktop] hotkey callback FAILED: $error');
              debugPrintStack(stackTrace: stackTrace);
            },
          );
        },
      );
      _registered = quickCaptureHotKey;
      debugPrint('[LaterBox Desktop] hotkey registered: ⌥Space');
      debugPrint(
        '[LaterBox Desktop] registered hotkeys: '
        '${hotKeyManager.registeredHotKeyList}',
      );
      return true;
    } on PlatformException catch (error) {
      debugPrint('[LaterBox Desktop] HOTKEY REGISTRATION FAILED: $error');
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
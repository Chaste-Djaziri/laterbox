import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../settings/desktop_shortcut.dart';

/// Registers the system-wide quick capture hotkey using `hotkey_manager`.
///
/// The shortcut is configurable (see [register]) so users can move it away
/// from `⌥Space` when that collides with a launcher. Registration is atomic:
/// a replacement is only activated once the new shortcut is confirmed.
class GlobalHotkeyService {
  HotKey? _registered;
  DesktopShortcut _current = DesktopShortcut.defaultQuickCapture();

  DesktopShortcut get current => _current;

  bool get isRegistered => _registered != null;

  HotKey _toHotKey(DesktopShortcut shortcut) {
    final key = shortcut.physicalKey;
    if (key == null) {
      throw ArgumentError(
        'Shortcut key id ${shortcut.keyId} is unknown on this build',
      );
    }
    return HotKey(
      key: key,
      modifiers: shortcut.modifiers.map(_toModifier).toList(),
      scope: HotKeyScope.system,
    );
  }

  static HotKeyModifier _toModifier(DesktopModifier modifier) {
    switch (modifier) {
      case DesktopModifier.alt:
        return HotKeyModifier.alt;
      case DesktopModifier.control:
        return HotKeyModifier.control;
      case DesktopModifier.shift:
        return HotKeyModifier.shift;
      case DesktopModifier.meta:
        return HotKeyModifier.meta;
    }
  }

  /// Registers [shortcut] as the system-wide quick capture hotkey.
  ///
  /// Returns `true` when the hotkey was successfully registered, `false` when
  /// it could not be taken (for example because another application already
  /// uses it). A previously registered hotkey is left untouched until the new
  /// one is confirmed to work, so the existing shortcut is never lost.
  Future<bool> register(
    DesktopShortcut shortcut, {
    required Future<void> Function() onTriggered,
  }) async {
    final hotKey = _toHotKey(shortcut);
    try {
      await hotKeyManager.register(
        hotKey,
        keyDownHandler: (_) {
          debugPrint('[LaterBox Desktop] hotkey fired: ${shortcut.displayLabel}');
          onTriggered().catchError(
            (Object error, StackTrace stackTrace) {
              debugPrint('[LaterBox Desktop] hotkey callback FAILED: $error');
              debugPrintStack(stackTrace: stackTrace);
            },
          );
        },
      );
      // Successfully registered the new shortcut; now release the old one.
      await unregister();
      _registered = hotKey;
      _current = shortcut;
      debugPrint('[LaterBox Desktop] hotkey registered: ${shortcut.displayLabel}');
      return true;
    } on PlatformException catch (error) {
      debugPrint('[LaterBox Desktop] HOTKEY REGISTRATION FAILED: $error');
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
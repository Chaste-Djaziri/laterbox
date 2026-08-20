import '../settings/desktop_shortcut.dart';

/// No-op global hotkey service for web and mobile.
///
/// Mirrors the call surface of `GlobalHotkeyService` (io) so shared code can
/// compile on every platform.
class GlobalHotkeyService {
  DesktopShortcut _current = DesktopShortcut.defaultQuickCapture();

  DesktopShortcut get current => _current;

  bool get isRegistered => false;

  Future<bool> register(
    DesktopShortcut shortcut, {
    required Future<void> Function() onTriggered,
  }) async {
    _current = shortcut;
    return false;
  }

  Future<void> unregister() async {}

  Future<void> unregisterAll() async {}
}
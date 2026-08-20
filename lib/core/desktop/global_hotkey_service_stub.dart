/// No-op global hotkey service for web and mobile.
///
/// Mirrors the call surface of `GlobalHotkeyService` (io) so shared code can
/// compile on every platform.
class GlobalHotkeyService {
  Future<bool> register({required void Function() onTriggered}) async {
    return false;
  }

  Future<void> unregister() async {}

  Future<void> unregisterAll() async {}
}
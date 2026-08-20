import 'tray_menu_state.dart';

/// No-op system tray service for web and mobile.
///
/// Mirrors the call surface of `TrayService` (io) so shared code can compile
/// on every platform.
class TrayService {
  Future<void> init({
    required Future<void> Function() onQuickCapture,
    required Future<void> Function() onOpenLaterBox,
    required Future<void> Function() onOpenSettings,
    required Future<void> Function() onQuit,
  }) async {}

  Future<void> updateMenu(DesktopMenuState state) async {}

  Future<void> destroy() async {}
}
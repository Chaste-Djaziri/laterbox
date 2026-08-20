/// No-op system tray service for web and mobile.
///
/// Mirrors the call surface of `TrayService` (io) so shared code can compile
/// on every platform.
class TrayService {
  Future<void> init({
    required void Function() onQuickCapture,
    required void Function() onOpenLaterBox,
    required void Function() onQuit,
  }) async {}

  Future<void> destroy() async {}
}
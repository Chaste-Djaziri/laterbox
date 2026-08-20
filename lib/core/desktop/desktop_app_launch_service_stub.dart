/// No-op app-launch integration for web and mobile.
///
/// Mirrors the call surface of `DesktopAppLaunchService` (io) so shared code
/// can compile on every platform. Reports no login-item integration.
class DesktopAppLaunchService {
  const DesktopAppLaunchService();

  Future<bool> wasLaunchedAtLogin() async => false;

  Future<bool> isLoginItemEnabled() async => false;

  Future<bool> setLoginItemEnabled(bool enabled) async => false;
}
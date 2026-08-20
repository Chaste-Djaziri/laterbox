import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:launch_at_startup/launch_at_startup.dart';

/// Reads the native macOS app-launch integration through the
/// `laterbox/app_launch` method channel, falling back to `launch_at_startup`.
///
/// - `wasLaunchedAtLogin`: whether the app was started by the login item
///   (used to start quietly without a main window).
/// - `isLoginItemEnabled` / `setLoginItemEnabled`: the "Launch at login"
///   preference.
class DesktopAppLaunchService {
  static const MethodChannel _channel = MethodChannel('laterbox/app_launch');

  const DesktopAppLaunchService();

  Future<bool> wasLaunchedAtLogin() async {
    try {
      return await _channel.invokeMethod<bool>('wasLaunchedAtLogin') ?? false;
    } on PlatformException catch (error) {
      debugPrint('[LaterBox] launch check failed: ${error.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> isLoginItemEnabled() async {
    try {
      final res = await _channel.invokeMethod<bool>('isLoginItemEnabled');
      if (res != null) return res;
    } on PlatformException catch (error) {
      debugPrint('[LaterBox] login item check failed: ${error.message}');
    } on MissingPluginException {
      // Fall through to launch_at_startup
    }

    try {
      return await LaunchAtStartup.instance.isEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<bool> setLoginItemEnabled(bool enabled) async {
    try {
      final result = await _channel
          .invokeMethod<bool>('setLoginItemEnabled', {'enabled': enabled});
      if (result != null) return result;
    } on PlatformException catch (error) {
      debugPrint('[LaterBox] login item update failed: ${error.message}');
    } on MissingPluginException {
      // Fall through to launch_at_startup
    }

    try {
      if (enabled) {
        await LaunchAtStartup.instance.enable();
      } else {
        await LaunchAtStartup.instance.disable();
      }
      return true;
    } catch (e) {
      debugPrint('[LaterBox] launch_at_startup update failed: $e');
      return false;
    }
  }
}
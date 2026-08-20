import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads the native macOS app-launch integration through the
/// `laterbox/app_launch` method channel.
///
/// - `wasLaunchedAtLogin`: whether the app was started by the login item
///   (used to start quietly without a main window).
/// - `isLoginItemEnabled` / `setLoginItemEnabled`: the "Launch at login"
///   preference, backed by SMAppService on macOS 13+.
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
      return await _channel.invokeMethod<bool>('isLoginItemEnabled') ?? false;
    } on PlatformException catch (error) {
      debugPrint('[LaterBox] login item check failed: ${error.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> setLoginItemEnabled(bool enabled) async {
    try {
      final result = await _channel
          .invokeMethod<bool>('setLoginItemEnabled', {'enabled': enabled});
      return result ?? false;
    } on PlatformException catch (error) {
      debugPrint('[LaterBox] login item update failed: ${error.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
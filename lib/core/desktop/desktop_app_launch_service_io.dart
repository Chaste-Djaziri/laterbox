import 'dart:io' show Platform;

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
  static bool _launchedAtLogin = false;

  const DesktopAppLaunchService();

  static void configure(List<String> arguments) {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    _launchedAtLogin = arguments.contains('--launch-at-login');
    LaunchAtStartup.instance.setup(
      appName: 'laterbox',
      appPath: Platform.resolvedExecutable,
      args: const ['--launch-at-login'],
    );
  }

  Future<bool> wasLaunchedAtLogin() async {
    if (Platform.isWindows || Platform.isLinux) {
      return _launchedAtLogin;
    }
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
      final result = await _channel.invokeMethod<bool>('setLoginItemEnabled', {
        'enabled': enabled,
      });
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

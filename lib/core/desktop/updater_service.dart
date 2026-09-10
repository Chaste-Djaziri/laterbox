import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Sparkle updater bridge for macOS direct distribution.
/// On MAS / non-macOS this is a no-op.
class UpdaterService {
  static const MethodChannel _channel = MethodChannel('laterbox/updater');

  const UpdaterService();

  Future<bool> canCheckForUpdates() async {
    if (kIsWeb || !Platform.isMacOS) return false;
    try {
      return await _channel.invokeMethod<bool>('canCheckForUpdates') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> checkForUpdates() async {
    if (kIsWeb || !Platform.isMacOS) return false;
    try {
      return await _channel.invokeMethod<bool>('checkForUpdates') ?? false;
    } on MissingPluginException {
      debugPrint('[LaterBox Updater] channel not registered (Sparkle not linked)');
      return false;
    } on PlatformException catch (e) {
      debugPrint('[LaterBox Updater] check failed: ${e.message}');
      return false;
    }
  }
}

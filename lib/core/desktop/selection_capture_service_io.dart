import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads the selected text of the foreground macOS application through the
/// Accessibility APIs via the `laterbox/selection_capture` method channel.
///
/// Requires Accessibility permission for the host app. When the permission is
/// missing (or reading fails for any reason) the methods return `null` and the
/// caller falls back to the clipboard.
class SelectionCaptureService {
  static const MethodChannel _channel = MethodChannel(
    'laterbox/selection_capture',
  );

  const SelectionCaptureService();

  Future<String?> readSelectedText() async {
    try {
      final value = await _channel.invokeMethod<String>('readSelectedText');
      if (value == null || value.trim().isEmpty) return null;
      return value;
    } on PlatformException catch (error) {
      debugPrint('[LaterBox] selection capture failed: ${error.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<String?> readFrontmostApplication() async {
    try {
      final name = await _channel.invokeMethod<String>(
        'readFrontmostApplication',
      );
      if (name == null || name.trim().isEmpty) return null;
      return name;
    } on PlatformException catch (error) {
      debugPrint('[LaterBox] frontmost app lookup failed: ${error.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'screen_capture_context.dart';

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

  /// Queries the active browser tab URL and title if the frontmost app is a browser.
  Future<Map<String, String>?> readActiveBrowserTab({String? appName}) async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'readActiveBrowserTab',
        appName != null ? {'appName': appName} : null,
      );
      if (raw == null) return null;
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    } on Object catch (error) {
      debugPrint('[LaterBox] active browser lookup failed: $error');
      return null;
    }
  }

  /// Gathers active screen context: frontmost app, active URL, title, selected text, and highlight URL.
  Future<ScreenCaptureContext?> readScreenContext() async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'readScreenContext',
      );
      if (raw == null) return null;
      return ScreenCaptureContext.fromMap(raw);
    } on Object catch (error) {
      debugPrint('[LaterBox] screen context lookup failed: $error');
      return null;
    }
  }

  /// Builds a W3C Scroll-to-Text Fragment URL for direct word highlight navigation.
  static String formatTextFragmentUrl(String baseUrl, String selectedText) {
    final cleanUrl = baseUrl.split('#').first;
    if (baseUrl.contains(':~:text=')) return baseUrl;

    final cleanSnippet = selectedText.trim().replaceAll(RegExp(r'^["“”\s]+|["“”\s]+$'), '');
    final words = cleanSnippet.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return cleanUrl;

    final String encodedDirective;
    if (words.length > 10) {
      final start = words.take(3).join(' ');
      final end = words.skip(words.length - 3).join(' ');
      encodedDirective = '${Uri.encodeComponent(start)},${Uri.encodeComponent(end)}';
    } else {
      encodedDirective = Uri.encodeComponent(cleanSnippet);
    }

    return '$cleanUrl#:~:text=$encodedDirective';
  }

  /// Queries current macOS screen geometry, including notch height if present.
  Future<Map<String, dynamic>?> getScreenGeometry() async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('getScreenGeometry');
      if (raw == null) return null;
      return raw.map((k, v) => MapEntry(k.toString(), v));
    } on Object catch (error) {
      debugPrint('[LaterBox] screen geometry lookup failed: $error');
      return null;
    }
  }

  /// Sets native macOS window attributes (frameless, transparent, statusBar level)
  /// when docked to the hardware notch.
  Future<bool> setNotchWindowStyle(bool isNotch) async {
    try {
      return await _channel.invokeMethod<bool>('setNotchWindowStyle', {'isNotch': isNotch}) ?? false;
    } on Object catch (error) {
      debugPrint('[LaterBox] setNotchWindowStyle failed: $error');
      return false;
    }
  }

  /// Requests the macOS accessibility prompt if not yet granted.
  Future<bool> requestAccessibilityPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestAccessibilityPermission') ?? false;
    } on Object {
      return false;
    }
  }

  /// Whether the host app holds Accessibility permission (`AXIsProcessTrusted`).
  Future<bool> isAccessibilityTrusted() async {
    try {
      return await _channel.invokeMethod<bool>('isAccessibilityTrusted') ?? false;
    } on PlatformException catch (error) {
      debugPrint('[LaterBox] accessibility check failed: ${error.message}');
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
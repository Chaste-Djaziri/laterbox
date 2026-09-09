import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../features/capture/domain/capture_payload.dart';
import '../../features/capture/domain/capture_service.dart';

/// Platform channel bridge between the Flutter LaterBox app and the native
/// macOS Notch NSPanel companion & ScreenCaptureKit watcher.
class MacOSCompanion {
  MacOSCompanion._();

  static const MethodChannel _channel = MethodChannel('laterbox/macos_companion');

  static final StreamController<Map<String, dynamic>> _candidateController =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get detectedCandidates =>
      _candidateController.stream;

  static CaptureService? _captureService;
  static VoidCallback? _onOpenLaterBox;

  /// Initializes the companion channel handler with callbacks into LaterBox.
  static void initialize({
    required CaptureService captureService,
    required VoidCallback onOpenLaterBox,
  }) {
    _captureService = captureService;
    _onOpenLaterBox = onOpenLaterBox;

    if (!kIsWeb && Platform.isMacOS) {
      _channel.setMethodCallHandler(_handleMethodCall);
    }
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'screenCandidateDetected':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        _candidateController.add(args);
        break;

      case 'saveCandidate':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final title = args['title'] as String? ?? 'Screen Note';
        final url = args['url'] as String?;
        final snippet = args['snippet'] as String?;

        if (url != null && url.isNotEmpty) {
          final payload = CapturePayload(
            url: url,
            text: snippet ?? title,
            source: CaptureSource.desktopQuickCapture,
          );
          await _captureService?.save(payload);
        } else {
          final payload = CapturePayload(
            text: snippet ?? title,
            source: CaptureSource.desktopQuickCapture,
          );
          await _captureService?.save(payload);
        }
        break;

      case 'itemsDropped':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final items = (args['items'] as List<dynamic>?)?.cast<String>() ?? [];
        for (final item in items) {
          final payload = CapturePayload.fromValue(
            item,
            source: CaptureSource.desktopQuickCapture,
          );
          await _captureService?.save(payload);
        }
        break;

      case 'openLaterBox':
        _onOpenLaterBox?.call();
        break;

      default:
        break;
    }
  }

  /// Displays the native floating notch panel on macOS.
  static Future<bool> showNotch() async {
    if (kIsWeb || !Platform.isMacOS) return false;
    try {
      return await _channel.invokeMethod<bool>('showNotch') ?? false;
    } catch (e) {
      debugPrint('[MacOSCompanion] showNotch failed: $e');
      return false;
    }
  }

  /// Hides the native floating notch panel.
  static Future<bool> hideNotch() async {
    if (kIsWeb || !Platform.isMacOS) return false;
    try {
      return await _channel.invokeMethod<bool>('hideNotch') ?? false;
    } catch (e) {
      debugPrint('[MacOSCompanion] hideNotch failed: $e');
      return false;
    }
  }

  /// Starts the continuous ScreenCaptureKit + Vision OCR screen watcher.
  static Future<bool> startWatching() async {
    if (kIsWeb || !Platform.isMacOS) return false;
    try {
      return await _channel.invokeMethod<bool>('startWatching') ?? false;
    } catch (e) {
      debugPrint('[MacOSCompanion] startWatching failed: $e');
      return false;
    }
  }

  /// Stops the screen watcher.
  static Future<bool> stopWatching() async {
    if (kIsWeb || !Platform.isMacOS) return false;
    try {
      return await _channel.invokeMethod<bool>('stopWatching') ?? false;
    } catch (e) {
      debugPrint('[MacOSCompanion] stopWatching failed: $e');
      return false;
    }
  }
}

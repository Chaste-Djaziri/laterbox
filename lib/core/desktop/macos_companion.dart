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
  static VoidCallback? _onOpenPlans;
  static Future<void> Function(List<String> filePaths, String? text)? _onFilesDropped;

  /// Initializes the companion channel handler with callbacks into LaterBox.
  static void initialize({
    required CaptureService captureService,
    required VoidCallback onOpenLaterBox,
    required VoidCallback onOpenPlans,
    Future<void> Function(List<String> filePaths, String? text)? onFilesDropped,
  }) {
    _captureService = captureService;
    _onOpenLaterBox = onOpenLaterBox;
    _onOpenPlans = onOpenPlans;
    _onFilesDropped = onFilesDropped;

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
        final id = args['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString();
        final title = args['title'] as String? ?? 'Screen Note';
        final url = args['url'] as String?;
        final snippet = args['snippet'] as String?;
        final source = _captureSource(args['source'] as String?);
        try {
          final payload = CapturePayload(
            id: id,
            url: url?.isNotEmpty == true ? url : null,
            text: snippet?.isNotEmpty == true ? snippet : (url == null ? title : null),
            source: source,
          );
          final service = _captureService;
          if (service == null) {
            return <String, dynamic>{
              'ok': false,
              'id': id,
              'message': 'LaterBox is still starting. Please try again.',
            };
          }
          await service.save(payload);
          return <String, dynamic>{
            'ok': true,
            'id': id,
            'title': title,
            'kind': args['kind'] as String? ?? (url == null ? 'note' : 'link'),
          };
        } catch (error, stackTrace) {
          debugPrint('[MacOSCompanion] capture failed: $error\n$stackTrace');
          return <String, dynamic>{
            'ok': false,
            'id': id,
            'message': 'Could not save this item. Check LaterBox and retry.',
          };
        }

      case 'itemsDropped':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final items = (args['items'] as List<dynamic>?)?.cast<String>() ?? [];
        // Separate file drops (image/pdf/doc) from text/url drops.
        final filePaths = <String>[];
        final textItems = <String>[];
        for (final item in items) {
          final trimmed = item.trim();
          if (trimmed.isEmpty) continue;
          final looksLikeFile = trimmed.startsWith('/') || trimmed.startsWith('file://') || File(trimmed).existsSync();
          // Heuristic: paths with known attachment extensions are files.
          final ext = trimmed.split('.').last.toLowerCase();
          final isAttachmentExt = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'pdf', 'txt', 'md', 'doc', 'docx'}.contains(ext);
          if ((looksLikeFile || isAttachmentExt) && (trimmed.contains('/') || trimmed.startsWith('file'))) {
            final path = trimmed.startsWith('file://') ? Uri.parse(trimmed).toFilePath() : trimmed;
            if (path.isNotEmpty) filePaths.add(path);
            else textItems.add(trimmed);
          } else {
            textItems.add(trimmed);
          }
        }
        if (filePaths.isNotEmpty && _onFilesDropped != null) {
          final combinedText = textItems.isEmpty ? null : textItems.join('\n');
          await _onFilesDropped!(filePaths, combinedText);
        }
        for (final item in textItems) {
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

      case 'openPlans':
        _onOpenPlans?.call();
        break;

      default:
        break;
    }
  }

  static CaptureSource _captureSource(String? value) {
    return switch (value) {
      'macosShare' => CaptureSource.macosShare,
      _ => CaptureSource.desktopQuickCapture,
    };
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

  static Future<bool> setProAutomationEnabled(bool enabled) async {
    if (kIsWeb || !Platform.isMacOS) return false;
    try {
      return await _channel.invokeMethod<bool>('setProAutomationEnabled', {
            'enabled': enabled,
          }) ??
          false;
    } catch (e) {
      debugPrint('[MacOSCompanion] entitlement sync failed: $e');
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

  /// Whether Screen Recording permission is already granted (CGPreflight).
  static Future<bool> isScreenCaptureTrusted() async {
    if (kIsWeb || !Platform.isMacOS) return false;
    try {
      return await _channel.invokeMethod<bool>('isScreenCaptureTrusted') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the system Screen Recording dialog if not yet trusted.
  static Future<bool> requestScreenCapturePermission() async {
    if (kIsWeb || !Platform.isMacOS) return false;
    try {
      return await _channel.invokeMethod<bool>('requestScreenCapturePermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens System Settings → Privacy & Security → Screen Recording.
  static Future<bool> openScreenRecordingSettings() async {
    if (kIsWeb || !Platform.isMacOS) return false;
    try {
      return await _channel.invokeMethod<bool>('openScreenRecordingSettings') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> reportCaptureCompleted({
    required String id,
    required String title,
    required String value,
    required String kind,
  }) async {
    if (kIsWeb || !Platform.isMacOS) return;
    await _channel.invokeMethod<void>('captureCompleted', {
      'id': id,
      'title': title,
      'value': value,
      'kind': kind,
    });
  }

  static Future<void> reportCaptureFailed({
    required String id,
    required String message,
  }) async {
    if (kIsWeb || !Platform.isMacOS) return;
    await _channel.invokeMethod<void>('captureFailed', {
      'id': id,
      'message': message,
    });
  }
}

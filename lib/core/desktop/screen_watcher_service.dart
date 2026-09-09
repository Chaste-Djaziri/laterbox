import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../features/capture/domain/capture_payload.dart';
import '../../features/capture/domain/capture_service.dart';
import 'screen_capture_context.dart';
import 'selection_capture_service.dart';

class ScreenWatcherService extends ChangeNotifier {
  ScreenWatcherService({
    required SelectionCaptureService selectionService,
    required CaptureService captureService,
    Duration pollInterval = const Duration(milliseconds: 1600),
  })  : _selectionService = selectionService,
        _captureService = captureService,
        _pollInterval = pollInterval;

  final SelectionCaptureService _selectionService;
  final CaptureService _captureService;
  final Duration _pollInterval;

  Timer? _timer;
  ScreenCaptureContext? _currentContext;
  bool _isWatching = false;
  String? _lastSavedId;
  String? _statusMessage;

  ScreenCaptureContext? get currentContext => _currentContext;
  bool get isWatching => _isWatching;
  String? get statusMessage => _statusMessage;

  bool get hasActiveLink =>
      _currentContext?.activeUrl != null &&
      _currentContext!.activeUrl!.trim().isNotEmpty;

  bool get hasSelectedText =>
      _currentContext?.selectedText != null &&
      _currentContext!.selectedText!.trim().isNotEmpty;

  void startWatching() {
    if (_isWatching) return;
    _isWatching = true;
    _poll();
    _timer = Timer.periodic(_pollInterval, (_) => _poll());
  }

  void stopWatching() {
    _timer?.cancel();
    _timer = null;
    _isWatching = false;
  }

  Future<void> pollNow() => _poll();

  Future<void> _poll() async {
    try {
      final context = await _selectionService.readScreenContext();
      if (context != null && context != _currentContext) {
        _currentContext = context;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[LaterBox ScreenWatcher] poll error: $e');
    }
  }

  /// Saves the current active browser tab link to LaterBox.
  Future<bool> saveActiveLink({String? note}) async {
    final url = _currentContext?.activeUrl;
    if (url == null || url.trim().isEmpty) return false;

    try {
      final title = _currentContext?.activeTitle ?? '';
      final value = note != null && note.trim().isNotEmpty
          ? '$url\n\n$note'
          : url;

      final payload = CapturePayload.fromValue(
        value,
        title: title.isNotEmpty ? title : null,
        source: CaptureSource.quickCapture,
      );

      await _captureService.save(payload);
      _lastSavedId = payload.id;
      _statusMessage = 'Saved link!';
      notifyListeners();

      Future.delayed(const Duration(seconds: 3), () {
        if (_statusMessage == 'Saved link!') {
          _statusMessage = null;
          notifyListeners();
        }
      });
      return true;
    } catch (e) {
      debugPrint('[LaterBox ScreenWatcher] saveActiveLink error: $e');
      _statusMessage = 'Failed to save link';
      notifyListeners();
      return false;
    }
  }

  /// Saves the selected word/quote with direct W3C Text Fragment highlight reference.
  Future<bool> saveSelectedWordReference({String? note}) async {
    final selected = _currentContext?.selectedText;
    if (selected == null || selected.trim().isEmpty) return false;

    try {
      final highlightUrl = _currentContext?.highlightUrl ??
          (_currentContext?.activeUrl != null
              ? SelectionCaptureService.formatTextFragmentUrl(
                  _currentContext!.activeUrl!,
                  selected,
                )
              : null);

      final buffer = StringBuffer();
      buffer.writeln('"$selected"');
      if (highlightUrl != null && highlightUrl.isNotEmpty) {
        buffer.writeln();
        buffer.writeln(highlightUrl);
      }
      if (note != null && note.trim().isNotEmpty) {
        buffer.writeln();
        buffer.writeln(note);
      }

      final title = _currentContext?.activeTitle != null
          ? 'Ref: ${_currentContext!.activeTitle}'
          : 'Reference snippet';

      final payload = CapturePayload.fromValue(
        buffer.toString().trim(),
        title: title,
        source: CaptureSource.quickCapture,
      );

      await _captureService.save(payload);
      _lastSavedId = payload.id;
      _statusMessage = 'Saved word reference!';
      notifyListeners();

      Future.delayed(const Duration(seconds: 3), () {
        if (_statusMessage == 'Saved word reference!') {
          _statusMessage = null;
          notifyListeners();
        }
      });
      return true;
    } catch (e) {
      debugPrint('[LaterBox ScreenWatcher] saveSelectedWordReference error: $e');
      _statusMessage = 'Failed to save reference';
      notifyListeners();
      return false;
    }
  }

  /// Saves arbitrary quick text or dropped content.
  Future<bool> saveContent(String content, {String? title}) async {
    if (content.trim().isEmpty) return false;

    try {
      final payload = CapturePayload.fromValue(
        content.trim(),
        title: title,
        source: CaptureSource.quickCapture,
      );

      await _captureService.save(payload);
      _lastSavedId = payload.id;
      _statusMessage = 'Saved to LaterBox!';
      notifyListeners();

      Future.delayed(const Duration(seconds: 3), () {
        if (_statusMessage == 'Saved to LaterBox!') {
          _statusMessage = null;
          notifyListeners();
        }
      });
      return true;
    } catch (e) {
      debugPrint('[LaterBox ScreenWatcher] saveContent error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    stopWatching();
    super.dispose();
  }
}

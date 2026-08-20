import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/capture/domain/capture_payload.dart';
import '../../features/capture/domain/capture_service.dart';
import 'clipboard_capture_service.dart';
import 'desktop_service.dart';

/// Blur→close delay, short enough to feel responsive but long enough to
/// ignore spurious focus events.
const blurCloseDelay = Duration(milliseconds: 350);
const successVisibleDuration = Duration(milliseconds: 450);

enum QuickCaptureStatus { idle, active, saving, success }

/// Drives the desktop quick capture flow:
/// hotkey/tray → small focused window → save → disappear.
class QuickCaptureController extends ChangeNotifier {
  QuickCaptureController({
    required DesktopService desktopService,
    required ClipboardCaptureService clipboardService,
    required CaptureService captureService,
    bool enableBlurClose = false,
  })  : _desktopService = desktopService,
        _clipboardService = clipboardService,
        _captureService = captureService,
        _enableBlurClose = enableBlurClose {
    _desktopService.addWindowBlurListener(_onWindowBlur);
    _desktopService.addWindowCloseListener(close);
  }

  final DesktopService _desktopService;
  final ClipboardCaptureService _clipboardService;
  final CaptureService _captureService;

  /// Temporarily disabled while the window show/focus path is being verified;
  /// re-enable once quick capture reliably opens.
  final bool _enableBlurClose;

  QuickCaptureStatus _status = QuickCaptureStatus.idle;
  String? _prefillText;
  String? _draft;
  String? _clipboardTextAtCaptureStart;
  Timer? _blurTimer;
  Timer? _successTimer;
  bool _disposed = false;

  QuickCaptureStatus get status => _status;
  bool get isActive => _status != QuickCaptureStatus.idle;
  bool get isSaving => _status == QuickCaptureStatus.saving;
  String? get prefillText => _prefillText;

  void updateDraft(String value) {
    _draft = value;
  }

  void clearDraft() {
    _draft = null;
  }

  /// Opens the quick capture flow. Called from [DesktopActions].
  ///
  /// Only manages capture state; the native window is shown afterwards by
  /// [DesktopActions.openQuickCapture] so the first visible frame is already
  /// the quick capture UI.
  Future<void> open() async {
    if (_disposed || isActive) return;
    _successTimer?.cancel();

    final clipboard = await _clipboardService.readText();
    final hasDraft = _draft != null && _draft!.trim().isNotEmpty;
    String? prefill;
    if (hasDraft && clipboard == _clipboardTextAtCaptureStart) {
      prefill = _draft;
    } else if (clipboard != null && ClipboardCaptureService.isUrl(clipboard)) {
      prefill = clipboard;
    }

    _clipboardTextAtCaptureStart = clipboard;
    _prefillText = prefill;
    _status = QuickCaptureStatus.active;
    notifyListeners();
  }

  /// Saves the current draft via the shared capture pipeline, then disappears.
  Future<void> save() async {
    if (_disposed || _status == QuickCaptureStatus.idle) return;
    if (_status == QuickCaptureStatus.saving) return;
    final value = (_draft ?? '').trim();
    if (value.isEmpty) {
      await close();
      return;
    }

    _status = QuickCaptureStatus.saving;
    notifyListeners();

    try {
      await _captureService.save(
        CapturePayload.fromValue(
          value,
          source: CaptureSource.desktopQuickCapture,
        ),
      );
      if (_disposed) return;
      _status = QuickCaptureStatus.success;
      notifyListeners();

      _successTimer = Timer(successVisibleDuration, () {
        close();
      });
    } catch (error, stackTrace) {
      debugPrint('LaterBox quick capture failed: $error\n$stackTrace');
      if (_disposed) return;
      _status = QuickCaptureStatus.active;
      notifyListeners();
    }
  }

  /// Hides the capture window and resets state.
  Future<void> close() async {
    _blurTimer?.cancel();
    _successTimer?.cancel();
    if (_disposed) return;
    _status = QuickCaptureStatus.idle;
    _prefillText = null;
    notifyListeners();
    await _desktopService.hideMainWindow();
  }

  void _onWindowBlur() {
    debugPrint('[LaterBox Desktop] window blur (blur-close disabled)');
    if (!_enableBlurClose) return;
    if (_status != QuickCaptureStatus.active) return;
    _blurTimer?.cancel();
    _blurTimer = Timer(blurCloseDelay, () {
      if (_status == QuickCaptureStatus.active) {
        close();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _blurTimer?.cancel();
    _successTimer?.cancel();
    super.dispose();
  }
}
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/capture/domain/capture_payload.dart';
import '../../features/capture/domain/capture_service.dart';
import 'clipboard_capture_service.dart';
import 'desktop_capture_context.dart';
import 'desktop_service.dart';

/// Blur→close delay, short enough to feel responsive but long enough to
/// ignore spurious focus events.
const blurCloseDelay = Duration(milliseconds: 350);
const successVisibleDuration = Duration(milliseconds: 450);

enum QuickCaptureStatus { idle, active, saving, success }

/// Drives the desktop quick capture state machine.
///
/// Owns no window logic: [DesktopActions] decides how the window is shown and
/// restored/hidden. This class only tracks capture state and persists values
/// through the shared capture pipeline.
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
  String? _sourceApplication;
  String? _draft;
  String? _clipboardTextAtCaptureStart;
  Timer? _blurTimer;
  Timer? _successTimer;
  bool _disposed = false;

  QuickCaptureStatus get status => _status;
  bool get isActive => _status != QuickCaptureStatus.idle;
  bool get isSaving => _status == QuickCaptureStatus.saving;
  String? get prefillText => _prefillText;
  String? get sourceApplication => _sourceApplication;

  void updateDraft(String value) {
    _draft = value;
  }

  void clearDraft() {
    _draft = null;
  }

  /// Opens the quick capture flow. Called from [DesktopActions] with a
  /// resolved capture context (selection → clipboard URL → clipboard text).
  ///
  /// When [context] is omitted, falls back to clipboard resolution so unit
  /// tests and older call sites keep working.
  Future<void> open({DesktopCaptureContext? context}) async {
    if (_disposed || isActive) return;
    _successTimer?.cancel();

    final resolved = context ?? await _resolveContext();
    _prefillText = resolved.type == DesktopCaptureContextType.empty
        ? null
        : resolved.value;
    _sourceApplication = resolved.sourceApplication;
    _status = QuickCaptureStatus.active;
    notifyListeners();
  }

  Future<DesktopCaptureContext> _resolveContext() async {
    final clipboard = await _clipboardService.readText();
    _clipboardTextAtCaptureStart = clipboard;
    final hasDraft = _draft != null && _draft!.trim().isNotEmpty;
    if (hasDraft && clipboard == _clipboardTextAtCaptureStart) {
      return DesktopCaptureContext(
        type: DesktopCaptureContextType.clipboardText,
        value: _draft!,
      );
    }
    final value = clipboard?.trim();
    if (value == null || value.isEmpty) {
      return const DesktopCaptureContext(
        type: DesktopCaptureContextType.empty,
        value: '',
      );
    }
    return DesktopCaptureContext(
      type: ClipboardCaptureService.isUrl(value)
          ? DesktopCaptureContextType.clipboardUrl
          : DesktopCaptureContextType.clipboardText,
      value: value,
    );
  }

  /// Saves an explicit value through the shared capture pipeline, then shows a
  /// brief success state before returning to idle.
  Future<void> saveValue(String value) async {
    if (_disposed) return;
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await close();
      return;
    }
    if (_status == QuickCaptureStatus.saving) return;

    _draft = value;
    _status = QuickCaptureStatus.saving;
    notifyListeners();

    try {
      await _captureService.save(
        CapturePayload.fromValue(
          trimmed,
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

  /// Saves the current draft. Convenience for tests and legacy call sites.
  Future<void> save() => saveValue(_draft ?? '');

  /// Resets capture state. Does not touch the window; [DesktopActions] decides
  /// whether to restore or hide it.
  Future<void> close() async {
    _blurTimer?.cancel();
    _successTimer?.cancel();
    if (_disposed) return;
    _status = QuickCaptureStatus.idle;
    _prefillText = null;
    _sourceApplication = null;
    notifyListeners();
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
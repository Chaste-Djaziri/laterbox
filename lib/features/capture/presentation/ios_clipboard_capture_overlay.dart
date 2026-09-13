import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/desktop/clipboard_capture_service.dart';
import '../domain/capture_payload.dart';
import '../domain/capture_providers.dart';

typedef ClipboardTextReader = Future<String?> Function();

/// Offers a foreground-only save confirmation for text copied outside LaterBox.
///
/// iOS does not allow an app to observe the pasteboard or display UI while it is
/// in the background. This checks once when LaterBox becomes visible, then
/// places the prompt below the system safe area on both Dynamic Island/notch and
/// conventional iPhones.
class IosClipboardCaptureOverlay extends ConsumerStatefulWidget {
  const IosClipboardCaptureOverlay({
    required this.child,
    this.clipboardReader,
    super.key,
  });

  final Widget child;
  final ClipboardTextReader? clipboardReader;

  @override
  ConsumerState<IosClipboardCaptureOverlay> createState() =>
      _IosClipboardCaptureOverlayState();
}

class _IosClipboardCaptureOverlayState
    extends ConsumerState<IosClipboardCaptureOverlay>
    with WidgetsBindingObserver {
  String? _candidate;
  String? _lastHandledValue;
  bool _saving = false;
  Timer? _dismissTimer;

  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (_isIos) {
      WidgetsBinding.instance.addObserver(this);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkClipboard());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  Future<String?> _readClipboard() async {
    if (widget.clipboardReader case final reader?) return reader();
    try {
      return (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    } on PlatformException {
      return null;
    }
  }

  Future<void> _checkClipboard() async {
    if (!_isIos || _candidate != null || _saving) return;
    final value = (await _readClipboard())?.trim();
    if (!mounted ||
        value == null ||
        value.isEmpty ||
        value == _lastHandledValue) {
      return;
    }
    setState(() => _candidate = value);
  }

  void _dismiss() {
    _dismissTimer?.cancel();
    setState(() {
      _lastHandledValue = _candidate;
      _candidate = null;
      _saving = false;
    });
  }

  Future<void> _save() async {
    final value = _candidate;
    if (value == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(captureServiceProvider)
          .save(CapturePayload.fromValue(value));
      if (!mounted) return;
      setState(() {
        _lastHandledValue = value;
        _candidate = null;
        _saving = false;
      });
      _dismissTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() {});
      });
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isIos) return widget.child;
    final candidate = _candidate;
    return Stack(
      children: [
        widget.child,
        if (candidate != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            right: 16,
            child: _ClipboardSavePrompt(
              value: candidate,
              saving: _saving,
              onSave: _save,
              onDismiss: _dismiss,
            ),
          ),
      ],
    );
  }
}

class _ClipboardSavePrompt extends StatelessWidget {
  const _ClipboardSavePrompt({
    required this.value,
    required this.saving,
    required this.onSave,
    required this.onDismiss,
  });

  final String value;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLink = ClipboardCaptureService.isUrl(value);
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Row(
            children: [
              Icon(
                isLink ? Icons.link_rounded : Icons.content_paste_rounded,
                color: theme.colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Save copied item?',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value.replaceAll(RegExp(r'\s+'), ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onInverseSurface.withValues(
                          alpha: 0.75,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: saving ? null : onDismiss,
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: saving ? null : onSave,
                child: saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/desktop/clipboard_capture_service.dart';
import '../../../core/enrichment/enrichment_providers.dart';
import '../domain/capture_payload.dart';
import '../domain/capture_providers.dart';
import '../../enrichment/domain/item_metadata.dart';

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
  static const _clipboardEvents = EventChannel('laterbox/ios_clipboard');

  String? _candidate;
  String? _lastHandledValue;
  EnrichedMetadata? _metadata;
  bool _saving = false;
  bool _promptVisible = false;
  StreamSubscription<dynamic>? _clipboardEventSubscription;

  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    if (_isIos) {
      WidgetsBinding.instance.addObserver(this);
      _clipboardEventSubscription = _clipboardEvents
          .receiveBroadcastStream()
          .listen((_) => _checkClipboard());
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkClipboard());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clipboardEventSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboard();
      Future<void>.delayed(const Duration(milliseconds: 350), _checkClipboard);
    }
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
    setState(() {
      _candidate = value;
      _metadata = null;
      _promptVisible = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _candidate == value) setState(() => _promptVisible = true);
    });
    _loadMetadata(value);
  }

  Future<void> _loadMetadata(String value) async {
    if (!ClipboardCaptureService.isUrl(value)) return;
    final remote = ref.read(remoteMetadataDataSourceProvider);
    if (remote == null) return;
    try {
      final metadata = await remote.fetch(value);
      if (mounted && _candidate == value) {
        setState(() => _metadata = metadata);
      }
    } catch (_) {
      // The prompt remains useful offline or when a website blocks metadata.
    }
  }

  void _dismiss() {
    if (!_promptVisible) return;
    setState(() => _promptVisible = false);
    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _lastHandledValue = _candidate;
        _candidate = null;
        _metadata = null;
        _saving = false;
      });
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
      _dismiss();
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
            child: AnimatedSlide(
              offset: _promptVisible ? Offset.zero : const Offset(0, -1.2),
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _promptVisible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: _ClipboardSavePrompt(
                  value: candidate,
                  metadata: _metadata,
                  saving: _saving,
                  onSave: _save,
                  onDismiss: _dismiss,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ClipboardSavePrompt extends StatelessWidget {
  const _ClipboardSavePrompt({
    required this.value,
    required this.metadata,
    required this.saving,
    required this.onSave,
    required this.onDismiss,
  });

  final String value;
  final EnrichedMetadata? metadata;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLink = ClipboardCaptureService.isUrl(value);
    final previewImageUrl = metadata?.previewImageUrl?.trim();
    final title = metadata?.title?.trim();
    final domain =
        metadata?.siteName?.trim() ??
        metadata?.domain?.trim() ??
        Uri.tryParse(value)?.host.replaceFirst(RegExp(r'^www\\.'), '');
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
              _PreviewIcon(
                imageUrl: previewImageUrl?.isEmpty == false
                    ? previewImageUrl
                    : null,
                icon: isLink ? Icons.link_rounded : Icons.content_paste_rounded,
                color: theme.colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title?.isNotEmpty == true ? title! : 'Save copied item?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      domain?.isNotEmpty == true
                          ? domain!
                          : value.replaceAll(RegExp(r'\s+'), ' '),
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
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Not now'),
              ),
              FilledButton(
                onPressed: saving ? null : onSave,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
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

class _PreviewIcon extends StatelessWidget {
  const _PreviewIcon({
    required this.imageUrl,
    required this.icon,
    required this.color,
  });

  final String? imageUrl;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color),
    );
    if (imageUrl == null) return fallback;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

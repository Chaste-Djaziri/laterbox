import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/desktop/clipboard_capture_service.dart';
import '../../../core/enrichment/enrichment_providers.dart';
import '../domain/capture_payload.dart';
import '../domain/capture_providers.dart';
import 'ios_notch_companion_controller.dart';

typedef ClipboardTextReader = Future<String?> Function();

/// Interactive Dynamic Island & Notch companion overlay for iOS.
///
/// Features:
/// 1. Prompts the user when external copied content is detected upon returning to the app,
///    allowing them to choose when to return the item (Inbox, Later today, Tomorrow, etc.).
/// 2. Confirms saved items and share receipts directly from the Dynamic Island / Notch
///    with animated checkmark and scheduled return time.
/// 3. Adapts dynamically to Dynamic Island cutouts, camera notches, and standard screens.
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

  String? _lastHandledValue;
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
    final companionState = ref.read(iosNotchCompanionProvider);
    if (!_isIos || companionState is! IosNotchIdle) return;
    final value = (await _readClipboard())?.trim();
    if (!mounted ||
        value == null ||
        value.isEmpty ||
        value == _lastHandledValue) {
      return;
    }
    _lastHandledValue = value;
    ref.read(iosNotchCompanionProvider.notifier).showClipboardPrompt(value);
    _loadMetadata(value);
  }

  Future<void> _loadMetadata(String value) async {
    if (!ClipboardCaptureService.isUrl(value)) return;
    final remote = ref.read(remoteMetadataDataSourceProvider);
    if (remote == null) return;
    try {
      final metadata = await remote.fetch(value);
      if (mounted) {
        ref
            .read(iosNotchCompanionProvider.notifier)
            .updatePromptMetadata(metadata);
      }
    } catch (_) {
      // Offline or metadata unavailable
    }
  }

  Future<void> _savePrompt(IosNotchClipboardPrompt prompt) async {
    final notifier = ref.read(iosNotchCompanionProvider.notifier);
    notifier.setPromptSaving(true);
    try {
      final payload = CapturePayload.fromValue(
        prompt.value,
        returnAt: prompt.selectedReturnAt,
        source: CaptureSource.iosShare,
      );
      await ref.read(captureServiceProvider).save(payload);
      if (!mounted) return;
      final displayTitle = prompt.metadata?.title?.trim().isNotEmpty == true
          ? prompt.metadata!.title!.trim()
          : (ClipboardCaptureService.isUrl(prompt.value)
              ? Uri.tryParse(prompt.value)?.host ?? 'Saved link'
              : 'Saved note');
      notifier.showSavedConfirmation(
        title: 'Saved to LaterBox',
        subtitle: displayTitle,
        returnAt: prompt.selectedReturnAt,
      );
    } catch (err) {
      if (mounted) {
        notifier.showError('Could not save item: $err');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isIos) return widget.child;
    final notchState = ref.watch(iosNotchCompanionProvider);
    final topPadding = MediaQuery.paddingOf(context).top;
    final isVisible = notchState is! IosNotchIdle;

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: topPadding >= 51
              ? 10.0
              : (topPadding >= 40 ? 0.0 : topPadding + 6.0),
          left: 14,
          right: 14,
          child: AnimatedSlide(
            offset: isVisible ? Offset.zero : const Offset(0, -1.2),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: _DynamicIslandCard(
                state: notchState,
                topPadding: topPadding,
                onSavePrompt: _savePrompt,
                onDismiss: () =>
                    ref.read(iosNotchCompanionProvider.notifier).dismiss(),
                onSelectReturnAt: (date) => ref
                    .read(iosNotchCompanionProvider.notifier)
                    .updatePromptReturnAt(date),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DynamicIslandCard extends StatelessWidget {
  const _DynamicIslandCard({
    required this.state,
    required this.topPadding,
    required this.onSavePrompt,
    required this.onDismiss,
    required this.onSelectReturnAt,
  });

  final IosNotchState state;
  final double topPadding;
  final ValueChanged<IosNotchClipboardPrompt> onSavePrompt;
  final VoidCallback onDismiss;
  final ValueChanged<DateTime?> onSelectReturnAt;

  @override
  Widget build(BuildContext context) {
    final borderRadius = topPadding >= 51
        ? BorderRadius.circular(28)
        : (topPadding >= 40
            ? const BorderRadius.vertical(bottom: Radius.circular(22))
            : BorderRadius.circular(20));

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF09090B),
          borderRadius: borderRadius,
          border: Border.all(color: const Color(0x28FFFFFF), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: switch (state) {
          IosNotchClipboardPrompt prompt => _buildPrompt(context, prompt),
          IosNotchSavedConfirmation saved => _buildSaved(context, saved),
          IosNotchError err => _buildError(context, err),
          IosNotchIdle() => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _buildPrompt(BuildContext context, IosNotchClipboardPrompt prompt) {
    final isLink = ClipboardCaptureService.isUrl(prompt.value);
    final title = prompt.metadata?.title?.trim().isNotEmpty == true
        ? prompt.metadata!.title!.trim()
        : 'Save copied item?';
    final domain = prompt.metadata?.siteName?.trim() ??
        prompt.metadata?.domain?.trim() ??
        (isLink
            ? Uri.tryParse(prompt.value)?.host.replaceFirst(RegExp(r'^www\.'), '')
            : prompt.value.replaceAll(RegExp(r'\s+'), ' '));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFE6EDB0).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isLink ? Icons.link_rounded : Icons.content_paste_rounded,
                color: const Color(0xFFE6EDB0),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    domain ?? prompt.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9E9B92),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 10),
        // When Preset Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _WhenChip(
                label: 'Inbox',
                isSelected: prompt.selectedReturnAt == null,
                onTap: () => onSelectReturnAt(null),
              ),
              const SizedBox(width: 6),
              _WhenChip(
                label: 'Later today',
                isSelected: prompt.selectedReturnAt != null &&
                    _isSameDay(prompt.selectedReturnAt!, DateTime.now()),
                onTap: () {
                  final now = DateTime.now();
                  final target = now.hour < 18
                      ? DateTime(now.year, now.month, now.day, 18, 0)
                      : now.add(const Duration(hours: 3));
                  onSelectReturnAt(target);
                },
              ),
              const SizedBox(width: 6),
              _WhenChip(
                label: 'Tomorrow',
                isSelected: prompt.selectedReturnAt != null &&
                    _isTomorrow(prompt.selectedReturnAt!),
                onTap: () {
                  final tomorrow = DateTime.now().add(const Duration(days: 1));
                  onSelectReturnAt(
                      DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0));
                },
              ),
              const SizedBox(width: 6),
              _WhenChip(
                label: 'Weekend',
                isSelected: prompt.selectedReturnAt != null &&
                    _isWeekend(prompt.selectedReturnAt!),
                onTap: () {
                  final now = DateTime.now();
                  final daysUntilSat = (6 - now.weekday + 7) % 7;
                  final days = daysUntilSat == 0 ? 7 : daysUntilSat;
                  final sat = now.add(Duration(days: days));
                  onSelectReturnAt(
                      DateTime(sat.year, sat.month, sat.day, 9, 0));
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Action Button Row
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: prompt.saving ? null : onDismiss,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Not now'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: prompt.saving ? null : () => onSavePrompt(prompt),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE6EDB0),
                foregroundColor: const Color(0xFF171711),
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: prompt.saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF171711),
                      ),
                    )
                  : const Icon(Icons.bookmark_add_rounded, size: 16),
              label: Text(
                prompt.saving ? 'Saving…' : 'Save to LaterBox',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSaved(BuildContext context, IosNotchSavedConfirmation saved) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFE6EDB0),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF171711),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    saved.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (saved.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      saved.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9E9B92),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (saved.returnAt != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFFE6EDB0),
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatReturnTag(saved.returnAt!),
                      style: const TextStyle(
                        color: Color(0xFFE6EDB0),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Countdown indicator
        Container(
          height: 2,
          decoration: BoxDecoration(
            color: const Color(0xFFE6EDB0).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, IosNotchError err) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.redAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Couldn't save item",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                err.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onDismiss,
          icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
        ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _isTomorrow(DateTime d) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return _isSameDay(d, tomorrow);
  }

  static bool _isWeekend(DateTime d) =>
      d.weekday == DateTime.saturday || d.weekday == DateTime.sunday;

  static String _formatReturnTag(DateTime d) {
    final now = DateTime.now();
    if (_isSameDay(d, now)) return 'Today';
    if (_isTomorrow(d)) return 'Tomorrow';
    return '${d.month}/${d.day}';
  }
}

class _WhenChip extends StatelessWidget {
  const _WhenChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFE6EDB0)
                : const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF171711) : Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}


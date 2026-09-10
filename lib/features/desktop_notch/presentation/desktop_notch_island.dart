import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/desktop/desktop_notch_service.dart';
import '../../../core/desktop/desktop_providers.dart';
import '../../../core/desktop/screen_watcher_service.dart';
import '../../../core/theme/app_theme.dart';

/// Floating Dynamic Island / Notch component for macOS (DEBUG-ONLY preview).
///
/// Production macOS uses the native `NotchPanelController` NSPanel (see
/// `macos/Runner/NotchPanelController.swift`) as the flagship capture surface
/// so the pill never covers menu-bar controls and survives every display shape.
/// This Flutter widget is retained only for `flutter run -d macos` previews
/// and widget tests — it renders nothing in release/profile.
class DesktopNotchIsland extends ConsumerStatefulWidget {
  const DesktopNotchIsland({super.key});

  @override
  ConsumerState<DesktopNotchIsland> createState() => _DesktopNotchIslandState();
}

class _DesktopNotchIslandState extends ConsumerState<DesktopNotchIsland>
    with SingleTickerProviderStateMixin {
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _collapseTimer;
  bool _isHovered = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Ensure screen watcher is actively polling when notch is displayed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(screenWatcherServiceProvider).startWatching();
    });
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    _noteController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    _collapseTimer?.cancel();
    setState(() => _isHovered = true);
    final notchService = ref.read(desktopNotchServiceProvider);
    if (!notchService.isIslandExpanded) {
      notchService.expandIsland();
    }
  }

  void _onHoverExit() {
    setState(() => _isHovered = false);
    _collapseTimer?.cancel();
    _collapseTimer = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_focusNode.hasFocus || _isSaving) return;
      final notchService = ref.read(desktopNotchServiceProvider);
      if (notchService.isIslandExpanded) {
        notchService.collapseToPill();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Flagship notch is the native NSPanel. Avoid duplicate UI in production
    // where the Dart island would fight the panel for hover and focus.
    if (kReleaseMode) return const SizedBox.shrink();
    assert(() {
      // In debug/profile we keep the island visible for quick iteration.
      return true;
    }());
    final notchService = ref.watch(desktopNotchServiceProvider);
    final watcher = ref.watch(screenWatcherServiceProvider);
    final isExpanded = notchService.isIslandExpanded;

    final borderRadius = isExpanded
        ? const BorderRadius.vertical(bottom: Radius.circular(22))
        : const BorderRadius.vertical(bottom: Radius.circular(18));

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.topCenter,
        child: MouseRegion(
          onEnter: (_) => _onHoverEnter(),
          onExit: (_) => _onHoverExit(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: isExpanded ? 540 : 280,
            height: isExpanded ? 250 : 40,
            decoration: BoxDecoration(
              color: const Color(0xFF000000).withValues(alpha: 0.98),
              borderRadius: borderRadius,
              border: Border.all(
                color: _isHovered
                    ? AppTheme.accent.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.14),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: isExpanded ? 28 : 12,
                  offset: const Offset(0, 6),
                  spreadRadius: 1,
                ),
                if (_isHovered)
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.12),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: isExpanded
                    ? _buildExpandedIsland(context, notchService, watcher)
                    : _buildCollapsedPill(context, notchService, watcher),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedPill(
    BuildContext context,
    DesktopNotchService notchService,
    ScreenWatcherService watcher,
  ) {
    final contextData = watcher.currentContext;
    final appName = contextData?.frontmostApp ?? 'Finder';
    final hasLink = watcher.hasActiveLink;
    final hasSelected = watcher.hasSelectedText;
    final status = watcher.statusMessage;

    return InkWell(
      onTap: () => notchService.expandIsland(),
      borderRadius: BorderRadius.circular(22),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            // Glowing LaterBox Logo Dot
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accent.withValues(alpha: 0.8),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Active App / Status
            Expanded(
              child: Text(
                status ??
                    (hasSelected
                        ? 'Quote: "${_truncate(contextData!.selectedText!, 18)}"'
                        : (hasLink ? 'Tab: ${_truncate(contextData!.activeTitle ?? appName, 18)}' : appName)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),

            // Quick Save Action Icon (if link or selection is ready)
            if (hasSelected || hasLink)
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                padding: EdgeInsets.zero,
                tooltip: hasSelected ? 'Save Word Reference' : 'Save Active Link',
                icon: Icon(
                  hasSelected ? Icons.format_quote_rounded : Icons.bookmark_add_outlined,
                  color: AppTheme.accent,
                ),
                onPressed: () async {
                  if (hasSelected) {
                    await watcher.saveSelectedWordReference();
                  } else if (hasLink) {
                    await watcher.saveActiveLink();
                  }
                },
              ),

            // Expand Chevron
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white.withValues(alpha: 0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedIsland(
    BuildContext context,
    DesktopNotchService notchService,
    ScreenWatcherService watcher,
  ) {
    final contextData = watcher.currentContext;
    final appName = contextData?.frontmostApp ?? 'Screen';
    final hasLink = watcher.hasActiveLink;
    final hasSelected = watcher.hasSelectedText;
    final status = watcher.statusMessage;

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Control Bar
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      appName.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              if (status != null)
                Text(
                  status,
                  style: TextStyle(
                    color: status.contains('Failed')
                        ? Colors.redAccent
                        : const Color(0xFF68D391),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),

              const Spacer(),

              // Quick Refresh
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                padding: EdgeInsets.zero,
                tooltip: 'Refresh screen context',
                icon: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: 0.6)),
                onPressed: () => watcher.pollNow(),
              ),

              // Open Full App Window
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                padding: EdgeInsets.zero,
                tooltip: 'Open full LaterBox',
                icon: Icon(Icons.open_in_full_rounded, color: Colors.white.withValues(alpha: 0.6)),
                onPressed: () => notchService.expandToFullWindow(),
              ),

              // Collapse back to Pill
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 16,
                padding: EdgeInsets.zero,
                tooltip: 'Collapse to notch pill',
                icon: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white.withValues(alpha: 0.6)),
                onPressed: () => notchService.collapseToPill(),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Context Highlights & Word Reference Section
          Expanded(
            child: Row(
              children: [
                // Active Link Card
                Expanded(
                  child: _buildContextCard(
                    icon: Icons.link_rounded,
                    title: hasLink ? (contextData?.activeTitle ?? 'Active Tab') : 'Active Browser Tab',
                    subtitle: hasLink ? (contextData?.activeUrl ?? '') : 'Open Safari, Chrome, or Arc',
                    actionLabel: 'Save Link',
                    isEnabled: hasLink && !_isSaving,
                    onAction: () async {
                      setState(() => _isSaving = true);
                      await watcher.saveActiveLink(note: _noteController.text);
                      _noteController.clear();
                      setState(() => _isSaving = false);
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // Selected Word / Reference Highlight Card
                Expanded(
                  child: _buildContextCard(
                    icon: Icons.format_quote_rounded,
                    title: hasSelected ? 'Selected Reference' : 'Word Reference',
                    subtitle: hasSelected
                        ? '"${contextData!.selectedText!}"'
                        : 'Select any words on screen to capture highlight link',
                    actionLabel: 'Save Reference',
                    isEnabled: hasSelected && !_isSaving,
                    accentColor: AppTheme.accent,
                    onAction: () async {
                      setState(() => _isSaving = true);
                      await watcher.saveSelectedWordReference(note: _noteController.text);
                      _noteController.clear();
                      setState(() => _isSaving = false);
                    },
                    secondaryAction: hasSelected && contextData?.highlightUrl != null
                        ? () {
                            Clipboard.setData(ClipboardData(text: contextData!.highlightUrl!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied highlight link (#:~:text=...) to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Quick Note Input / Drop zone
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: TextField(
                    controller: _noteController,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Add note or paste reference... (Press Enter)',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 12,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    onSubmitted: (text) async {
                      if (text.trim().isEmpty) return;
                      await watcher.saveContent(text);
                      _noteController.clear();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: const Color(0xFF0C0C0E),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  minimumSize: const Size(0, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final text = _noteController.text.trim();
                  if (text.isNotEmpty) {
                    await watcher.saveContent(text);
                    _noteController.clear();
                  } else if (hasSelected) {
                    await watcher.saveSelectedWordReference();
                  } else if (hasLink) {
                    await watcher.saveActiveLink();
                  }
                },
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required bool isEnabled,
    required VoidCallback onAction,
    VoidCallback? secondaryAction,
    Color? accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isEnabled
              ? (accentColor ?? Colors.white).withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: isEnabled ? (accentColor ?? AppTheme.accent) : Colors.white38,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (secondaryAction != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 14,
                  padding: EdgeInsets.zero,
                  tooltip: 'Copy highlight link',
                  icon: const Icon(Icons.copy_rounded, color: Colors.white54),
                  onPressed: secondaryAction,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isEnabled ? Colors.white70 : Colors.white30,
                fontSize: 10.5,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 26,
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isEnabled ? Colors.white : Colors.white24,
                side: BorderSide(
                  color: isEnabled
                      ? (accentColor ?? AppTheme.accent).withValues(alpha: 0.6)
                      : Colors.white12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: isEnabled ? onAction : null,
              child: Text(
                actionLabel,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isEnabled ? (accentColor ?? AppTheme.accent) : Colors.white24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truncate(String text, int max) {
    final clean = text.replaceAll('\n', ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max)}…';
  }
}

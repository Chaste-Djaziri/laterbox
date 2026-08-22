import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'web_update_service.dart';

class WebUpdateBannerOverlay extends ConsumerWidget {
  const WebUpdateBannerOverlay({
    super.key,
    required this.child,
    this.enabled,
  });

  final Widget child;
  final bool? enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = enabled ?? kIsWeb;
    if (!isEnabled) return child;

    final updateState = ref.watch(webUpdateProvider);

    return Stack(
      children: [
        child,
        Positioned(
          bottom: 24,
          right: 24,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.4),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: updateState.shouldShowBanner
                ? _WebUpdateCard(key: const ValueKey('update_banner'), state: updateState)
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ],
    );
  }
}

class _WebUpdateCard extends ConsumerWidget {
  const _WebUpdateCard({
    super.key,
    required this.state,
  });

  final WebUpdateState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(webUpdateProvider.notifier);

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 360,
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF171711),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7FF57),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.autorenew_rounded,
                      color: Color(0xFF171711),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Update available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Color(0xFFA1A19A)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  splashRadius: 16,
                  onPressed: () => notifier.dismiss(),
                  tooltip: 'Dismiss',
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'A new version of laterbox has been deployed. Reload now to apply the latest updates without cache.',
              style: TextStyle(
                color: Color(0xFFC7C6BC),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: state.isReloading ? null : () => notifier.dismiss(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFA1A19A),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Later'),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FilledButton.icon(
                    onPressed: state.isReloading
                        ? null
                        : () => notifier.reloadAndApplyUpdate(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE7FF57),
                      foregroundColor: const Color(0xFF171711),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: state.isReloading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF171711),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      state.isReloading ? 'Updating...' : 'Reload & update',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

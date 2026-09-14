import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ios_app_store_update_service.dart';

class IosAppStoreUpdateOverlay extends ConsumerWidget {
  const IosAppStoreUpdateOverlay({required this.child, super.key});

  final Widget child;

  bool get _isIos => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isIos) return child;
    final update = ref.watch(iosAppStoreUpdateProvider);
    return Stack(
      children: [
        child,
        Positioned(
          left: 20,
          right: 20,
          bottom: MediaQuery.paddingOf(context).bottom + 20,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.2),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: update.shouldShow
                ? _UpdateCard(
                    key: const ValueKey('ios-app-store-update'),
                    latestVersion: update.latestVersion!,
                    storeUrl: update.storeUrl,
                  )
                : const SizedBox.shrink(
                    key: ValueKey('no-ios-app-store-update'),
                  ),
          ),
        ),
      ],
    );
  }
}

class _UpdateCard extends ConsumerWidget {
  const _UpdateCard({
    required this.latestVersion,
    required this.storeUrl,
    super.key,
  });

  final String latestVersion;
  final String storeUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
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
          padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
          child: Row(
            children: [
              Icon(
                Icons.system_update_rounded,
                color: theme.colorScheme.onInverseSurface,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update available',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'LaterBox $latestVersion is ready on the App Store.',
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
                onPressed: () =>
                    ref.read(iosAppStoreUpdateProvider.notifier).dismiss(),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Later'),
              ),
              FilledButton(
                onPressed: () async {
                  final opened = await launchUrl(
                    Uri.parse(storeUrl),
                    mode: LaunchMode.externalApplication,
                  );
                  if (opened) {
                    ref.read(iosAppStoreUpdateProvider.notifier).dismiss();
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

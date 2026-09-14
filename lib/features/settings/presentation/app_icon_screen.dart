import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_icon/app_icon_providers.dart';
import '../../../core/app_icon/app_icon_service.dart';

/// Dedicated screen for browsing and selecting iOS alternate app icons.
class AppIconScreen extends ConsumerWidget {
  const AppIconScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentIconAsync = ref.watch(currentAppIconProvider);
    final activeId = currentIconAsync.valueOrNull;
    final isSupportedAsync = ref.watch(appIconSupportedProvider);
    final isSupported = isSupportedAsync.valueOrNull ??
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

    final currentOption = AppIconOption.fromId(activeId);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'App Icon',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Hero active icon preview
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.asset(
                        currentOption.assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: colors.surfaceContainerHighest,
                          child: Icon(
                            Icons.apps_rounded,
                            size: 48,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentOption.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentOption.subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Current Home Screen Icon',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Available Variants',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            // Variants list
            ...AppIconOption.all.map((option) {
              final isSelected = (option.id == activeId) ||
                  (option.id == null && activeId == null);
              final isLoading = currentIconAsync.isLoading;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _VariantCard(
                  option: option,
                  isSelected: isSelected,
                  isLoading: isLoading,
                  onTap: () async {
                    if (isSelected || isLoading) return;
                    HapticFeedback.selectionClick();
                    if (!isSupported) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'App icon switching is supported on iOS devices.',
                          ),
                        ),
                      );
                      return;
                    }
                    final success = await ref
                        .read(currentAppIconProvider.notifier)
                        .selectIcon(option.id);
                    if (!context.mounted) return;
                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not change app icon to ${option.name}.',
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            }),
            const SizedBox(height: 16),
            // Platform footnote
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'iOS will display a system confirmation when switching app icons. Alternate icons update across your Home Screen, App Library, and App Switcher.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _VariantCard extends StatelessWidget {
  const _VariantCard({
    required this.option,
    required this.isSelected,
    required this.isLoading,
    required this.onTap,
  });

  final AppIconOption option;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${option.name} app icon, ${option.subtitle}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.08)
                  : colors.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.6)
                    : colors.outlineVariant.withValues(alpha: 0.6),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.asset(
                      option.assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: colors.surfaceContainerHighest,
                        child: Icon(
                          Icons.apps_rounded,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                          color: isSelected ? colors.primary : colors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? colors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : colors.outlineVariant,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: colors.onPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/database/app_database.dart';
import '../../core/sync/sync_providers.dart';
import '../../core/sync/sync_stats_provider.dart';

class CloudSyncIndicator extends ConsumerWidget {
  const CloudSyncIndicator({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).asData?.value;
    final isAuthenticated = auth?.isAuthenticated ?? false;
    final statsAsync = ref.watch(syncStatsProvider);

    final stats = statsAsync.asData?.value ??
        const SyncStatsData(
          totalItems: 0,
          pendingItems: 0,
          totalAttachments: 0,
          pendingAttachments: 0,
        );

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final isSyncing = stats.pendingCount > 0;

    final IconData icon;
    final Color backgroundColor;
    final Color foregroundColor;
    final String labelText;

    if (!isAuthenticated) {
      icon = Icons.cloud_off_rounded;
      backgroundColor = colors.surfaceContainerHighest;
      foregroundColor = colors.onSurfaceVariant;
      labelText = compact ? 'Local' : 'Local Mode';
    } else if (isSyncing) {
      icon = Icons.cloud_sync_rounded;
      backgroundColor = colors.primaryContainer;
      foregroundColor = colors.onPrimaryContainer;
      labelText = 'Syncing ${stats.percentage}%';
    } else {
      icon = Icons.cloud_done_rounded;
      backgroundColor = colors.secondaryContainer.withValues(alpha: 0.8);
      foregroundColor = colors.onSecondaryContainer;
      labelText = compact ? '${stats.percentage}%' : 'Synced ${stats.percentage}%';
    }

    return Semantics(
      button: true,
      label: 'Cloud Sync Status: $labelText',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => showCloudSyncDetailSheet(context, ref),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: foregroundColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSyncing)
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    value:
                        stats.totalCount > 0 ? stats.progressFraction : null,
                    strokeWidth: 2,
                    color: foregroundColor,
                  ),
                )
              else
                Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                labelText,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showCloudSyncDetailSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _CloudSyncDetailSheet(),
  );
}

class _CloudSyncDetailSheet extends ConsumerWidget {
  const _CloudSyncDetailSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final auth = ref.watch(authStateProvider).asData?.value;
    final isAuthenticated = auth?.isAuthenticated ?? false;
    final statsAsync = ref.watch(syncStatsProvider);

    final stats = statsAsync.asData?.value ??
        const SyncStatsData(
          totalItems: 0,
          pendingItems: 0,
          totalAttachments: 0,
          pendingAttachments: 0,
        );

    final isSyncing = stats.pendingCount > 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSyncing
                        ? colors.primaryContainer
                        : colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isSyncing
                        ? Icons.cloud_sync_rounded
                        : Icons.cloud_done_rounded,
                    size: 28,
                    color: isSyncing
                        ? colors.onPrimaryContainer
                        : colors.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cloud Sync & Backup',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAuthenticated
                            ? (isSyncing
                                ? 'Syncing changes to cloud...'
                                : 'All items backed up to cloud')
                            : 'Guest mode — local storage only',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sync Progress',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${stats.percentage}%',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: stats.progressFraction,
                      minHeight: 10,
                      backgroundColor: colors.surfaceContainerHighest,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  _StatRow(
                    label: 'Items Synced',
                    value:
                        '${stats.totalItems - stats.pendingItems} of ${stats.totalItems}',
                    icon: Icons.article_outlined,
                  ),
                  const SizedBox(height: 12),
                  _StatRow(
                    label: 'Attachments Synced',
                    value:
                        '${stats.totalAttachments - stats.pendingAttachments} of ${stats.totalAttachments}',
                    icon: Icons.attach_file_rounded,
                  ),
                  if (stats.pendingCount > 0) ...[
                    const SizedBox(height: 12),
                    _StatRow(
                      label: 'Pending Sync',
                      value: '${stats.pendingCount} items/files',
                      icon: Icons.pending_actions_rounded,
                      valueColor: colors.tertiary,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await ref.read(syncCoordinatorProvider).syncNow();
                },
                icon: const Icon(Icons.sync_rounded),
                label: const Text('Sync Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

import 'entitlement.dart';

enum EntitlementSeverity { neutral, success, warning }

class EntitlementPresentation {
  const EntitlementPresentation({
    required this.label,
    required this.description,
    required this.actionLabel,
    required this.severity,
    this.remainingDays,
    this.progress,
  });

  final String label;
  final String description;
  final String actionLabel;
  final EntitlementSeverity severity;
  final int? remainingDays;
  final double? progress;

  factory EntitlementPresentation.from(
    Entitlement entitlement, {
    DateTime? now,
  }) {
    final current = (now ?? DateTime.now()).toUtc();
    final end = entitlement.phaseEndsAt ?? entitlement.accessEndsAt;
    final remaining = end == null
        ? null
        : end.difference(current).inSeconds <= 0
        ? 0
        : (end.difference(current).inSeconds / Duration.secondsPerDay).ceil();
    final start = entitlement.phaseStartsAt;
    double? progress;
    if (start != null && end != null && end.isAfter(start)) {
      progress = current.difference(start).inMilliseconds /
          end.difference(start).inMilliseconds;
      progress = progress.clamp(0, 1);
    }
    final time = remaining == null
        ? ''
        : remaining == 0
        ? 'Ends today'
        : '$remaining day${remaining == 1 ? '' : 's'} left';

    final hasAccess = entitlement.tier == EntitlementTier.pro &&
        (entitlement.accessEndsAt == null ||
            entitlement.accessEndsAt!.isAfter(current));
    if (!hasAccess) {
      return const EntitlementPresentation(
        label: 'Free',
        description: 'Local saving, reading, search, organization, and export.',
        actionLabel: 'View plans',
        severity: EntitlementSeverity.neutral,
      );
    }
    if (entitlement.status == EntitlementStatus.pastDue) {
      return EntitlementPresentation(
        label: 'Grace period${time.isEmpty ? '' : ' · $time'}',
        description: 'Update your payment method to keep Pro active.',
        actionLabel: 'Fix payment',
        severity: EntitlementSeverity.warning,
        remainingDays: remaining,
        progress: progress,
      );
    }
    if (entitlement.status == EntitlementStatus.trialing) {
      return EntitlementPresentation(
        label: 'Pro trial${time.isEmpty ? '' : ' · $time'}',
        description: 'All connected features are available during your trial.',
        actionLabel: 'Manage',
        severity: EntitlementSeverity.success,
        remainingDays: remaining,
        progress: progress,
      );
    }
    if (entitlement.status == EntitlementStatus.granted) {
      return EntitlementPresentation(
        label: 'Launch Pro${time.isEmpty ? '' : ' · $time'}',
        description: 'Temporary launch access includes all Pro features.',
        actionLabel: 'View plans',
        severity: EntitlementSeverity.success,
        remainingDays: remaining,
        progress: progress,
      );
    }
    if (entitlement.willCancel) {
      return EntitlementPresentation(
        label: 'Pro${time.isEmpty ? '' : ' · $time'}',
        description: 'Your plan stays active until the end of this period.',
        actionLabel: 'Manage',
        severity: EntitlementSeverity.warning,
        remainingDays: remaining,
        progress: progress,
      );
    }
    return const EntitlementPresentation(
      label: 'Pro',
      description: 'Sync, cloud attachments, integrations, and automation are active.',
      actionLabel: 'Manage',
      severity: EntitlementSeverity.success,
    );
  }
}

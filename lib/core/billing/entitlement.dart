enum EntitlementTier { free, pro }

enum EntitlementStatus {
  free,
  granted,
  trialing,
  active,
  pastDue,
  paused,
  canceled,
}

class Entitlement {
  const Entitlement({
    required this.tier,
    required this.status,
    this.provider,
    this.trialEndsAt,
    this.accessEndsAt,
    this.willCancel = false,
    this.billingWarning,
    this.phaseStartsAt,
    this.phaseEndsAt,
  });

  const Entitlement.free()
    : tier = EntitlementTier.free,
      status = EntitlementStatus.free,
      provider = null,
      trialEndsAt = null,
      accessEndsAt = null,
      willCancel = false,
      billingWarning = null,
      phaseStartsAt = null,
      phaseEndsAt = null;

  final EntitlementTier tier;
  final EntitlementStatus status;
  final String? provider;
  final DateTime? trialEndsAt;
  final DateTime? accessEndsAt;
  final bool willCancel;
  final String? billingWarning;
  final DateTime? phaseStartsAt;
  final DateTime? phaseEndsAt;

  bool get hasProAccess =>
      tier == EntitlementTier.pro &&
      (accessEndsAt == null || accessEndsAt!.isAfter(DateTime.now().toUtc()));

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final value = json[key] as String?;
      return value == null ? null : DateTime.tryParse(value)?.toUtc();
    }

    final rawStatus = (json['status'] as String? ?? 'free').replaceAll('_', '');
    final status = EntitlementStatus.values.firstWhere(
      (value) => value.name.toLowerCase() == rawStatus.toLowerCase(),
      orElse: () => EntitlementStatus.free,
    );
    return Entitlement(
      tier: json['tier'] == 'pro' ? EntitlementTier.pro : EntitlementTier.free,
      status: status,
      provider: json['provider'] as String?,
      trialEndsAt: date('trialEndsAt'),
      accessEndsAt: date('accessEndsAt'),
      willCancel: json['willCancel'] as bool? ?? false,
      billingWarning: json['billingWarning'] as String?,
      phaseStartsAt: date('phaseStartsAt'),
      phaseEndsAt: date('phaseEndsAt'),
    );
  }

  Map<String, dynamic> toJson() => {
    'tier': tier.name,
    'status': status == EntitlementStatus.pastDue ? 'past_due' : status.name,
    'provider': provider,
    'trialEndsAt': trialEndsAt?.toIso8601String(),
    'accessEndsAt': accessEndsAt?.toIso8601String(),
    'willCancel': willCancel,
    'billingWarning': billingWarning,
    'phaseStartsAt': phaseStartsAt?.toIso8601String(),
    'phaseEndsAt': phaseEndsAt?.toIso8601String(),
  };
}

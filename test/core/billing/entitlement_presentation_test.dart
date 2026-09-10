import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/billing/entitlement.dart';
import 'package:laterbox/core/billing/entitlement_presentation.dart';

void main() {
  final now = DateTime.utc(2026, 9, 10, 12);

  test('free entitlement presents an upgrade action', () {
    final value = EntitlementPresentation.from(const Entitlement.free(), now: now);
    expect(value.label, 'Free');
    expect(value.actionLabel, 'View plans');
    expect(value.progress, isNull);
  });

  test('trial reports ceiling days and clamped progress', () {
    final value = EntitlementPresentation.from(
      Entitlement(
        tier: EntitlementTier.pro,
        status: EntitlementStatus.trialing,
        trialEndsAt: now.add(const Duration(hours: 49)),
        accessEndsAt: now.add(const Duration(hours: 49)),
        phaseStartsAt: now.subtract(const Duration(hours: 49)),
        phaseEndsAt: now.add(const Duration(hours: 49)),
      ),
      now: now,
    );
    expect(value.label, 'Pro trial · 3 days left');
    expect(value.progress, closeTo(0.5, 0.001));
  });

  test('past due access remains a visible warning', () {
    final value = EntitlementPresentation.from(
      Entitlement(
        tier: EntitlementTier.pro,
        status: EntitlementStatus.pastDue,
        accessEndsAt: now.add(const Duration(hours: 12)),
        phaseStartsAt: now.subtract(const Duration(days: 6)),
        phaseEndsAt: now.add(const Duration(hours: 12)),
        billingWarning: 'payment_past_due',
      ),
      now: now,
    );
    expect(value.label, 'Grace period · 1 day left');
    expect(value.actionLabel, 'Fix payment');
    expect(value.severity, EntitlementSeverity.warning);
  });

  test('expired entitlement presents as free', () {
    final value = EntitlementPresentation.from(
      Entitlement(
        tier: EntitlementTier.pro,
        status: EntitlementStatus.canceled,
        accessEndsAt: now.subtract(const Duration(seconds: 1)),
      ),
      now: now,
    );
    expect(value.label, 'Free');
  });
}

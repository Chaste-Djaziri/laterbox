import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/billing/entitlement.dart';

void main() {
  group('Entitlement', () {
    test('free entitlement never grants Pro', () {
      expect(const Entitlement.free().hasProAccess, isFalse);
    });

    test('maps past_due and preserves warning state', () {
      final entitlement = Entitlement.fromJson({
        'tier': 'pro',
        'status': 'past_due',
        'provider': 'paddle',
        'accessEndsAt': DateTime.now().toUtc().add(const Duration(days: 2)).toIso8601String(),
        'willCancel': false,
        'billingWarning': 'payment_past_due',
      });

      expect(entitlement.status, EntitlementStatus.pastDue);
      expect(entitlement.hasProAccess, isTrue);
      expect(entitlement.billingWarning, 'payment_past_due');
    });

    test('expired cached entitlement does not extend access', () {
      final entitlement = Entitlement.fromJson({
        'tier': 'pro',
        'status': 'active',
        'provider': 'paddle',
        'accessEndsAt': DateTime.now().toUtc().subtract(const Duration(minutes: 1)).toIso8601String(),
      });

      expect(entitlement.hasProAccess, isFalse);
    });

    test('scheduled cancellation keeps access until period end', () {
      final entitlement = Entitlement.fromJson({
        'tier': 'pro',
        'status': 'active',
        'provider': 'paddle',
        'accessEndsAt': DateTime.now().toUtc().add(const Duration(days: 10)).toIso8601String(),
        'willCancel': true,
      });

      expect(entitlement.hasProAccess, isTrue);
      expect(entitlement.willCancel, isTrue);
    });
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/billing/billing_providers.dart';

void main() {
  test('uses StoreKit for an iOS App Store build', () {
    expect(
      isAppleStoreDistribution(
        distribution: 'app-store',
        platform: TargetPlatform.iOS,
        isWeb: false,
      ),
      isTrue,
    );
  });

  test('does not use StoreKit for a direct iOS build', () {
    expect(
      isAppleStoreDistribution(
        distribution: 'direct',
        platform: TargetPlatform.iOS,
        isWeb: false,
      ),
      isFalse,
    );
  });
}

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../supabase/supabase_provider.dart';
import 'entitlement.dart';
import 'entitlement_repository.dart';
import 'apple_purchase_service.dart';

enum ProFeature {
  cloudSync,
  cloudAttachments,
  shareIntegration,
  clipboardCapture,
  watchMode,
  automatedCapture,
}

const laterBoxDistribution = String.fromEnvironment(
  'LATERBOX_DISTRIBUTION',
  defaultValue: 'direct',
);

bool get billingEnforcementEnabled {
  return true;
}

bool isAppleStoreDistribution({
  String distribution = laterBoxDistribution,
  TargetPlatform? platform,
  bool isWeb = kIsWeb,
}) {
  final target = platform ?? defaultTargetPlatform;
  return !isWeb &&
      distribution == 'app-store' &&
      (target == TargetPlatform.iOS || target == TargetPlatform.macOS);
}

bool get isAppleAppStoreBuild => isAppleStoreDistribution();

bool get canOpenWebCheckout {
  if (kIsWeb ||
      laterBoxDistribution == 'play' ||
      laterBoxDistribution == 'app-store') {
    return false;
  }
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

final entitlementRepositoryProvider = Provider<EntitlementRepository>((ref) {
  return EntitlementRepository(ref.watch(supabaseClientProvider));
});

final applePurchaseServiceProvider =
    ChangeNotifierProvider<ApplePurchaseService>((ref) {
      final service = ApplePurchaseService(
        ref.watch(supabaseClientProvider),
        onVerified: () => ref.invalidate(entitlementProvider),
      );
      service.initialize();
      return service;
    });

final entitlementProvider = FutureProvider<Entitlement>((ref) async {
  ref.watch(authStateProvider);
  return ref.watch(entitlementRepositoryProvider).load();
});

final hasProAccessProvider = Provider<bool>((ref) {
  if (!billingEnforcementEnabled) return true;
  return ref.watch(entitlementProvider).valueOrNull?.hasProAccess ?? false;
});

final proFeatureAccessProvider = Provider.family<bool, ProFeature>((
  ref,
  feature,
) {
  return ref.watch(hasProAccessProvider);
});

void refreshEntitlement(WidgetRef ref) {
  ref.invalidate(entitlementProvider);
}

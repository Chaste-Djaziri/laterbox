import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const appleMonthlyProductId = 'com.laterbox.pro.monthly';
const appleAnnualProductId = 'com.laterbox.pro.annual';
const appleProductIds = <String>{appleMonthlyProductId, appleAnnualProductId};

enum ApplePurchaseState { unavailable, loading, ready, pending, verifying, failed }

class ApplePurchaseCatalog {
  const ApplePurchaseCatalog({
    this.products = const [],
    this.trialEligible = const {},
    this.state = ApplePurchaseState.loading,
    this.message,
  });

  final List<ProductDetails> products;
  final Map<String, bool> trialEligible;
  final ApplePurchaseState state;
  final String? message;

  ApplePurchaseCatalog copyWith({
    List<ProductDetails>? products,
    Map<String, bool>? trialEligible,
    ApplePurchaseState? state,
    String? message,
    bool clearMessage = false,
  }) => ApplePurchaseCatalog(
    products: products ?? this.products,
    trialEligible: trialEligible ?? this.trialEligible,
    state: state ?? this.state,
    message: clearMessage ? null : message ?? this.message,
  );
}

class ApplePurchaseService extends ChangeNotifier {
  ApplePurchaseService(
    this._supabase, {
    http.Client? client,
    this.onVerified,
  }) : _http = client ?? http.Client();

  static const _apiBase = String.fromEnvironment(
    'LATERBOX_WEB_URL',
    defaultValue: 'https://app.laterbox.dev',
  );

  final SupabaseClient? _supabase;
  final http.Client _http;
  final VoidCallback? onVerified;
  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ApplePurchaseCatalog _catalog = const ApplePurchaseCatalog();
  ApplePurchaseCatalog get catalog => _catalog;

  bool get isAppleStoreBuild =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) &&
      const String.fromEnvironment(
            'LATERBOX_DISTRIBUTION',
            defaultValue: 'direct',
          ) ==
          'app-store';

  Future<void> initialize() async {
    if (!isAppleStoreBuild) {
      _set(const ApplePurchaseCatalog(state: ApplePurchaseState.unavailable));
      return;
    }
    _subscription ??= _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) => _set(
        _catalog.copyWith(
          state: ApplePurchaseState.failed,
          message: 'The App Store purchase could not be loaded.',
        ),
      ),
    );
    await loadProducts();
  }

  Future<void> loadProducts() async {
    _set(_catalog.copyWith(state: ApplePurchaseState.loading, clearMessage: true));
    if (!await _store.isAvailable()) {
      _set(const ApplePurchaseCatalog(
        state: ApplePurchaseState.unavailable,
        message: 'The App Store is unavailable on this device.',
      ));
      return;
    }
    final response = await _store.queryProductDetails(appleProductIds);
    if (response.error != null || response.notFoundIDs.isNotEmpty) {
      _set(ApplePurchaseCatalog(
        products: response.productDetails,
        state: ApplePurchaseState.failed,
        message: 'LaterBox Pro products are not available in this storefront yet.',
      ));
      return;
    }
    final addition = _store.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
    final eligibility = <String, bool>{};
    for (final product in response.productDetails) {
      eligibility[product.id] = await addition.isIntroductoryOfferEligible(product.id);
    }
    final sorted = [...response.productDetails]
      ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
    _set(ApplePurchaseCatalog(
      products: sorted,
      trialEligible: eligibility,
      state: ApplePurchaseState.ready,
    ));
  }

  Future<void> purchase(ProductDetails product) async {
    final userId = _supabase?.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Sign in or create an account before starting a subscription.');
    }
    if (!appleProductIds.contains(product.id)) {
      throw ArgumentError.value(product.id, 'product', 'Unknown LaterBox product');
    }
    _set(_catalog.copyWith(state: ApplePurchaseState.pending, clearMessage: true));
    await _store.buyNonConsumable(
      purchaseParam: Sk2PurchaseParam(
        productDetails: product,
        applicationUserName: userId,
      ),
    );
  }

  Future<void> restore() async {
    if (_supabase?.auth.currentUser == null) {
      throw StateError('Sign in before restoring purchases.');
    }
    _set(_catalog.copyWith(state: ApplePurchaseState.pending, clearMessage: true));
    await _store.restorePurchases();
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!appleProductIds.contains(purchase.productID)) continue;
      if (purchase.status == PurchaseStatus.pending) {
        _set(_catalog.copyWith(state: ApplePurchaseState.pending));
        continue;
      }
      if (purchase.status == PurchaseStatus.canceled) {
        _set(_catalog.copyWith(state: ApplePurchaseState.ready, clearMessage: true));
        continue;
      }
      if (purchase.status == PurchaseStatus.error) {
        _set(_catalog.copyWith(
          state: ApplePurchaseState.failed,
          message: purchase.error?.message ?? 'The purchase was not completed.',
        ));
        continue;
      }
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _set(_catalog.copyWith(state: ApplePurchaseState.verifying));
        try {
          await _verify(purchase);
          onVerified?.call();
          if (purchase.pendingCompletePurchase) {
            await _store.completePurchase(purchase);
          }
          _set(_catalog.copyWith(state: ApplePurchaseState.ready, clearMessage: true));
        } catch (_) {
          _set(_catalog.copyWith(
            state: ApplePurchaseState.failed,
            message: 'Your purchase is safe, but verification is still pending. Try Refresh Status.',
          ));
        }
      }
    }
  }

  Future<void> _verify(PurchaseDetails purchase) async {
    final token = _supabase?.auth.currentSession?.accessToken;
    if (token == null) throw StateError('Authentication expired.');
    final response = await _http.post(
      Uri.parse('$_apiBase/api/billing/apple/verify'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'signedTransaction': purchase.verificationData.serverVerificationData,
        'productId': purchase.productID,
      }),
    );
    if (response.statusCode != 200) throw StateError('Verification failed.');
  }

  Future<void> openManagement() => launchUrl(
    Uri.parse('https://apps.apple.com/account/subscriptions'),
    mode: LaunchMode.externalApplication,
  );

  void _set(ApplePurchaseCatalog value) {
    _catalog = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _http.close();
    super.dispose();
  }
}

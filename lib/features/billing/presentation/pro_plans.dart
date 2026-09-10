import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/billing/apple_purchase_service.dart';
import '../../../core/billing/billing_providers.dart';

enum PlanInterval { monthly, annual }

class ProPlans extends ConsumerWidget {
  const ProPlans({
    super.key,
    this.compact = false,
    this.onAuthenticationRequired,
    this.onContinueFree,
  });

  final bool compact;
  final ValueChanged<PlanInterval>? onAuthenticationRequired;
  final VoidCallback? onContinueFree;

  static const _proFeatures = <String>[
    'Cloud sync across your devices',
    'Cloud-backed files and attachments',
    'Browser and system share integrations',
    'macOS notch clipboard capture and Watch Mode',
    'Automatic capture and enrichment',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final authenticated = auth?.isAuthenticated ?? false;
    final apple = isAppleAppStoreBuild
        ? ref.watch(applePurchaseServiceProvider)
        : null;
    final products = apple?.catalog.products ?? const <ProductDetails>[];

    ProductDetails? product(String id) {
      for (final value in products) {
        if (value.id == id) return value;
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _PlanCard(
              width: compact ? 320 : 350,
              title: 'Free',
              price: 'Free forever',
              description: 'A private local library for saving and finding what matters.',
              features: const [
                'Unlimited local saves',
                'Reading, search, and organization',
                'Local attachments and export',
                'No account or connection required',
              ],
              action: 'Continue free',
              onPressed: () {
                ref.read(guestModeProvider.notifier).state = true;
                onContinueFree?.call();
              },
            ),
            _PlanCard(
              width: compact ? 320 : 350,
              featured: true,
              title: 'LaterBox Pro',
              price: _priceText(product(appleMonthlyProductId), product(appleAnnualProductId)),
              description: 'Connected capture, secure sync, and automation everywhere.',
              features: _proFeatures,
              badge: _trialBadge(apple),
              action: _actionLabel(authenticated),
              onPressed: () => _startPro(
                context,
                ref,
                authenticated: authenticated,
                apple: apple,
                interval: PlanInterval.annual,
              ),
            ),
          ],
        ),
        if (apple != null) ...[
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            children: [
              TextButton(
                onPressed: authenticated ? apple.restore : null,
                child: const Text('Restore Purchases'),
              ),
              TextButton(
                onPressed: apple.loadProducts,
                child: const Text('Refresh Status'),
              ),
            ],
          ),
          if (apple.catalog.message != null)
            Text(
              apple.catalog.message!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ],
    );
  }

  String _priceText(ProductDetails? monthly, ProductDetails? annual) {
    if (isAppleAppStoreBuild) {
      if (monthly == null || annual == null) return 'Loading App Store prices…';
      return '${monthly.price}/month or ${annual.price}/year';
    }
    return r'$3.99/month or $39.99/year';
  }

  String? _trialBadge(ApplePurchaseService? apple) {
    if (!isAppleAppStoreBuild) return '14-day trial';
    if (apple == null || apple.catalog.products.isEmpty) return null;
    return apple.catalog.trialEligible.values.any((eligible) => eligible)
        ? 'Introductory trial available'
        : null;
  }

  String _actionLabel(bool authenticated) {
    if (!authenticated) return 'Create account to start';
    if (laterBoxDistribution == 'play') return 'How to get Pro';
    if (isAppleAppStoreBuild) return 'Choose App Store plan';
    return 'View Pro plans';
  }

  Future<void> _startPro(
    BuildContext context,
    WidgetRef ref, {
    required bool authenticated,
    required ApplePurchaseService? apple,
    required PlanInterval interval,
  }) async {
    if (!authenticated) {
      onAuthenticationRequired?.call(interval);
      return;
    }
    if (laterBoxDistribution == 'play') {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Get LaterBox Pro'),
          content: const Text(
            'Subscribe at laterbox.dev on the web, then return here and sign in with the same LaterBox account. Google Play purchases are not offered in this app.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
          ],
        ),
      );
      return;
    }
    if (isAppleAppStoreBuild && apple != null) {
      if (apple.catalog.products.isEmpty) {
        await apple.loadProducts();
        return;
      }
      if (!context.mounted) return;
      final chosen = await showModalBottomSheet<ProductDetails>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Choose your plan', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Both plans include the same Pro features. The App Store shows the final localized price and trial eligibility.'),
              const SizedBox(height: 18),
              for (final product in apple.catalog.products)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, product),
                    child: Text('${product.id == appleAnnualProductId ? 'Annual' : 'Monthly'} · ${product.price}'),
                  ),
                ),
            ],
          ),
        ),
      );
      if (chosen != null) await apple.purchase(chosen);
      return;
    }
    await launchUrl(
      Uri.parse('https://laterbox.dev/pricing'),
      mode: LaunchMode.externalApplication,
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.width,
    required this.title,
    required this.price,
    required this.description,
    required this.features,
    required this.action,
    required this.onPressed,
    this.badge,
    this.featured = false,
  });

  final double width;
  final String title;
  final String price;
  final String description;
  final List<String> features;
  final String action;
  final VoidCallback onPressed;
  final String? badge;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: featured ? Colors.black : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: featured
              ? const Color(0xFFD7FF27)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFD7FF27),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(badge!, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
            ),
          Text(title, style: theme.textTheme.titleLarge?.copyWith(
            color: featured ? Colors.white : null,
            fontWeight: FontWeight.w900,
          )),
          const SizedBox(height: 8),
          Text(price, style: theme.textTheme.titleMedium?.copyWith(
            color: featured ? const Color(0xFFD7FF27) : null,
            fontWeight: FontWeight.w800,
          )),
          const SizedBox(height: 10),
          Text(description, style: TextStyle(color: featured ? Colors.white70 : theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Icon(Icons.check_circle_rounded, size: 17, color: featured ? const Color(0xFFD7FF27) : theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(feature, style: TextStyle(color: featured ? Colors.white : null, fontSize: 13))),
            ]),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: featured ? const Color(0xFFD7FF27) : theme.colorScheme.primary,
                foregroundColor: featured ? Colors.black : theme.colorScheme.onPrimary,
              ),
              child: Text(action),
            ),
          ),
        ],
      ),
    );
  }
}

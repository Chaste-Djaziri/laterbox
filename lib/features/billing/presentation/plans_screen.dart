import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/billing/billing_providers.dart';
import 'pro_plans.dart';

class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = GoRouterState.of(context).uri.queryParameters;
    final interval = query['interval'];
    final returnedFromCheckout = query['checkout'] == 'success';
    final entitlement = ref.watch(entitlementProvider).valueOrNull;
    final preferredInterval = interval == PlanInterval.monthly.name
        ? PlanInterval.monthly
        : PlanInterval.annual;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LaterBox plans'),
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/inbox'),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close plans',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                children: [
                  Text(
                    'Choose how you use LaterBox',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your local library stays free. Upgrade only for connected features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (returnedFromCheckout) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: entitlement?.hasProAccess == true
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        entitlement?.hasProAccess == true
                            ? 'LaterBox Pro is active. Your connected features are ready.'
                            : 'Welcome back. Confirming your subscription and refreshing Pro status…',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  ProPlans(
                    preferredInterval: preferredInterval,
                    onContinueFree: () => context.go('/inbox'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

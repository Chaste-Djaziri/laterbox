import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pro_plans.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final interval = GoRouterState.of(context).uri.queryParameters['interval'];
    final preferredInterval = interval == PlanInterval.monthly.name
        ? PlanInterval.monthly
        : PlanInterval.annual;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LaterBox plans'),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/inbox'),
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
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your local library stays free. Upgrade only for connected features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
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

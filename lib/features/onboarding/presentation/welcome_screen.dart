import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../billing/presentation/pro_plans.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 20 : 40,
            vertical: compact ? 28 : 44,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: Column(
                children: [
                  Image.asset(
                    'assets/branding/laterbox-logo.png',
                    height: compact ? 58 : 72,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Save locally for free.\nConnect everything with Pro.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Text(
                      'LaterBox keeps articles, links, files, and notes easy to find. Start with a private local library, or add secure sync and automatic capture across your devices.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  ProPlans(
                    compact: compact,
                    onContinueFree: () => context.go('/inbox'),
                    onAuthenticationRequired: (interval) => context.go(
                      '/login?mode=signup&next=plans&interval=${interval.name}',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.go('/login?mode=signin'),
                        child: const Text('Sign in'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login?mode=signup'),
                        child: const Text('Create account'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Subscriptions renew automatically until canceled. Local data remains readable and exportable if Pro ends.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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

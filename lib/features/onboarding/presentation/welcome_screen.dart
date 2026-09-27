import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  bool _usesMacDesktopLayout(BuildContext context) =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.macOS &&
      MediaQuery.sizeOf(context).width >= 820;

  @override
  Widget build(BuildContext context) {
    if (_usesMacDesktopLayout(context)) {
      return _MacWelcomeScreen(legal: _legal(context));
    }
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 24 : 40,
            vertical: compact ? 28 : 44,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/branding/laterbox-logo.png',
                    height: compact ? 40 : 48,
                    fit: BoxFit.contain,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/backgrounds/onboarding-hero.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const Text(
                'Save it now.\nRead it later.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.5,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your personal vault for articles, links, files, and notes.',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => context.push('/login'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                ),
                child: const Text(
                  'Get started',
                  style: TextStyle(fontSize: 17),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: _legal(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legal(BuildContext context) => Text.rich(
    TextSpan(
      text: 'By continuing, you agree to our ',
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      children: [
        TextSpan(
          text: 'Terms',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => launchUrl(Uri.parse('https://laterbox.dev/terms')),
        ),
        const TextSpan(text: ' and '),
        TextSpan(
          text: 'Privacy Policy',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () =>
                launchUrl(Uri.parse('https://laterbox.dev/privacy')),
        ),
        const TextSpan(text: '.'),
      ],
    ),
    textAlign: TextAlign.center,
  );
}

class _MacWelcomeScreen extends StatelessWidget {
  const _MacWelcomeScreen({required this.legal});
  final Widget legal;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(52, 42, 44, 38),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/branding/laterbox-logo.png',
                      height: 42,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'A calmer way to remember',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Save it now.\nRead it later.',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.8,
                        height: .98,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A private place for the links, notes, files, and ideas you want to return to at the right time.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 250,
                      height: 52,
                      child: FilledButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Get started'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(width: 330, child: legal),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: colors.secondaryContainer.withValues(alpha: .42),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 28,
                      right: 30,
                      child: TextButton(
                        onPressed: () => context.push('/login'),
                        child: const Text('Sign in'),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(54),
                        child: Image.asset(
                          'assets/backgrounds/onboarding-hero.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 30,
                      bottom: 30,
                      child: Text(
                        'Capture once.\nReturn with intent.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

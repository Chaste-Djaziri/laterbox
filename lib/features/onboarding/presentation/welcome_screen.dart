import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    onPressed: () => context.go('/login?mode=signin'),
                    child: const Text('Sign in'),
                  ),
                ],
              ),
              const Spacer(),
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
                onPressed: () => context.go('/login?mode=signup'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                ),
                child: const Text(
                  'Get started',
                  style: TextStyle(fontSize: 17),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Text.rich(
                  TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    children: [
                      TextSpan(
                        text: 'Terms',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(
                                Uri.parse('https://laterbox.dev/terms'),
                              ),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(
                                Uri.parse('https://laterbox.dev/privacy'),
                              ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

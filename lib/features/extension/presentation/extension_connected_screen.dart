import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Confirmation page shown after the browser extension completes its
/// tab-based connect flow (used by Safari, which has no `identity` API).
class ExtensionConnectedScreen extends StatelessWidget {
  const ExtensionConnectedScreen({
    super.key,
    required this.status,
    required this.requestId,
  });

  final String status;
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final approved = status == 'approved';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Image.asset(
                        'assets/branding/laterbox-logo.png',
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      Icon(
                        approved ? Icons.check_circle : Icons.info_outline,
                        size: 48,
                        color: approved
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        approved
                            ? 'Browser extension connected'
                            : 'Connection not completed',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        approved
                            ? 'Your browser extension is connected to LaterBox. You can close this tab.'
                            : 'The extension was not connected. Try connecting again from the extension.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => context.go('/inbox'),
                        child: const Text('Go to inbox'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../auth/presentation/auth_screen.dart';
import 'extension_redirect.dart';

class ExtensionConnectScreen extends ConsumerStatefulWidget {
  const ExtensionConnectScreen({
    super.key,
    required this.requestId,
    required this.requestSecret,
    required this.redirectUri,
  });

  final String requestId;
  final String requestSecret;
  final String redirectUri;

  @override
  ConsumerState<ExtensionConnectScreen> createState() =>
      _ExtensionConnectScreenState();
}

class _ExtensionConnectScreenState
    extends ConsumerState<ExtensionConnectScreen> {
  bool _busy = false;
  String? _error;

  bool get _validRequest =>
      widget.requestId.isNotEmpty &&
      widget.requestSecret.length >= 32 &&
      _isValidRedirectUri(widget.redirectUri);

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, stackTrace) => const AuthScreen(),
      data: (state) => state.isAuthenticated
          ? _buildApproval(context, state.email)
          : const AuthScreen(),
    );
  }

  Widget _buildApproval(BuildContext context, String? email) {
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
                      Text(
                        'Connect browser extension',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email == null
                            ? 'The extension will be able to save captures to your LaterBox account.'
                            : 'Connect this browser extension to $email.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy || !_validRequest ? null : _approve,
                        child: Text(_busy ? 'Connecting...' : 'Connect'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : () => redirectTo(widget.redirectUri),
                        child: const Text('Cancel'),
                      ),
                      if (!_validRequest)
                        Text(
                          'This connection request is invalid or expired.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
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

  Future<void> _approve() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) {
      setState(() => _error = 'LaterBox is not connected to Supabase.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await client.functions.invoke(
        'extension-connect',
        body: {
          'action': 'approve',
          'request_id': widget.requestId,
          'request_secret': widget.requestSecret,
        },
      );
      final callback = Uri.parse(widget.redirectUri).replace(
        queryParameters: {
          'request_id': widget.requestId,
          'status': 'approved',
        },
      );
      redirectTo(callback.toString());
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not connect this extension.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

bool _isValidRedirectUri(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null) return false;
  if (uri.scheme == 'moz-extension' || uri.scheme == 'safari-web-extension') {
    return true;
  }
  if (uri.scheme == 'https') {
    final host = uri.host.toLowerCase();
    return host.endsWith('.chromiumapp.org') ||
        host.endsWith('.extensions.allizom.org') ||
        host == 'app.laterbox.com';
  }
  if (uri.scheme == 'http' && uri.host == 'localhost') {
    return true;
  }
  return false;
}

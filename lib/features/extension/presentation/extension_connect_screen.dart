import 'package:flutter/foundation.dart';
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

  String get _requestId {
    if (widget.requestId.isNotEmpty) return widget.requestId;
    if (kIsWeb) {
      final q = Uri.base.queryParameters['request_id'];
      if (q != null && q.isNotEmpty) return q;
      if (Uri.base.fragment.contains('request_id=')) {
        final frag = Uri.tryParse(Uri.base.fragment);
        final fragQ = frag?.queryParameters['request_id'];
        if (fragQ != null && fragQ.isNotEmpty) return fragQ;
      }
    }
    return '';
  }

  String get _requestSecret {
    if (widget.requestSecret.isNotEmpty) return widget.requestSecret;
    if (kIsWeb) {
      final q = Uri.base.queryParameters['request_secret'];
      if (q != null && q.isNotEmpty) return q;
      if (Uri.base.fragment.contains('request_secret=')) {
        final frag = Uri.tryParse(Uri.base.fragment);
        final fragQ = frag?.queryParameters['request_secret'];
        if (fragQ != null && fragQ.isNotEmpty) return fragQ;
      }
    }
    return '';
  }

  String get _redirectUri {
    if (widget.redirectUri.isNotEmpty) return widget.redirectUri;
    if (kIsWeb) {
      final q = Uri.base.queryParameters['redirect_uri'];
      if (q != null && q.isNotEmpty) return q;
      if (Uri.base.fragment.contains('redirect_uri=')) {
        final frag = Uri.tryParse(Uri.base.fragment);
        final fragQ = frag?.queryParameters['redirect_uri'];
        if (fragQ != null && fragQ.isNotEmpty) return fragQ;
      }
    }
    return '/extension/connected';
  }

  bool get _validRequest => _requestId.isNotEmpty && _requestSecret.isNotEmpty;

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
                        onPressed: _busy
                            ? null
                            : () => redirectTo(
                                _redirectUri.isNotEmpty ? _redirectUri : '/inbox'),
                        child: const Text('Cancel'),
                      ),
                      if (!_validRequest)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'This connection request is missing required parameters.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
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
      final response = await client.functions.invoke(
        'extension-connect',
        body: {
          'action': 'approve',
          'request_id': _requestId,
          'request_secret': _requestSecret,
        },
      );
      if (response.status >= 400) {
        final data = response.data;
        final msg = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Connection request expired or unavailable. Please click Connect in the extension again.';
        if (mounted) setState(() => _error = msg);
        return;
      }
      final redirectBase = _redirectUri.isNotEmpty ? _redirectUri : '/extension/connected';
      final redirectParsed = Uri.tryParse(redirectBase);
      final callback = (redirectParsed ?? Uri.parse('/extension/connected')).replace(
        queryParameters: {
          ...redirectParsed?.queryParameters ?? {},
          'request_id': _requestId,
          'status': 'approved',
        },
      );
      redirectTo(callback.toString());
    } catch (error) {
      if (mounted) {
        setState(() => _error =
            'Could not connect this extension. Please click Connect in the extension to create a fresh link.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

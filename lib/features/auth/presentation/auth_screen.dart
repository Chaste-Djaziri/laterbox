import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool createAccount}) async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      final repository = ref.read(authRepositoryProvider);
      if (createAccount) {
        await repository.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) {
          final signedIn = ref.read(authStateProvider).valueOrNull?.isAuthenticated ?? false;
          if (signedIn) {
            _finishAuthentication();
          } else {
            setState(
              () => _message = 'Account created. Check your email if confirmation is required.',
            );
          }
        }
      } else {
        await repository.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) _finishAuthentication();
      }
    } on AuthException catch (error) {
      setState(() => _message = error.message);
    } on StateError catch (error) {
      setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finishAuthentication() {
    final next = GoRouterState.of(context).uri.queryParameters['next'];
    context.go(next == 'plans' ? '/plans' : '/inbox');
  }

  @override
  Widget build(BuildContext context) {
    final mode = GoRouterState.of(context).uri.queryParameters['mode'];
    final prefersSignup = mode == 'signup';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/branding/laterbox-logo.png',
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Put it here. Find it later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      prefersSignup ? 'Create your account' : 'Welcome back',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter a valid email address.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                          tooltip: _showPassword ? 'Hide password' : 'Show password',
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Password must be at least 6 characters.'
                          : null,
                      onFieldSubmitted: (_) => _submit(createAccount: prefersSignup),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      child: Text(
                        _busy
                            ? 'Please wait…'
                            : prefersSignup
                            ? 'Create account'
                            : 'Sign in',
                      ),
                      onPressed: _busy
                          ? null
                          : () => _submit(createAccount: prefersSignup),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () {
                              final query = GoRouterState.of(context).uri.queryParameters;
                              final next = query['next'];
                              final nextQuery = next == null ? '' : '&next=$next';
                              context.go(
                                '/login?mode=${prefersSignup ? 'signin' : 'signup'}$nextQuery',
                              );
                            },
                      child: Text(
                        prefersSignup
                            ? 'Already have an account? Sign in'
                            : 'Create account',
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () {
                              ref.read(guestModeProvider.notifier).state = true;
                              context.go('/inbox');
                            },
                      child: const Text('Continue without account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _otpController = TextEditingController();
  bool _showPassword = false;
  bool _busy = false;
  bool _awaitingOtp = false;
  bool _otpForSignup = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
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
        final confirmationRequired = await repository.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) {
          if (!confirmationRequired) {
            _finishAuthentication();
          } else {
            setState(() {
              _awaitingOtp = true;
              _otpForSignup = true;
              _message = null;
            });
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

  Future<void> _requestSignInOtp() async {
    final email = _emailController.text.trim();
    if (_busy || !email.contains('@')) {
      setState(() => _message = 'Enter a valid email address first.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestSignInOtp(email);
      if (mounted) {
        setState(() {
          _awaitingOtp = true;
          _otpForSignup = false;
        });
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on StateError catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    final token = _otpController.text.trim();
    if (_busy || !RegExp(r'^\d{8}$').hasMatch(token)) {
      setState(() => _message = 'Enter the eight digit code from your email.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyEmailOtp(email: _emailController.text, token: token);
      if (mounted) _finishAuthentication();
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on StateError catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final repository = ref.read(authRepositoryProvider);
      if (_otpForSignup) {
        await repository.resendSignupOtp(_emailController.text);
      } else {
        await repository.requestSignInOtp(_emailController.text);
      }
      if (mounted) setState(() => _message = 'A new code was sent.');
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finishAuthentication() {
    final query = GoRouterState.of(context).uri.queryParameters;
    final next = query['next'];
    final interval = query['interval'];
    context.go(
      next == 'plans'
          ? '/plans${interval == null ? '' : '?interval=$interval'}'
          : '/home',
    );
  }

  Widget _buildOtpScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _awaitingOtp = false;
                  _otpController.clear();
                  _message = null;
                }),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/branding/laterbox-logo.png',
                  height: 58,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _otpForSignup ? 'Verify your account' : 'Check your email',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the eight digit code sent to ${_emailController.text.trim()}.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 10,
                    ),
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                  counterText: '',
                ),
                maxLength: 8,
                onSubmitted: (_) => _verifyOtp(),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: TextStyle(
                    color: _message == 'A new code was sent.'
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : _verifyOtp,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                ),
                child: Text(_busy ? 'Please wait…' : 'Verify code'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _busy ? null : _resendOtp,
                    child: const Text('Send a new code'),
                  ),
                  const Text('·'),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _awaitingOtp = false;
                            _otpController.clear();
                            _message = null;
                          }),
                    child: const Text('Use a different email'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = GoRouterState.of(context).uri.queryParameters['mode'];
    final prefersSignup = mode == 'signup';
    if (_awaitingOtp) return _buildOtpScreen(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
              ),
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/branding/laterbox-logo.png',
                  height: 58,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                prefersSignup ? 'Create your account' : 'Welcome back',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Put it here. Find it later.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Form(
                key: _formKey,
                child: Column(
                  children: [
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
                          tooltip: _showPassword
                              ? 'Hide password'
                              : 'Show password',
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Password must be at least 6 characters.'
                          : null,
                      onFieldSubmitted: (_) =>
                          _submit(createAccount: prefersSignup),
                    ),
                  ],
                ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 14),
                Text(
                  _message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () => _submit(createAccount: prefersSignup),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                ),
                child: Text(
                  _busy
                      ? 'Please wait…'
                      : prefersSignup
                          ? 'Create account'
                          : 'Sign in',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                          final query = GoRouterState.of(context)
                              .uri
                              .queryParameters;
                          final next = query['next'];
                          final interval = query['interval'];
                          final nextQuery =
                              next == null ? '' : '&next=$next';
                          final intervalQuery =
                              interval == null ? '' : '&interval=$interval';
                          context.go(
                            '/login?mode=${prefersSignup ? 'signin' : 'signup'}$nextQuery$intervalQuery',
                          );
                        },
                  child: Text(
                    prefersSignup
                        ? 'Already have an account? Sign in'
                        : 'Create account',
                  ),
                ),
              ),
              if (!prefersSignup) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _busy ? null : _requestSignInOtp,
                    icon: const Icon(Icons.password_rounded),
                    label: const Text('Email me a sign in code'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                          ref.read(guestModeProvider.notifier).state = true;
                          context.go('/home');
                        },
                  child: const Text('Continue without account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

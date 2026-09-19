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
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _busy = false;
  bool _awaitingOtp = false;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    var email = _emailController.text.trim();
    if (email.isNotEmpty && !email.contains('@')) {
      email = '$email@gmail.com';
      _emailController.text = email;
    }
    if (_busy || !email.contains('@')) {
      setState(() => _message = 'Enter a valid email address.');
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
          _message = null;
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
      if (mounted) context.go('/home');
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
      await ref.read(authRepositoryProvider).requestSignInOtp(
            _emailController.text,
          );
      if (mounted) setState(() => _message = 'A new code was sent.');
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_awaitingOtp) return _buildOtpScreen(context);
    return _buildEmailScreen(context);
  }

  Widget _buildEmailScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/welcome');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Image.asset(
                    'assets/branding/laterbox-logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/backgrounds/auth-signin.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Text(
                'Enter your email',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'We\'ll send you a code to sign in or create your account.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendOtp(),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _sendOtp,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(
                  _busy ? 'Please wait…' : 'Continue',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpScreen(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      _awaitingOtp = false;
                      _otpController.clear();
                      _message = null;
                    }),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Image.asset(
                    'assets/branding/laterbox-logo.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Check your email',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the eight digit code sent to ${_emailController.text.trim()}.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const Spacer(),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _verifyOtp,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: Text(
                  _busy ? 'Please wait…' : 'Verify code',
                  style: const TextStyle(fontSize: 17),
                ),
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
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/billing/billing_providers.dart';
import '../../../core/settings/display_name_provider.dart';
import '../../../core/sync/sync_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  bool _busy = false;
  bool _awaitingOtp = false;
  String? _message;

  bool _usesMacDesktopLayout(BuildContext context) =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.macOS &&
      MediaQuery.sizeOf(context).width >= 820;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _nameController.dispose();
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

      ref.read(guestModeProvider.notifier).state = false;

      // Immediately fetch user info to know if display name exists
      final name = await ref.read(displayNameProvider.notifier).refresh();

      // Refresh entitlements so Pro/sync state is immediately resolved
      ref.invalidate(entitlementProvider);
      try {
        await ref.read(entitlementProvider.future);
      } catch (_) {}

      // Immediately trigger full sync of items, collections, notes, metadata
      unawaited(ref.read(syncCoordinatorProvider).syncNow());

      if (!mounted) return;

      if (name != null && name.trim().isNotEmpty) {
        context.go('/home');
      } else {
        _showDisplayNameModal();
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } on StateError catch (error) {
      if (mounted) setState(() => _message = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showDisplayNameModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(ctx).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What should we call you?',
                style: Theme.of(ctx).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Optional — you can always set this later.',
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Display name'),
                onSubmitted: (_) => _submitDisplayName(ctx),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _submitDisplayName(ctx),
                  child: const Text('Continue'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _submitDisplayName(ctx),
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) context.go('/home');
    });
  }

  void _submitDisplayName(BuildContext ctx) async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await ref.read(displayNameProvider.notifier).set(name);
    }
    unawaited(ref.read(syncCoordinatorProvider).syncNow());
    if (ctx.mounted) Navigator.of(ctx).pop();
  }

  Future<void> _resendOtp() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .requestSignInOtp(_emailController.text);
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
    if (_usesMacDesktopLayout(context)) {
      return _buildDesktopEmailScreen(context);
    }
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
                style: Theme.of(context).textTheme.headlineMedium
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
              ListenableBuilder(
                listenable: _emailController,
                builder: (context, _) {
                  final hasAt = _emailController.text.contains('@');
                  return TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: 'Email',
                      suffixIcon: hasAt
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Text(
                                '@gmail.com',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                      suffixIconConstraints: const BoxConstraints(
                        maxHeight: 20,
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _sendOtp(),
                  );
                },
              ),
              if (_message != null) ...[
                const SizedBox(height: 14),
                Text(
                  _message!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    if (_usesMacDesktopLayout(context)) {
      return _buildDesktopOtpScreen(context);
    }
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
                style: Theme.of(context).textTheme.headlineMedium
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
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 10),
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

  Widget _buildDesktopEmailScreen(BuildContext context) {
    return _desktopFrame(
      context,
      eyebrow: 'WELCOME TO LATERBOX',
      title: 'Everything worth returning to, in one calm place.',
      detail: 'Sign in to sync your library across your devices. You can also start locally and add an account later.',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Continue with email',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'We’ll send a one-time code — no password needed.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          ListenableBuilder(
            listenable: _emailController,
            builder: (context, _) {
              final hasAt = _emailController.text.contains('@');
              return TextField(
                controller: _emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: 'Email address',
                  suffixIcon: hasAt
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: Text(
                            '@gmail.com',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 15,
                            ),
                          ),
                        ),
                  suffixIconConstraints: const BoxConstraints(maxHeight: 20),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendOtp(),
              );
            },
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _messageText(context),
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : _sendOtp,
              child: Text(_busy ? 'Sending code…' : 'Continue'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    ref.read(guestModeProvider.notifier).state = true;
                    context.go('/home');
                  },
            child: const Text('Continue without an account'),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopOtpScreen(BuildContext context) {
    return _desktopFrame(
      context,
      eyebrow: 'ONE MORE STEP',
      title: 'Your LaterBox is ready when you are.',
      detail: 'We keep the sign-in flow lightweight so you can return to what matters.',
      form: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Check your email',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the eight digit code sent to ${_emailController.text.trim()}.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
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
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 9),
            decoration: const InputDecoration(
              labelText: 'Verification code',
              counterText: '',
            ),
            maxLength: 8,
            onSubmitted: (_) => _verifyOtp(),
          ),
          if (_message != null) ...[
            const SizedBox(height: 12),
            _messageText(context),
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _busy ? null : _verifyOtp,
              child: Text(_busy ? 'Verifying…' : 'Verify code'),
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
        ],
      ),
    );
  }

  Widget _messageText(BuildContext context) => Text(
    _message!,
    style: TextStyle(
      color: _message == 'A new code was sent.'
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.error,
    ),
  );

  Widget _desktopFrame(
    BuildContext context, {
    required String eyebrow,
    required String title,
    required String detail,
    required Widget form,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 11,
              child: Container(
                padding: const EdgeInsets.fromLTRB(48, 42, 52, 42),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer.withValues(alpha: .36),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/branding/laterbox-logo.png',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    const Spacer(),
                    Text(
                      eyebrow,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.6,
                        height: 1.02,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Private by default · Available offline',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 48,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          if (_awaitingOtp) {
                            setState(() {
                              _awaitingOtp = false;
                              _otpController.clear();
                              _message = null;
                            });
                          } else if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/welcome');
                          }
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Back'),
                      ),
                    ),
                    const Spacer(),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: form,
                    ),
                    const Spacer(),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../home/presentation/home_shell.dart';
import 'auth_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final guestMode = ref.watch(guestModeProvider);

    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, stackTrace) => guestMode
          ? HomeShell(selectedIndex: initialIndex)
          : const AuthScreen(),
      data: (state) => state.isAuthenticated || guestMode
          ? HomeShell(selectedIndex: initialIndex)
          : const AuthScreen(),
    );
  }
}

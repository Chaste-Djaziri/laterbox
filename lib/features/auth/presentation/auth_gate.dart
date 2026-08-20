import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../home/presentation/home_shell.dart';
import 'auth_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({
    super.key,
    this.initialIndex = 0,
    this.navigationShell,
    this.child,
  });

  final int initialIndex;
  final StatefulNavigationShell? navigationShell;
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final guestMode = ref.watch(guestModeProvider);

    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, stackTrace) => guestMode
          ? (child ??
              HomeShell(
                selectedIndex: navigationShell?.currentIndex ?? initialIndex,
                navigationShell: navigationShell,
              ))
          : const AuthScreen(),
      data: (state) => state.isAuthenticated || guestMode
          ? (child ??
              HomeShell(
                selectedIndex: navigationShell?.currentIndex ?? initialIndex,
                navigationShell: navigationShell,
              ))
          : const AuthScreen(),
    );
  }
}

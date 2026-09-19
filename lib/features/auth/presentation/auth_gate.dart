import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';
import '../../home/presentation/home_shell.dart';
import '../../onboarding/presentation/welcome_screen.dart';

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
    final currentAuth = ref.watch(currentAuthStateProvider);
    final isGuest = ref.watch(isGuestProvider);

    if (currentAuth.isAuthenticated || isGuest) {
      return child ??
          HomeShell(
            selectedIndex: navigationShell?.currentIndex ?? initialIndex,
            navigationShell: navigationShell,
          );
    }

    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (error, stackTrace) => const WelcomeScreen(),
      data: (state) => state.isAuthenticated
          ? (child ??
              HomeShell(
                selectedIndex: navigationShell?.currentIndex ?? initialIndex,
                navigationShell: navigationShell,
              ))
          : const WelcomeScreen(),
    );
  }
}

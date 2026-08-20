import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/detail/presentation/item_detail_screen.dart';
import '../../features/extension/presentation/extension_connect_screen.dart';
import '../../features/extension/presentation/extension_connected_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/landing/presentation/landing_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final initialLocationProvider = Provider<String>((ref) {
  if (kIsWeb) return '/';
  final authState = ref.watch(authStateProvider).asData?.value;
  final guestMode = ref.watch(guestModeProvider);

  if (guestMode || (authState?.isAuthenticated ?? false)) {
    return '/inbox';
  }
  return '/login';
});

final appRouterProvider = Provider<GoRouter>((ref) {
  // The router must outlive authentication state changes. Recreating it while
  // a pointer event is in flight can dispose the active route's viewport
  // before hit testing completes.
  final initialLocation = ref.read(initialLocationProvider);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const LandingScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
        ),
      ),
      GoRoute(
        path: '/extension/connect',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: ExtensionConnectScreen(
            requestId: state.uri.queryParameters['request_id'] ?? '',
            requestSecret: state.uri.queryParameters['request_secret'] ?? '',
            redirectUri: state.uri.queryParameters['redirect_uri'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/extension/connected',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: ExtensionConnectedScreen(
            status: state.uri.queryParameters['status'] ?? '',
            requestId: state.uri.queryParameters['request_id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          int selectedIndex = 0;
          if (location.startsWith('/search')) {
            selectedIndex = 1;
          } else if (location.startsWith('/library')) {
            selectedIndex = 2;
          }
          return AuthGate(
            child: HomeShell(
              selectedIndex: selectedIndex,
              child: child,
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/inbox',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const InboxScreen(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SearchScreen(),
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const LibraryScreen(),
            ),
          ),
          GoRoute(
            path: '/item/:id',
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ItemDetailScreen(itemId: id);
            },
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

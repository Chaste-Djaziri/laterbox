import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_provider.dart';
import '../../features/auth/presentation/auth_gate.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/billing/presentation/plans_screen.dart';
import '../../features/capture/presentation/capture_sheet.dart';
import '../../features/detail/presentation/item_detail_screen.dart';
import '../../features/download/presentation/download_screen.dart';
import '../../features/extension/presentation/extension_connect_screen.dart';
import '../../features/extension/presentation/extension_connected_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/home/presentation/home_dashboard.dart';
import '../../features/scheduling/presentation/schedule_providers.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/landing/presentation/landing_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/library/presentation/library_providers.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/library/presentation/library_section_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/app_icon_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

import '../../features/splash/presentation/splash_screen.dart';
import '../../features/tutorial/presentation/tutorial_screen.dart';

final initialLocationProvider = Provider<String>((ref) {
  if (kIsWeb) return '/';
  final authState = ref.watch(restoredAuthStateProvider);
  final guestMode = ref.watch(guestModeProvider);

  if (guestMode || authState.isAuthenticated) {
    return '/home';
  }
  return '/welcome';
});

final appRouterProvider = Provider<GoRouter>((ref) {
  // The router must outlive authentication state changes. Recreating it while
  // a pointer event is in flight can dispose the active route's viewport
  // before hit testing completes.
  final isMobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);
  final initialLocation = isMobile
      ? '/splash'
      : ref.read(initialLocationProvider);
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const LandingScreen()),
      ),
      GoRoute(
        path: '/download',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const DownloadScreen()),
      ),
      GoRoute(
        path: '/downloads',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const DownloadScreen()),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const WelcomeScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const AuthScreen()),
      ),
      GoRoute(
        path: '/plans',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const PlansScreen()),
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
        path: '/tutorial',
        pageBuilder: (context, state) =>
            NoTransitionPage(key: state.pageKey, child: const TutorialScreen()),
      ),
      GoRoute(
        path: '/capture',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: SafeArea(child: CaptureSheet())),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.path;
          final selectedIndex = location.startsWith('/settings')
              ? 6
              : location.startsWith('/library') || location.startsWith('/kept')
              ? 5
              : location.startsWith('/someday')
              ? 4
              : location.startsWith('/upcoming')
              ? 3
              : location.startsWith('/today')
              ? 2
              : location.startsWith('/inbox') ||
                    location.startsWith('/item') ||
                    location.startsWith('/search')
              ? 1
              : 0;
          return AuthGate(
            child: HomeShell(selectedIndex: selectedIndex, child: child),
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeDashboard(),
            ),
          ),
          for (final entry in const {
            '/today': ScheduleView.today,
            '/upcoming': ScheduleView.upcoming,
            '/someday': ScheduleView.someday,
          }.entries)
            GoRoute(
              path: entry.key,
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: ScheduleScreen(view: entry.value),
              ),
            ),
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
            path: '/settings',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'icon',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const AppIconScreen(),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/kept',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: LibrarySectionScreen(
                title: 'Kept',
                provider: keptProvider,
              ),
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

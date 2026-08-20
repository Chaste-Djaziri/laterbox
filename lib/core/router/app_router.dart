import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_gate.dart';
import '../../features/detail/presentation/item_detail_screen.dart';
import '../../features/extension/presentation/extension_connect_screen.dart';
import '../../features/extension/presentation/extension_connected_screen.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/search/presentation/search_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/inbox',
    routes: [
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
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return NoTransitionPage(
                key: state.pageKey,
                child: ItemDetailScreen(itemId: id),
              );
            },
          ),
        ],
      ),
      GoRoute(path: '/', redirect: (context, state) => '/inbox'),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

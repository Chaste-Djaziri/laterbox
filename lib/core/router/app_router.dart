import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_gate.dart';
import '../../features/detail/presentation/item_detail_screen.dart';
import '../../features/extension/presentation/extension_connect_screen.dart';
import '../../features/inbox/presentation/inbox_screen.dart';
import '../../features/library/presentation/library_screen.dart';
import '../../features/search/presentation/search_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/extension/connect',
        builder: (context, state) => ExtensionConnectScreen(
          requestId: state.uri.queryParameters['request_id'] ?? '',
          requestSecret: state.uri.queryParameters['request_secret'] ?? '',
          redirectUri: state.uri.queryParameters['redirect_uri'] ?? '',
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AuthGate(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const InboxScreen(),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/library',
                builder: (context, state) => const LibraryScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/', redirect: (context, state) => '/inbox'),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

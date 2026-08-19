import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_gate.dart';
import '../../features/extension/presentation/extension_connect_screen.dart';

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
      GoRoute(
        path: '/inbox',
        builder: (context, state) => const AuthGate(initialIndex: 0),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const AuthGate(initialIndex: 1),
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const AuthGate(initialIndex: 2),
      ),
      GoRoute(path: '/', redirect: (context, state) => '/inbox'),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

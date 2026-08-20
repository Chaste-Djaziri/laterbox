import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/core/auth/auth_state.dart';
import 'package:laterbox/core/router/app_router.dart';

void main() {
  test('a restored session opens the inbox after reload', () {
    final container = ProviderContainer(
      overrides: [
        guestModeProvider.overrideWith((ref) => false),
        restoredAuthStateProvider.overrideWith(
          (ref) => const LaterBoxAuthState(
            userId: 'user-1',
            email: 'user@example.com',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(initialLocationProvider), '/inbox');
  });

  test('a reload without a session opens sign in', () {
    final container = ProviderContainer(
      overrides: [
        guestModeProvider.overrideWith((ref) => false),
        restoredAuthStateProvider.overrideWith(
          (ref) => const LaterBoxAuthState(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(initialLocationProvider), '/login');
  });
}

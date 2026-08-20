import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/router/app_router.dart';

void main() {
  test('keeps the active router when initial location inputs change', () {
    final location = StateProvider<String>((ref) => '/login');
    final container = ProviderContainer(
      overrides: [
        initialLocationProvider.overrideWith((ref) => ref.watch(location)),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);

    container.read(location.notifier).state = '/inbox';

    expect(container.read(appRouterProvider), same(router));
  });
}

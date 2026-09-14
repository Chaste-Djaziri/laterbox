import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_icon_service.dart';

final appIconServiceProvider = Provider<AppIconService>((ref) {
  return const AppIconService();
});

final appIconSupportedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(appIconServiceProvider);
  return service.isSupported();
});

class AppIconNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final service = ref.watch(appIconServiceProvider);
    return service.getCurrentIconName();
  }

  /// Sets the active app icon variant. Returns whether the operation succeeded.
  Future<bool> selectIcon(String? iconName) async {
    final service = ref.read(appIconServiceProvider);
    final previous = state.valueOrNull;
    state = const AsyncValue.loading();
    final success = await service.setAlternateIconName(iconName);
    if (success) {
      state = AsyncValue.data(iconName);
      return true;
    } else {
      state = AsyncValue.data(previous);
      return false;
    }
  }
}

final currentAppIconProvider =
    AsyncNotifierProvider<AppIconNotifier, String?>(AppIconNotifier.new);

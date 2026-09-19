import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_provider.dart';
import '../supabase/supabase_provider.dart';

final displayNameProvider =
    NotifierProvider<DisplayNameNotifier, String?>(DisplayNameNotifier.new);

class DisplayNameNotifier extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(authStateProvider);
    final client = ref.read(supabaseClientProvider);
    final user = client?.auth.currentUser;
    final meta = user?.userMetadata;
    final raw = meta?['display_name'] ?? meta?['full_name'] ?? meta?['name'];
    return (raw is String && raw.trim().isNotEmpty) ? raw.trim() : null;
  }

  Future<String?> refresh() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return null;
    try {
      final response = await client.auth.getUser();
      final user = response.user;
      final meta = user?.userMetadata;
      final raw = meta?['display_name'] ?? meta?['full_name'] ?? meta?['name'];
      final name = (raw is String && raw.trim().isNotEmpty) ? raw.trim() : null;
      state = name;
      return name;
    } catch (_) {
      final meta = client.auth.currentUser?.userMetadata;
      final raw = meta?['display_name'] ?? meta?['full_name'] ?? meta?['name'];
      final fallback =
          (raw is String && raw.trim().isNotEmpty) ? raw.trim() : null;
      state = fallback;
      return fallback;
    }
  }

  Future<void> set(String name) async {
    final trimmed = name.trim();
    final client = ref.read(supabaseClientProvider);
    if (client != null) {
      await client.auth.updateUser(
        UserAttributes(data: {'display_name': trimmed}),
      );
    }
    state = trimmed.isNotEmpty ? trimmed : null;
  }

  Future<void> clear() async {
    final client = ref.read(supabaseClientProvider);
    if (client != null) {
      await client.auth.updateUser(
        UserAttributes(data: {'display_name': null}),
      );
    }
    state = null;
  }
}


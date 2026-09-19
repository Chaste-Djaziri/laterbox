import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_provider.dart';

final displayNameProvider =
    NotifierProvider<DisplayNameNotifier, String?>(DisplayNameNotifier.new);

class DisplayNameNotifier extends Notifier<String?> {
  @override
  String? build() {
    final client = ref.read(supabaseClientProvider);
    final user = client?.auth.currentUser;
    return user?.userMetadata?['display_name'] as String?;
  }

  Future<void> set(String name) async {
    final client = ref.read(supabaseClientProvider);
    if (client != null) {
      await client.auth.updateUser(
        UserAttributes(data: {'display_name': name}),
      );
    }
    state = name;
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

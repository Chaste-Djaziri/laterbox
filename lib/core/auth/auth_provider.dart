import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../supabase/supabase_config.dart';
import '../supabase/supabase_provider.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

final guestModeProvider = StateProvider<bool>(
  (ref) => !SupabaseConfig.isConfigured,
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<LaterBoxAuthState>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    yield const LaterBoxAuthState();
    return;
  }

  final initialUser = client.auth.currentUser;
  yield LaterBoxAuthState(userId: initialUser?.id, email: initialUser?.email);

  await for (final event in client.auth.onAuthStateChange) {
    final user = event.session?.user;
    yield LaterBoxAuthState(userId: user?.id, email: user?.email);
  }
});

final activeUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).asData?.value.userId;
});

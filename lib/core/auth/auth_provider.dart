import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_config.dart';
import '../supabase/supabase_provider.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

final guestModeProvider = StateProvider<bool>((ref) {
  if (!SupabaseConfig.isInitialized) return true;
  final user = ref.watch(supabaseClientProvider)?.auth.currentUser;
  return user == null;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final restoredAuthStateProvider = Provider<LaterBoxAuthState>((ref) {
  final user = ref.watch(supabaseClientProvider)?.auth.currentUser;
  return LaterBoxAuthState(userId: user?.id, email: user?.email);
});

final authStateProvider = StreamProvider<LaterBoxAuthState>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) {
    yield const LaterBoxAuthState();
    return;
  }

  yield ref.watch(restoredAuthStateProvider);

  await for (final event in client.auth.onAuthStateChange) {
    final user = event.session?.user;
    if (user != null) {
      Future.microtask(() {
        ref.read(guestModeProvider.notifier).state = false;
      });
    } else if (event.event == AuthChangeEvent.signedOut) {
      Future.microtask(() {
        ref.read(guestModeProvider.notifier).state = true;
      });
    }
    yield LaterBoxAuthState(userId: user?.id, email: user?.email);
  }
});

/// Synchronous or stream-derived authenticated state of LaterBox.
/// Guaranteed to never lag behind in AsyncLoading when a session is already present
/// in SupabaseClient.auth.currentUser.
final currentAuthStateProvider = Provider<LaterBoxAuthState>((ref) {
  final streamState = ref.watch(authStateProvider).valueOrNull;
  if (streamState != null && streamState.isAuthenticated) {
    return streamState;
  }
  final restored = ref.watch(restoredAuthStateProvider);
  if (restored.isAuthenticated) {
    return restored;
  }
  return streamState ?? restored;
});

/// Indicates whether the application is running in local-only Guest Mode.
/// If an authenticated session exists, this is guaranteed to return false.
final isGuestProvider = Provider<bool>((ref) {
  final auth = ref.watch(currentAuthStateProvider);
  if (auth.isAuthenticated) {
    return false;
  }
  return ref.watch(guestModeProvider);
});

final activeUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentAuthStateProvider).userId;
});


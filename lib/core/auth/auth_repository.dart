import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient? _client;

  SupabaseClient get _requiredClient {
    return _client ??
        (throw StateError('Supabase is not configured for authentication.'));
  }

  Future<void> signIn({required String email, required String password}) async {
    await _requiredClient.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUp({required String email, required String password}) async {
    await _requiredClient.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _requiredClient.auth.signOut();
}

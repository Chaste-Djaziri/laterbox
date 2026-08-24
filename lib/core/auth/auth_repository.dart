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
    await _requiredClient.auth.signUp(email: email.trim(), password: password);
  }

  Future<void> updatePassword(String newPassword) async {
    await _requiredClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> deleteAccount({Future<void> Function()? onClearLocalData}) async {
    final session = _requiredClient.auth.currentSession;
    if (session != null) {
      try {
        await _requiredClient.functions.invoke(
          'delete-account',
          headers: {'Authorization': 'Bearer ${session.accessToken}'},
        );
      } catch (_) {
        // Fallback to table deletions via RLS
        final userId = _requiredClient.auth.currentUser?.id;
        if (userId != null) {
          try {
            await _requiredClient.from('item_collections').delete().match({'user_id': userId});
          } catch (_) {}
          try {
            await _requiredClient.from('item_metadata').delete().match({'user_id': userId});
          } catch (_) {}
          try {
            await _requiredClient.from('items').delete().match({'user_id': userId});
          } catch (_) {}
          try {
            await _requiredClient.from('collections').delete().match({'user_id': userId});
          } catch (_) {}
        }
      }
    }

    if (onClearLocalData != null) {
      await onClearLocalData();
    }

    await _requiredClient.auth.signOut();
  }

  Future<void> signOut() => _requiredClient.auth.signOut();
}

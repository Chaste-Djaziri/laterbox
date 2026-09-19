import 'package:shared_preferences/shared_preferences.dart';

import '../notifications/notification_identity.dart';
import '../notifications/notification_service.dart';

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

  Future<bool> signUp({required String email, required String password}) async {
    final response = await _requiredClient.auth.signUp(
      email: email.trim(),
      password: password,
    );
    return response.session == null;
  }

  Future<void> requestSignInOtp(String email) async {
    await _requiredClient.auth.signInWithOtp(
      email: email.trim(),
      shouldCreateUser: false,
    );
  }

  Future<void> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    final response = await _requiredClient.auth.verifyOTP(
      email: email.trim(),
      token: token,
      type: OtpType.email,
    );
    if (response.session == null) {
      throw const AuthException(
        'The verification code could not be confirmed.',
      );
    }
  }

  Future<void> resendSignupOtp(String email) async {
    await _requiredClient.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _requiredClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> deleteAccount({
    Future<void> Function()? onClearLocalData,
  }) async {
    await _disconnectNotifications();
    final session = _requiredClient.auth.currentSession;
    if (session != null) {
      // 1. Try atomic PostgreSQL RPC deletion (Security Definer)
      try {
        await _requiredClient.rpc('delete_user_account');
      } catch (_) {
        // 2. Try Edge Function deletion
        try {
          await _requiredClient.functions.invoke(
            'delete-account',
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
          );
        } catch (_) {
          // 3. Fallback table-by-table deletions via RLS
          final userId = _requiredClient.auth.currentUser?.id;
          if (userId != null) {
            try {
              await _requiredClient.from('collection_items').delete();
            } catch (_) {}
            try {
              await _requiredClient.from('item_notes').delete().match({
                'user_id': userId,
              });
            } catch (_) {}
            try {
              await _requiredClient.from('item_metadata').delete().match({
                'user_id': userId,
              });
            } catch (_) {}
            try {
              await _requiredClient.from('attachments').delete().match({
                'user_id': userId,
              });
            } catch (_) {}
            try {
              await _requiredClient.from('items').delete().match({
                'user_id': userId,
              });
            } catch (_) {}
            try {
              await _requiredClient.from('collections').delete().match({
                'user_id': userId,
              });
            } catch (_) {}
          }
        }
      }
    }

    if (onClearLocalData != null) {
      await onClearLocalData();
    }

    await _requiredClient.auth.signOut();
  }

  Future<void> _disconnectNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await InboxNotificationService.instance.disconnect();
    if (prefs.getString('notification_registered_user') != null) {
      await _requiredClient.rpc(
        'revoke_notification_installation',
        params: {
          'installation_id': await NotificationIdentity.installationId(),
          'revocation_secret': await NotificationIdentity.revocationSecret(),
        },
      );
      await prefs.remove('notification_registered_user');
    }
    await prefs.remove('notification_handed_off');
  }

  Future<void> signOut() async {
    await _disconnectNotifications();
    await _requiredClient.auth.signOut();
  }
}

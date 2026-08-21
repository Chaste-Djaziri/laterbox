import 'localhost_url.dart';

abstract final class SupabaseConfig {
  static const _backend = String.fromEnvironment(
    'LATERBOX_BACKEND',
    defaultValue: 'remote',
  );
  static const _configuredUrl = String.fromEnvironment('SUPABASE_URL');
  static const _configuredPublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _localPublishableKey =
      'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';
  static const _hostedUrl = 'https://ltjisrgldssqskcylcbj.supabase.co';
  static const _hostedPublishableKey =
      'sb_publishable_Rc4e_ik2LE4SR0UrfX-OEQ_5Mu_lw9p';

  static bool _initialized = false;

  static bool get usesLocalBackend => _backend == 'local';

  static String get url {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;
    return usesLocalBackend ? localDebugSupabaseUrl : _hostedUrl;
  }

  static String get publishableKey {
    if (_configuredPublishableKey.isNotEmpty) {
      return _configuredPublishableKey;
    }
    return usesLocalBackend ? _localPublishableKey : _hostedPublishableKey;
  }

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
  static bool get isInitialized => _initialized;

  static void markInitialized() => _initialized = true;
}

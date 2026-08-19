import 'package:flutter/foundation.dart';

import 'localhost_url.dart';

abstract final class SupabaseConfig {
  static const _configuredUrl = String.fromEnvironment('SUPABASE_URL');
  static const _configuredPublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _localPublishableKey =
      'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

  static bool _initialized = false;

  static String get url => _configuredUrl.isNotEmpty
      ? _configuredUrl
      : kReleaseMode
      ? ''
      : localDebugSupabaseUrl;

  static String get publishableKey => _configuredPublishableKey.isNotEmpty
      ? _configuredPublishableKey
      : kReleaseMode
      ? ''
      : _localPublishableKey;

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
  static bool get isInitialized => _initialized;

  static void markInitialized() => _initialized = true;
}

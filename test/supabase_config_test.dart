import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/supabase/supabase_config.dart';

void main() {
  test('debug builds default to the local Supabase stack', () {
    expect(SupabaseConfig.isConfigured, isTrue);
    expect(SupabaseConfig.url, 'http://127.0.0.1:54321');
    expect(SupabaseConfig.publishableKey, isNotEmpty);
    expect(SupabaseConfig.isInitialized, isFalse);
  });
}

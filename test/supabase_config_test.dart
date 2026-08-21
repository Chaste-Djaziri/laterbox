import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/supabase/supabase_config.dart';

void main() {
  test('builds default to the hosted Supabase project', () {
    expect(SupabaseConfig.isConfigured, isTrue);
    expect(SupabaseConfig.url, 'https://ltjisrgldssqskcylcbj.supabase.co');
    expect(SupabaseConfig.usesLocalBackend, isFalse);
    expect(SupabaseConfig.publishableKey, isNotEmpty);
    expect(SupabaseConfig.isInitialized, isFalse);
  });
}

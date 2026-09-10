import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'entitlement.dart';

class EntitlementRepository {
  EntitlementRepository(this._client, {http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  static const _apiBase = String.fromEnvironment(
    'LATERBOX_WEB_URL',
    defaultValue: 'https://app.laterbox.dev',
  );

  final SupabaseClient? _client;
  final http.Client _http;

  Future<Entitlement> load() async {
    final user = _client?.auth.currentUser;
    final token = _client?.auth.currentSession?.accessToken;
    if (user == null || token == null) return const Entitlement.free();

    try {
      final response = await _http.get(
        Uri.parse('$_apiBase/api/billing/entitlement'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) throw StateError('Billing API unavailable');
      final entitlement = Entitlement.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        _cacheKey(user.id),
        jsonEncode(entitlement.toJson()),
      );
      return entitlement;
    } catch (_) {
      return loadCached(user.id);
    }
  }

  Future<Entitlement> loadCached(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    final cached = preferences.getString(_cacheKey(userId));
    if (cached == null) return const Entitlement.free();
    try {
      return Entitlement.fromJson(jsonDecode(cached) as Map<String, dynamic>);
    } catch (_) {
      return const Entitlement.free();
    }
  }

  String _cacheKey(String userId) => 'laterbox_entitlement_$userId';
}

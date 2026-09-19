import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _key = 'laterbox_display_name';

final displayNameProvider =
    NotifierProvider<DisplayNameNotifier, String?>(DisplayNameNotifier.new);

class DisplayNameNotifier extends Notifier<String?> {
  @override
  String? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString(_key);
  }

  Future<void> set(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, name);
    state = name;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    state = null;
  }
}

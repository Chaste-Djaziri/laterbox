import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Origin identity also exists before permission is granted. It contains no token.
class NotificationIdentity {
  static Future<String> installationId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString('notification_installation_id');
    if (existing != null) return existing;
    final id = const Uuid().v4();
    await prefs.setString('notification_installation_id', id);
    return id;
  }
}

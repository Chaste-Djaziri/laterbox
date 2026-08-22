import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> reloadWebWithoutCache() async {
  try {
    final sw = web.window.navigator.serviceWorker;
    final registrations = await sw.getRegistrations().toDart;
    for (var i = 0; i < registrations.length; i++) {
      final reg = registrations[i];
      reg.unregister();
    }
  } catch (_) {}

  try {
    final caches = web.window.caches;
    final keys = await caches.keys().toDart;
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i].toDart;
      caches.delete(key);
    }
  } catch (_) {}

  try {
    final loc = web.window.location;
    final url = Uri.parse(loc.href);
    final freshParams = Map<String, String>.from(url.queryParameters);
    freshParams['_v'] = DateTime.now().millisecondsSinceEpoch.toString();
    loc.assign(url.replace(queryParameters: freshParams).toString());
  } catch (_) {
    web.window.location.reload();
  }
}

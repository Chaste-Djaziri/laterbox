import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> reloadWebWithoutCache() async {
  // 1. Unregister all service workers and wait for completion
  try {
    final sw = web.window.navigator.serviceWorker;
    final registrations = await sw.getRegistrations().toDart;
    final jsList = registrations.toDart;
    for (final reg in jsList) {
      try {
        await reg.unregister().toDart;
      } catch (_) {}
    }
  } catch (_) {}

  // 2. Clear all CacheStorage keys and wait for completion
  try {
    final caches = web.window.caches;
    final keys = await caches.keys().toDart;
    final jsKeys = keys.toDart;
    for (final key in jsKeys) {
      try {
        await caches.delete(key.toDart).toDart;
      } catch (_) {}
    }
  } catch (_) {}

  // 3. Clear transient sessionStorage
  try {
    web.window.sessionStorage.clear();
  } catch (_) {}

  // 4. Force browser navigation with fresh timestamp and reload
  try {
    final loc = web.window.location;
    final url = Uri.parse(loc.href);
    final freshParams = Map<String, String>.from(url.queryParameters);
    freshParams['_update'] = DateTime.now().millisecondsSinceEpoch.toString();
    final freshUrl = url.replace(queryParameters: freshParams).toString();
    loc.replace(freshUrl);
  } catch (_) {
    try {
      web.window.location.reload();
    } catch (_) {}
  }
}

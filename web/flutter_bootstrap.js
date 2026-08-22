{{flutter_js}}
{{flutter_build_config}}

async function startLaterBox() {
  if ('serviceWorker' in navigator) {
    try {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));
    } catch (_) {}
  }

  if ('caches' in window) {
    try {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
    } catch (_) {}
  }

  await _flutter.loader.load({
    serviceWorkerSettings: null,
  });
}

startLaterBox();


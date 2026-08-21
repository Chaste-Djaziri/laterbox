{{flutter_js}}
{{flutter_build_config}}

async function startLaterBox() {
  // Flutter's generated service worker is deprecated and can keep an old app
  // shell alive after a Pages deployment. Retire any prior registration before
  // starting the current release.
  if ('serviceWorker' in navigator) {
    const registrations = await navigator.serviceWorker.getRegistrations();
    await Promise.all(registrations.map((registration) => registration.unregister()));
  }

  await _flutter.loader.load();
}

startLaterBox();

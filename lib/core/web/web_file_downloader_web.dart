import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> triggerBrowserDownload(String url, String filename) async {
  try {
    final response = await web.window.fetch(url.toJS).toDart;
    if (response.status == 200) {
      final blob = await response.blob().toDart;
      final blobUrl = web.URL.createObjectURL(blob);
      final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
      anchor.href = blobUrl;
      anchor.download = filename;
      anchor.style.display = 'none';
      web.document.body?.appendChild(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(blobUrl);
      return;
    }
  } catch (_) {}

  try {
    final absoluteUrl = url.startsWith('http')
        ? url
        : '${web.window.location.origin}$url';
    web.window.open(absoluteUrl, '_blank');
  } catch (_) {}
}

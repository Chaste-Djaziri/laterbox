import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<bool> triggerBrowserDownload(String url, String filename) async {
  try {
    final response = await web.window.fetch(url.toJS).toDart;
    if (response.status == 200) {
      final contentType = response.headers.get('content-type') ?? '';
      final isBinaryFile = filename.endsWith('.pkg') ||
          filename.endsWith('.dmg') ||
          filename.endsWith('.zip') ||
          filename.endsWith('.exe');
      if (isBinaryFile && contentType.contains('text/html')) {
        return false;
      }

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
      return true;
    }
  } catch (_) {}

  return false;
}

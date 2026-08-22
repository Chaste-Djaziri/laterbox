import 'package:web/web.dart' as web;

void triggerBrowserDownload(String url, String filename) {
  try {
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.target = '_blank';
    anchor.style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
  } catch (_) {
    web.window.open(url, '_blank');
  }
}

import 'laterbox_extension_stub.dart'
    if (dart.library.js_interop) 'laterbox_extension_web.dart' as impl;

/// Asks the installed LaterBox browser extension to open [url] in a fresh tab
/// and highlight the saved quote by locating it in the DOM.
///
/// Returns true when the extension handled the request, false when it is not
/// available (native app, no extension installed, or no listener on the
/// origin), so callers fall back to the browser-native text fragment URL.
Future<bool> openWithLaterBoxExtension(
  String url, {
  String? fragmentUrl,
  String? exact,
  String? prefix,
  String? suffix,
}) {
  return impl.openWithLaterBoxExtension(
    url,
    fragmentUrl: fragmentUrl,
    exact: exact,
    prefix: prefix,
    suffix: suffix,
  );
}
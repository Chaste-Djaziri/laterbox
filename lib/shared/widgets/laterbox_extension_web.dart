import 'dart:js_interop';

@JS()
extension type _GlobalThis._(JSObject _) implements JSObject {
  external ChromeRuntime? get chrome;
}

@JS()
extension type ChromeRuntime._(JSObject _) implements JSObject {
  external ChromeExtRuntime? get runtime;
}

@JS()
extension type ChromeExtRuntime._(JSObject _) implements JSObject {
  external JSPromise<JSAny?>? sendMessage(JSAny message);
}

@JS()
extension type _StatusResponse._(JSObject _) implements JSObject {
  external String? get status;
}

Future<bool> openWithLaterBoxExtension(
  String url, {
  String? fragmentUrl,
  String? exact,
  String? prefix,
  String? suffix,
}) async {
  try {
    final runtime = (globalContext as _GlobalThis).chrome?.runtime;
    if (runtime == null) return false;

    final message = <String, JSAny?>{
      'type': 'open-with-highlight'.toJS,
      'url': url.toJS,
      if (fragmentUrl != null) 'fragmentUrl': fragmentUrl.toJS,
      'selector': <String, JSAny?>{
        'exact': (exact ?? '').toJS,
        if (prefix != null) 'prefix': prefix.toJS,
        if (suffix != null) 'suffix': suffix.toJS,
      }.jsify(),
    }.jsify();

    final promise = runtime.sendMessage(message!);
    if (promise == null) return false;
    final response = await promise.toDart;
    if (response == null || !response.isA<JSObject>()) return false;
    return (response as _StatusResponse).status == 'ok';
  } catch (_) {
    return false;
  }
}
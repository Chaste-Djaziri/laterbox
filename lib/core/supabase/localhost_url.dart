import 'localhost_url_stub.dart'
    if (dart.library.io) 'localhost_url_io.dart' as impl;

String get localDebugSupabaseUrl => impl.localDebugSupabaseUrl;
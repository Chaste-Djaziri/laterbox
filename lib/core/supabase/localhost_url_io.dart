import 'dart:io';

String get localDebugSupabaseUrl =>
    Platform.isAndroid ? 'http://10.0.2.2:54321' : 'http://127.0.0.1:54321';
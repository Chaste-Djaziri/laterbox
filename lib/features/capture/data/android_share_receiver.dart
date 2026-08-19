import 'package:flutter/services.dart';

import '../domain/capture_payload.dart';

class AndroidShareReceiver {
  const AndroidShareReceiver();

  static const channelName = 'laterbox/android_share';
  static const MethodChannel _channel = MethodChannel(channelName);

  Future<CapturePayload?> consume() async {
    final text = await _channel.invokeMethod<String?>('consumeShare');
    final value = text?.trim();
    if (value == null || value.isEmpty) return null;
    return CapturePayload.fromValue(value, source: CaptureSource.androidShare);
  }
}
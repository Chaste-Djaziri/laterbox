import 'package:flutter/services.dart';

import '../domain/capture_payload.dart';

class AndroidShareReceiver {
  const AndroidShareReceiver();

  static const channelName = 'laterbox/android_share';
  static const MethodChannel _channel = MethodChannel(channelName);

  Future<List<CapturePayload>> consumePendingShares() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('consumeShares');
    if (raw == null || raw.isEmpty) return const [];

    return raw
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map(
          (value) => CapturePayload.fromValue(
            value,
            source: CaptureSource.androidShare,
          ),
        )
        .toList();
  }
}
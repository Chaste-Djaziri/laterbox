import 'package:flutter/services.dart';

import '../domain/native_share_payload.dart';

class IosShareReceiver {
  const IosShareReceiver();

  static const channelName = 'laterbox/apple_share';
  static const MethodChannel _channel = MethodChannel(channelName);

  Future<List<NativeSharePayload>> consumePendingShares() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('consumePending');
    if (raw == null || raw.isEmpty) return const [];

    final payloads = <NativeSharePayload>[];
    for (final entry in raw.whereType<Map<dynamic, dynamic>>()) {
      final normalized = Map<dynamic, dynamic>.from(entry);
      if (normalized['text'] == null && normalized['value'] != null) {
        normalized['text'] = normalized['value'];
      }
      final payload = NativeSharePayload.fromMap(normalized);
      if (payload != null) payloads.add(payload);
    }
    return payloads;
  }

  Future<void> clearPending() async {
    await _channel.invokeMethod<void>('clearPending');
  }

  Future<void> acknowledge(Iterable<String> ids) async {
    await _channel.invokeMethod<bool>('acknowledgePending', {
      'ids': ids.toList(),
    });
  }
}

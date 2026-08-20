import 'package:flutter/services.dart';

import '../domain/native_share_payload.dart';

class AndroidShareReceiver {
  const AndroidShareReceiver();

  static const channelName = 'laterbox/android_share';
  static const MethodChannel _channel = MethodChannel(channelName);

  Future<List<NativeSharePayload>> consumePendingShares() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('consumeShares');
    if (raw == null || raw.isEmpty) return const [];

    final payloads = <NativeSharePayload>[];
    for (var index = 0; index < raw.length; index++) {
      final entry = raw[index];
      if (entry is Map<dynamic, dynamic>) {
        final payload = NativeSharePayload.fromMap(entry);
        if (payload != null) payloads.add(payload);
      } else if (entry is String && entry.trim().isNotEmpty) {
        payloads.add(
          NativeSharePayload(
            id: 'legacy-$index',
            text: entry.trim(),
            filePaths: const [],
          ),
        );
      }
    }
    return payloads;
  }

  Future<void> acknowledge(Iterable<String> ids) async {
    await _channel.invokeMethod<bool>('acknowledgeShares', {
      'ids': ids.toList(),
    });
  }
}

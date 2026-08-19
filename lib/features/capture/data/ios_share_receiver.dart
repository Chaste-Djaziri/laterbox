import 'package:flutter/services.dart';

import '../domain/capture_payload.dart';

class IosShareReceiver {
  const IosShareReceiver();

  static const channelName = 'laterbox/ios_share';
  static const MethodChannel _channel = MethodChannel(channelName);

  Future<List<CapturePayload>> consumePendingShares() async {
    final raw = await _channel.invokeMethod<List<dynamic>>('consumePending');
    if (raw == null || raw.isEmpty) return const [];

    final payloads = <CapturePayload>[];
    for (final entry in raw.whereType<Map<dynamic, dynamic>>()) {
      final id = entry['id'] as String?;
      final value = (entry['value'] as String?)?.trim();
      if (value == null || value.isEmpty) continue;
      final createdAtText = entry['createdAt'] as String?;
      final createdAt = createdAtText == null
          ? null
          : DateTime.tryParse(createdAtText);
      payloads.add(
        CapturePayload.fromValue(
          value,
          id: id,
          createdAt: createdAt,
          source: CaptureSource.iosShare,
        ),
      );
    }
    return payloads;
  }

  Future<void> clearPending() async {
    await _channel.invokeMethod<void>('clearPending');
  }
}
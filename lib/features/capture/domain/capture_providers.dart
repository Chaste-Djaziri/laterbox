import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../inbox/presentation/inbox_providers.dart';
import '../data/android_share_receiver.dart';
import '../data/ios_share_receiver.dart';
import 'capture_service.dart';

final captureServiceProvider = Provider<CaptureService>((ref) {
  return CaptureService(ref.watch(itemRepositoryProvider));
});

final androidShareReceiverProvider = Provider<AndroidShareReceiver>((ref) {
  return const AndroidShareReceiver();
});

final iosShareReceiverProvider = Provider<IosShareReceiver>((ref) {
  return const IosShareReceiver();
});
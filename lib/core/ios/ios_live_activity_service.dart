import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IosLiveActivityService {
  const IosLiveActivityService({
    MethodChannel? channel,
    this.platform,
  }) : _channel =
            channel ?? const MethodChannel('pro.micorp.laterbox/live_activity');

  final MethodChannel _channel;
  final TargetPlatform? platform;

  TargetPlatform get effectivePlatform => platform ?? defaultTargetPlatform;

  Future<bool> isSupported() async {
    if (kIsWeb || effectivePlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      final supported = await _channel.invokeMethod<bool>('isSupported');
      return supported ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> startActivity({
    required String id,
    required String title,
    String? subtitle,
    String? returnSchedule,
    String captureType = 'share',
    bool isCompleted = true,
    bool isError = false,
    double autoDismissSeconds = 3.5,
  }) async {
    if (kIsWeb || effectivePlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('start', {
        'id': id,
        'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (returnSchedule != null) 'returnSchedule': returnSchedule,
        'captureType': captureType,
        'isCompleted': isCompleted,
        'isError': isError,
        'autoDismissSeconds': autoDismissSeconds,
      });
    } on PlatformException catch (e) {
      debugPrint('[IosLiveActivityService] Failed to start Live Activity: $e');
    } catch (_) {}
  }

  Future<void> updateActivity({
    required String id,
    String? title,
    String? subtitle,
    String? returnSchedule,
    bool? isCompleted,
    bool? isError,
  }) async {
    if (kIsWeb || effectivePlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('update', {
        'id': id,
        if (title != null) 'title': title,
        if (subtitle != null) 'subtitle': subtitle,
        if (returnSchedule != null) 'returnSchedule': returnSchedule,
        if (isCompleted != null) 'isCompleted': isCompleted,
        if (isError != null) 'isError': isError,
      });
    } on PlatformException catch (e) {
      debugPrint('[IosLiveActivityService] Failed to update Live Activity: $e');
    } catch (_) {}
  }

  Future<void> endActivity(String id) async {
    if (kIsWeb || effectivePlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('end', {'id': id});
    } catch (_) {}
  }

  Future<void> endAllActivities() async {
    if (kIsWeb || effectivePlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      await _channel.invokeMethod<bool>('endAll');
    } catch (_) {}
  }
}

final iosLiveActivityServiceProvider = Provider<IosLiveActivityService>((ref) {
  return const IosLiveActivityService();
});

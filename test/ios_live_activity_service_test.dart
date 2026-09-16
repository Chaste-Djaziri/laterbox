import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/ios/ios_live_activity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IosLiveActivityService', () {
    const channel = MethodChannel('pro.micorp.laterbox/live_activity');
    final log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        log.add(call);
        if (call.method == 'isSupported') return true;
        return true;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('isSupported returns true when channel returns true on iOS', () async {
      const service = IosLiveActivityService(platform: TargetPlatform.iOS);
      final supported = await service.isSupported();

      expect(supported, isTrue);
      expect(log.single.method, 'isSupported');
    });

    test('isSupported returns false on non-iOS platform without invoking channel', () async {
      const service = IosLiveActivityService(platform: TargetPlatform.android);
      final supported = await service.isSupported();

      expect(supported, isFalse);
      expect(log, isEmpty);
    });

    test('startActivity invokes start with correct arguments on iOS', () async {
      const service = IosLiveActivityService(platform: TargetPlatform.iOS);
      await service.startActivity(
        id: 'capture-42',
        title: 'Saved to LaterBox',
        subtitle: 'https://flutter.dev',
        returnSchedule: 'Tomorrow',
        captureType: 'share',
        isCompleted: true,
      );

      expect(log.single.method, 'start');
      expect(log.single.arguments, {
        'id': 'capture-42',
        'title': 'Saved to LaterBox',
        'subtitle': 'https://flutter.dev',
        'returnSchedule': 'Tomorrow',
        'captureType': 'share',
        'isCompleted': true,
        'isError': false,
        'autoDismissSeconds': 3.5,
      });
    });

    test('updateActivity invokes update on iOS', () async {
      const service = IosLiveActivityService(platform: TargetPlatform.iOS);
      await service.updateActivity(
        id: 'capture-42',
        title: 'Updated Title',
        isCompleted: true,
      );

      expect(log.single.method, 'update');
      expect(log.single.arguments, {
        'id': 'capture-42',
        'title': 'Updated Title',
        'isCompleted': true,
      });
    });

    test('endActivity invokes end with id on iOS', () async {
      const service = IosLiveActivityService(platform: TargetPlatform.iOS);
      await service.endActivity('capture-42');

      expect(log.single.method, 'end');
      expect(log.single.arguments, {'id': 'capture-42'});
    });

    test('endAllActivities invokes endAll on iOS', () async {
      const service = IosLiveActivityService(platform: TargetPlatform.iOS);
      await service.endAllActivities();

      expect(log.single.method, 'endAll');
    });
  });
}

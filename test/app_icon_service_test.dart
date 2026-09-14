import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/app_icon/app_icon_providers.dart';
import 'package:laterbox/core/app_icon/app_icon_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppIconOption', () {
    test('all contains 6 curated variants', () {
      expect(AppIconOption.all.length, 6);
      expect(AppIconOption.all.map((o) => o.id), [
        null,
        'AppIcon-Dark',
        'AppIcon-Neon',
        'AppIcon-Emerald',
        'AppIcon-Sunset',
        'AppIcon-Monochrome',
      ]);
    });

    test('fromId returns correct option or defaults to Classic Light', () {
      expect(AppIconOption.fromId(null).name, 'Classic Light');
      expect(AppIconOption.fromId('AppIcon-Dark').name, 'Midnight Dark');
      expect(AppIconOption.fromId('AppIcon-Neon').name, 'Neon Lime');
      expect(AppIconOption.fromId('AppIcon-Emerald').name, 'Emerald Forest');
      expect(AppIconOption.fromId('AppIcon-Sunset').name, 'Sunset Coral');
      expect(AppIconOption.fromId('AppIcon-Monochrome').name, 'Monochrome');
      expect(AppIconOption.fromId('unknown-id').name, 'Classic Light');
    });
  });

  group('AppIconService & Channel', () {
    const channel = MethodChannel('laterbox/app_icon');
    final log = <MethodCall>[];
    String? currentMockIcon;
    bool mockSupports = true;

    setUp(() {
      log.clear();
      currentMockIcon = null;
      mockSupports = true;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            log.add(methodCall);
            switch (methodCall.method) {
              case 'supportsAlternateIcons':
                return mockSupports;
              case 'getAlternateIconName':
                return currentMockIcon;
              case 'setAlternateIconName':
                final iconName = methodCall.arguments['iconName'] as String?;
                currentMockIcon = iconName;
                return true;
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('isSupported queries channel and handles exceptions', () async {
      const service = AppIconService(
        channel: channel,
        platform: TargetPlatform.iOS,
      );
      expect(await service.isSupported(), isTrue);
      expect(log.last.method, 'supportsAlternateIcons');
    });

    test('getCurrentIconName returns active icon name', () async {
      currentMockIcon = 'AppIcon-Dark';
      const service = AppIconService(
        channel: channel,
        platform: TargetPlatform.iOS,
      );
      expect(await service.getCurrentIconName(), 'AppIcon-Dark');
      expect(log.last.method, 'getAlternateIconName');
    });

    test('setAlternateIconName invokes method with iconName', () async {
      const service = AppIconService(
        channel: channel,
        platform: TargetPlatform.iOS,
      );
      final result = await service.setAlternateIconName('AppIcon-Neon');
      expect(result, isTrue);
      expect(log.last.method, 'setAlternateIconName');
      expect(log.last.arguments, {'iconName': 'AppIcon-Neon'});
      expect(currentMockIcon, 'AppIcon-Neon');
    });
  });

  group('AppIconNotifier Provider', () {
    const channel = MethodChannel('laterbox/app_icon');
    String? currentMockIcon = 'AppIcon-Emerald';

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (methodCall) async {
            switch (methodCall.method) {
              case 'supportsAlternateIcons':
                return true;
              case 'getAlternateIconName':
                return currentMockIcon;
              case 'setAlternateIconName':
                final iconName = methodCall.arguments['iconName'] as String?;
                currentMockIcon = iconName;
                return true;
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('loads initial state and updates on selectIcon', () async {
      final container = ProviderContainer(
        overrides: [
          appIconServiceProvider.overrideWithValue(
            const AppIconService(
              channel: channel,
              platform: TargetPlatform.iOS,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final initial = await container.read(currentAppIconProvider.future);
      expect(initial, 'AppIcon-Emerald');

      final success = await container
          .read(currentAppIconProvider.notifier)
          .selectIcon('AppIcon-Dark');
      expect(success, isTrue);

      final updated = container.read(currentAppIconProvider).value;
      expect(updated, 'AppIcon-Dark');
      expect(currentMockIcon, 'AppIcon-Dark');
    });
  });
}

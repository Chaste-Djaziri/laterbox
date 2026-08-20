import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:laterbox/core/desktop/desktop_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DesktopSettingsNotifier', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('initializes with default values', () {
      final notifier = DesktopSettingsNotifier(prefs);
      expect(notifier.state.keepRunningOnClose, isTrue);
      expect(notifier.state.launchAtLogin, isFalse);
      expect(notifier.state.showInMenuBar, isTrue);
      expect(notifier.state.useSelectedText, isTrue);
      expect(notifier.state.blurCloseOnFocusLost, isFalse);
      expect(notifier.state.shortcut.label, '⌥ Space');
    });

    test('updates and persists settings changes', () async {
      final notifier = DesktopSettingsNotifier(prefs);

      await notifier.setKeepRunningOnClose(false);
      expect(notifier.state.keepRunningOnClose, isFalse);

      await notifier.setBlurCloseOnFocusLost(true);
      expect(notifier.state.blurCloseOnFocusLost, isTrue);

      const customShortcut = DesktopShortcut(
        key: PhysicalKeyboardKey.keyK,
        modifiers: [HotKeyModifier.alt, HotKeyModifier.shift],
      );
      await notifier.updateShortcut(customShortcut);
      expect(notifier.state.shortcut.label, '⌥ ⇧ K');

      // Reload notifier from prefs to verify persistence
      final reloadedNotifier = DesktopSettingsNotifier(prefs);
      // Wait for microtask/async load if needed
      await Future<void>.delayed(Duration.zero);

      expect(reloadedNotifier.state.keepRunningOnClose, isFalse);
      expect(reloadedNotifier.state.blurCloseOnFocusLost, isTrue);
      expect(reloadedNotifier.state.shortcut.label, '⌥ ⇧ K');
    });
  });
}
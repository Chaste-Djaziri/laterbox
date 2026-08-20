import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/settings/desktop_shortcut.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('DesktopShortcut', () {
    test('defaults to alt + space with a stable label', () {
      final shortcut = DesktopShortcut.defaultQuickCapture();

      expect(shortcut.keyId, PhysicalKeyboardKey.space.usbHidUsage);
      expect(shortcut.modifiers, [DesktopModifier.alt]);
      expect(shortcut.displayLabel, '⌥ Space');
    });

    test('uses a Windows safe default and native labels', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      final shortcut = DesktopShortcut.defaultQuickCapture();

      expect(shortcut.keyId, PhysicalKeyboardKey.space.usbHidUsage);
      expect(shortcut.modifiers, [
        DesktopModifier.control,
        DesktopModifier.alt,
      ]);
      expect(shortcut.displayLabel, 'Ctrl + Alt + Space');
    });

    test('round-trips through JSON', () {
      const shortcut = DesktopShortcut(
        keyId: 44,
        modifiers: [DesktopModifier.alt, DesktopModifier.meta],
      );

      final restored = DesktopShortcut.fromJson(shortcut.toJson());

      expect(restored.keyId, 44);
      expect(restored.modifiers, [DesktopModifier.alt, DesktopModifier.meta]);
      expect(restored.isSameAs(shortcut), isTrue);
    });

    test('isSameAs compares key and modifier set', () {
      const a = DesktopShortcut(
        keyId: 44,
        modifiers: [DesktopModifier.alt, DesktopModifier.shift],
      );
      const b = DesktopShortcut(
        keyId: 44,
        modifiers: [DesktopModifier.shift, DesktopModifier.alt],
      );
      const c = DesktopShortcut(keyId: 44, modifiers: [DesktopModifier.alt]);

      expect(a.isSameAs(b), isTrue);
      expect(a.isSameAs(c), isFalse);
    });

    test('malformed JSON falls back to the default shortcut', () {
      final restored = DesktopShortcut.fromJson(const {'nonsense': true});

      expect(restored.keyId, PhysicalKeyboardKey.space.usbHidUsage);
      expect(restored.modifiers, [DesktopModifier.alt]);
    });
  });
}

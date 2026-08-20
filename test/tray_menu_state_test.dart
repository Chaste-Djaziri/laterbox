import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/desktop/tray_menu_state.dart';

void main() {
  group('DesktopMenuState', () {
    test('synced shows the account lines', () {
      const state = DesktopMenuState(
        accountStatus: DesktopMenuAccountStatus.synced,
        quickCaptureShortcutLabel: '⌥ Space',
        email: 'me@example.com',
      );

      expect(state.statusLines(), [
        '✓ Synced',
        'Signed in as me@example.com',
      ]);
    });

    test('offline explains local saving', () {
      const state = DesktopMenuState(
        accountStatus: DesktopMenuAccountStatus.offline,
        quickCaptureShortcutLabel: '⌥ Space',
      );

      expect(state.statusLines(), ['Offline — changes saved locally']);
    });

    test('guest mode has a single line', () {
      const state = DesktopMenuState(
        accountStatus: DesktopMenuAccountStatus.guest,
        quickCaptureShortcutLabel: '⌥ Space',
      );

      expect(state.statusLines(), ['Guest mode']);
    });
  });
}
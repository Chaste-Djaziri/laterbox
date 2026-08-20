import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/desktop/desktop_providers.dart';
import 'package:laterbox/core/settings/desktop_settings.dart';
import 'package:laterbox/core/settings/desktop_shortcut.dart';
import 'package:laterbox/core/settings/settings_providers.dart';
import 'package:laterbox/features/settings/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.leanfy.hotkey_manager'),
          (methodCall) async {
            if (methodCall.method == 'register' ||
                methodCall.method == 'unregister') {
              return true;
            }
            return null;
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.fluttercommunity.plus/connectivity'),
          (methodCall) async {
            if (methodCall.method == 'check') {
              return ['wifi'];
            }
            return null;
          },
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.alexmercerind/tray_manager'),
          (methodCall) async {
            return null;
          },
        );
  });

  Future<AppDatabase> pumpScreen(
    WidgetTester tester, {
    bool accessibilityGranted = true,
  }) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final store = DesktopSettingsStore(database);

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        desktopSettingsStoreProvider.overrideWithValue(store),
        accessibilityTrustedProvider.overrideWith(
          (ref) async => accessibilityGranted,
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return database;
  }

  testWidgets('renders every settings section with defaults', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Quick Capture'), findsOneWidget);
    expect(find.text('Shortcut'), findsOneWidget);
    expect(find.text('⌥ Space'), findsOneWidget);
    expect(find.text('Use selected text when available'), findsOneWidget);
    expect(find.text('Close Quick Capture when focus is lost'), findsOneWidget);
    expect(
      find.text('Keep LaterBox running when window closes'),
      findsOneWidget,
    );
    expect(find.text('Launch LaterBox at login'), findsOneWidget);
    expect(find.text('Show LaterBox in menu bar'), findsOneWidget);

    final switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .map((w) => w.value)
        .toList();
    expect(switches, [
      true, // useSelectedText
      false, // closeOnFocusLoss
      true, // keepRunningOnWindowClose
      false, // launchAtLogin
      true, // showInMenuBar
    ]);
  });

  testWidgets('granted accessibility shows enabled status', (tester) async {
    await pumpScreen(tester, accessibilityGranted: true);

    expect(find.text('Accessibility access enabled'), findsOneWidget);
    expect(find.text('Open System Settings'), findsNothing);
  });

  testWidgets('missing accessibility offers to open system settings', (
    tester,
  ) async {
    await pumpScreen(tester, accessibilityGranted: false);

    expect(find.text('Accessibility access required'), findsOneWidget);
    expect(find.text('Open System Settings'), findsOneWidget);
  });

  testWidgets('shortcut recorder persists a new combination', (tester) async {
    final database = await pumpScreen(tester);

    await tester.tap(find.text('Change shortcut'));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyT);
    await tester.pump();
    expect(find.text('⌘ T'), findsOneWidget);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyT);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.tap(find.text('Save shortcut'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final persisted = await database.readSetting(
      DesktopSettingsKeys.quickCaptureShortcut,
    );
    final settings = DesktopSettings.fromKeyValues({
      DesktopSettingsKeys.quickCaptureShortcut: persisted,
    });
    expect(
      settings.quickCaptureShortcut.keyId,
      PhysicalKeyboardKey.keyT.usbHidUsage,
    );
    expect(settings.quickCaptureShortcut.modifiers, [DesktopModifier.meta]);
  });

  testWidgets('shortcut recorder rejects a modifier-less key', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Change shortcut'));
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyT);
    await tester.pump();

    expect(
      find.text('Add a modifier like ⌥ or ⌘ for a safe global shortcut.'),
      findsOneWidget,
    );
    expect(find.text('⌘ T'), findsNothing);
  });
}

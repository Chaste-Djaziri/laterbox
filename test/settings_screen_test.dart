import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/billing/billing_providers.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/desktop/desktop_providers.dart';
import 'package:laterbox/core/settings/desktop_settings.dart';
import 'package:laterbox/core/settings/desktop_shortcut.dart';
import 'package:laterbox/core/settings/settings_providers.dart';
import 'package:laterbox/core/theme/app_theme.dart';
import 'package:laterbox/features/settings/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.leanflutter.plugins/hotkey_manager'),
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
    bool isPro = false,
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
        hasProAccessProvider.overrideWithValue(isPro),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return database;
  }

  testWidgets('renders every settings section with defaults', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Quick Capture'), findsOneWidget);
    expect(find.text('Shortcut'), findsOneWidget);
    expect(find.text('⌃ ⌥ Space'), findsOneWidget);
    expect(find.text('Use selected text when available'), findsOneWidget);
    expect(find.text('Close Quick Capture when focus is lost'), findsOneWidget);
    expect(find.text('Keep LaterBox running when window closes'), findsOneWidget);
    expect(find.text('Launch LaterBox at login'), findsOneWidget);
    expect(find.text('Show LaterBox in menu bar'), findsOneWidget);
    expect(find.text('Live in Top Screen Notch (macOS)'), findsOneWidget);
    expect(find.text('Watch active screen & browser tabs'), findsOneWidget);
    expect(
      find.text('Capture word references with highlight URLs'),
      findsOneWidget,
    );

    final switches = tester
        .widgetList<SwitchListTile>(find.byType(SwitchListTile))
        .map((w) => w.value)
        .toList();
    expect(switches, [
      false, // notifications.enabled
      true, // notifications.returns
      true, // notifications.saves
      true, // useSelectedText
      false, // closeOnFocusLoss
      true, // keepRunningOnWindowClose
      false, // launchAtLogin
      true, // showInMenuBar
      true, // enableNotchMode
      true, // watchActiveScreen
      true, // autoCopyWordReferences
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

  testWidgets('force sync prompts pro plan sheet when user is not pro', (
    tester,
  ) async {
    await pumpScreen(tester, isPro: false);

    final pageScrollable = find.byType(Scrollable).first;
    final syncButton = find.text('Force Sync Now');
    await tester.scrollUntilVisible(syncButton, 100, scrollable: pageScrollable);
    await tester.drag(pageScrollable, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(syncButton, findsOneWidget);

    await tester.tap(syncButton);
    await tester.pumpAndSettle();

    expect(find.text('Choose a Pro plan'), findsOneWidget);
    expect(find.text('Cloud sync completed'), findsNothing);
  });

  testWidgets('force sync runs sync and shows snackbar when user is pro', (
    tester,
  ) async {
    await pumpScreen(tester, isPro: true);

    final pageScrollable = find.byType(Scrollable).first;
    final syncButton = find.text('Force Sync Now');
    await tester.scrollUntilVisible(syncButton, 100, scrollable: pageScrollable);
    await tester.drag(pageScrollable, const Offset(0, -150));
    await tester.pumpAndSettle();
    expect(syncButton, findsOneWidget);

    await tester.tap(syncButton);
    await tester.pumpAndSettle();

    expect(find.text('Choose a Pro plan'), findsNothing);
    expect(find.text('Cloud sync completed'), findsOneWidget);
  });

  testWidgets('renders App Icon tile and opens dedicated AppIconScreen', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await pumpScreen(tester);

      final pageScrollable = find.byType(Scrollable).first;
      final appIconTile = find.widgetWithText(ListTile, 'App Icon');
      await tester.scrollUntilVisible(
        appIconTile,
        300,
        scrollable: pageScrollable,
      );
      expect(appIconTile, findsOneWidget);
      expect(find.text('Classic Light • Paper & Ink'), findsOneWidget);

      await tester.tap(appIconTile);
      await tester.pumpAndSettle();

      // Now on dedicated AppIconScreen
      expect(find.text('Available Variants'), findsOneWidget);
      expect(find.text('Current Home Screen Icon'), findsOneWidget);
      expect(find.text('Classic Light'), findsWidgets);
      expect(find.text('Midnight Dark'), findsOneWidget);
      expect(find.text('Neon Lime'), findsOneWidget);
      expect(find.text('Emerald Forest'), findsOneWidget);
      expect(find.text('Sunset Coral'), findsOneWidget);
      expect(find.text('Monochrome'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}



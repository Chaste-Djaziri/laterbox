import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/desktop/clipboard_capture_service.dart';
import 'package:laterbox/core/desktop/desktop_actions.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/desktop/desktop_app_launch_service.dart';
import 'package:laterbox/core/desktop/desktop_capture_context_resolver.dart';
import 'package:laterbox/core/desktop/desktop_providers.dart';
import 'package:laterbox/core/desktop/desktop_service.dart';
import 'package:laterbox/core/desktop/global_hotkey_service.dart';
import 'package:laterbox/core/desktop/quick_capture_controller.dart';
import 'package:laterbox/core/desktop/selection_capture_service.dart';
import 'package:laterbox/core/desktop/tray_menu_state.dart';
import 'package:laterbox/core/desktop/tray_service.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/settings/desktop_shortcut.dart';
import 'package:laterbox/core/settings/settings_providers.dart';
import 'package:laterbox/features/capture/domain/capture_service.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/inbox/data/item_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'openQuickCapture activates the controller then shows the window',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final desktop = _FakeDesktopService();
      final container = _container(desktop, database: database);
      addTearDown(container.dispose);

      await container.read(desktopActionsProvider).openQuickCapture();

      expect(container.read(quickCaptureControllerProvider).isActive, isTrue);
      expect(desktop.showCalls, 1);
      expect(desktop.hideCalls, 0);
    },
  );

  test('openLaterBox closes capture state and shows the main window', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _FakeDesktopService();
    final container = _container(desktop, database: database);
    addTearDown(container.dispose);

    final controller = container.read(quickCaptureControllerProvider);
    await controller.open();
    expect(controller.isActive, isTrue);

    await container.read(desktopActionsProvider).openLaterBox();

    expect(controller.isActive, isFalse);
    expect(desktop.showMainCalls, 1);
    expect(desktop.hideCalls, 0);
  });

  test(
    'openQuickCapture prefills from a text selection and records the app',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final desktop = _FakeDesktopService();
      final container = _container(
        desktop,
        database: database,
        resolver: DesktopCaptureContextResolver(
          selectionService: _FakeSelectionService(
            selection: 'selected paragraph',
            appName: 'Safari',
          ),
          clipboardService: _FakeClipboardService('https://clipboard.example'),
        ),
      );
      addTearDown(container.dispose);

      await container.read(desktopActionsProvider).openQuickCapture();

      final controller = container.read(quickCaptureControllerProvider);
      expect(controller.isActive, isTrue);
      expect(controller.prefillText, 'selected paragraph');
      expect(controller.sourceApplication, 'Safari');
    },
  );

  test(
    'openQuickCapture falls back to the clipboard URL without a selection',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final desktop = _FakeDesktopService();
      final container = _container(
        desktop,
        database: database,
        resolver: DesktopCaptureContextResolver(
          selectionService: const _FakeSelectionService(),
          clipboardService: _FakeClipboardService('https://clipboard.example'),
        ),
      );
      addTearDown(container.dispose);

      await container.read(desktopActionsProvider).openQuickCapture();

      final controller = container.read(quickCaptureControllerProvider);
      expect(controller.isActive, isTrue);
      expect(controller.prefillText, 'https://clipboard.example');
      expect(controller.sourceApplication, isNull);
    },
  );

  test('finishQuickCapture restores the pre-capture window', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _FakeDesktopService();
    final container = _container(desktop, database: database);
    addTearDown(container.dispose);

    await container.read(desktopActionsProvider).finishQuickCapture();

    expect(desktop.finishCalls, 1);
  });

  test('openQuickCapture rethrows when showing the window fails', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _ThrowingDesktopService();
    final container = _container(desktop, database: database);
    addTearDown(container.dispose);

    await expectLater(
      container.read(desktopActionsProvider).openQuickCapture(),
      throwsException,
    );
  });

  test(
    'changeQuickCaptureShortcut persists a successful registration',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final desktop = _FakeDesktopService();
      final hotkey = _FakeHotkeyService(succeed: true);
      final container = _container(desktop, database: database, hotkey: hotkey);
      addTearDown(container.dispose);

      const replacement = DesktopShortcut(
        keyId: 44,
        modifiers: [DesktopModifier.control, DesktopModifier.shift],
      );

      final ok = await container
          .read(desktopActionsProvider)
          .changeQuickCaptureShortcut(replacement);

      expect(ok, isTrue);
      expect(hotkey.registered, isNotNull);
      expect(hotkey.registered!.isSameAs(replacement), isTrue);
      final persisted = await container
          .read(desktopSettingsStoreProvider)
          .load();
      expect(persisted.quickCaptureShortcut.isSameAs(replacement), isTrue);
    },
  );

  test(
    'changeQuickCaptureShortcut keeps the old shortcut on failure',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final desktop = _FakeDesktopService();
      final hotkey = _FakeHotkeyService(succeed: false);
      final container = _container(desktop, database: database, hotkey: hotkey);
      addTearDown(container.dispose);

      const replacement = DesktopShortcut(
        keyId: 44,
        modifiers: [DesktopModifier.control],
      );

      final ok = await container
          .read(desktopActionsProvider)
          .changeQuickCaptureShortcut(replacement);

      expect(ok, isFalse);
      expect(hotkey.registered, isNull);
      final persisted = await container
          .read(desktopSettingsStoreProvider)
          .load();
      expect(
        persisted.quickCaptureShortcut.keyId,
        PhysicalKeyboardKey.space.usbHidUsage,
      );
    },
  );

  test('applyStartup hides the window when launched at login', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _FakeDesktopService();
    final appLaunch = _FakeAppLaunchService(launchedAtLogin: true);
    final hotkey = _FakeHotkeyService(succeed: true);
    final container = _container(
      desktop,
      database: database,
      hotkey: hotkey,
      appLaunch: appLaunch,
      tray: _FakeTrayService(),
    );
    addTearDown(container.dispose);

    await container.read(desktopActionsProvider).applyStartup();

    expect(desktop.hideCalls, 1);
    expect(hotkey.registered, isNotNull);
  });

  test('applyStartup keeps the window visible on a manual launch', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final desktop = _FakeDesktopService();
    final appLaunch = _FakeAppLaunchService(launchedAtLogin: false);
    final hotkey = _FakeHotkeyService(succeed: true);
    final container = _container(
      desktop,
      database: database,
      hotkey: hotkey,
      appLaunch: appLaunch,
      tray: _FakeTrayService(),
    );
    addTearDown(container.dispose);

    await container.read(desktopActionsProvider).applyStartup();

    expect(desktop.hideCalls, 0);
    expect(hotkey.registered, isNotNull);
  });

  test(
    'menu bar setting destroys and recreates the tray immediately',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final tray = _FakeTrayService();
      final container = _container(
        _FakeDesktopService(),
        database: database,
        tray: tray,
      );
      addTearDown(container.dispose);
      final actions = container.read(desktopActionsProvider);

      await actions.setShowInMenuBar(false);
      await actions.setShowInMenuBar(true);

      expect(tray.destroyCalls, 1);
      expect(tray.initCalls, 1);
      expect(tray.updateCalls, 1);
      final persisted = await container
          .read(desktopSettingsStoreProvider)
          .load();
      expect(persisted.showInMenuBar, isTrue);
    },
  );
}

ProviderContainer _container(
  DesktopService desktop, {
  required AppDatabase database,
  DesktopCaptureContextResolver? resolver,
  GlobalHotkeyService? hotkey,
  DesktopAppLaunchService? appLaunch,
  TrayService? tray,
}) {
  return ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      desktopServiceProvider.overrideWithValue(desktop),
      quickCaptureControllerProvider.overrideWith(
        (ref) => QuickCaptureController(
          desktopService: desktop,
          clipboardService: const ClipboardCaptureService(),
          captureService: _captureService(database),
        ),
      ),
      if (resolver != null)
        desktopCaptureContextResolverProvider.overrideWithValue(resolver),
      if (hotkey != null) globalHotkeyServiceProvider.overrideWithValue(hotkey),
      if (appLaunch != null)
        desktopAppLaunchServiceProvider.overrideWithValue(appLaunch),
      if (tray != null) trayServiceProvider.overrideWithValue(tray),
    ],
  );
}

CaptureService _captureService(AppDatabase database) {
  final local = LocalItemDataSource(database);
  final repository = ItemRepository(local, userId: null, onSaved: () async {});
  return CaptureService(repository);
}

class _FakeDesktopService extends DesktopService {
  int showCalls = 0;
  int hideCalls = 0;
  int showMainCalls = 0;
  int finishCalls = 0;
  final List<void Function()> blurListeners = [];
  final List<void Function()> closeListeners = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showQuickCapture() async {
    showCalls++;
  }

  @override
  Future<void> showMainWindow() async {
    showMainCalls++;
  }

  @override
  Future<void> hideMainWindow() async {
    hideCalls++;
  }

  @override
  Future<void> finishQuickCapture() async {
    finishCalls++;
  }

  @override
  Future<void> restoreMainWindow() async {}

  @override
  void addWindowBlurListener(void Function() onBlur) {
    blurListeners.add(onBlur);
  }

  @override
  void addWindowCloseListener(void Function() onClose) {
    closeListeners.add(onClose);
  }
}

class _ThrowingDesktopService extends _FakeDesktopService {
  @override
  Future<void> showQuickCapture() async {
    throw Exception('boom');
  }
}

class _FakeSelectionService extends SelectionCaptureService {
  const _FakeSelectionService({this.selection, this.appName});

  final String? selection;
  final String? appName;

  @override
  Future<String?> readSelectedText() async => selection;

  @override
  Future<String?> readFrontmostApplication() async => appName;
}

class _FakeClipboardService extends ClipboardCaptureService {
  _FakeClipboardService(this.text);

  final String? text;

  @override
  Future<String?> readText() async => text;
}

class _FakeHotkeyService extends GlobalHotkeyService {
  _FakeHotkeyService({required this.succeed});

  final bool succeed;
  DesktopShortcut? registered;

  @override
  Future<bool> register(
    DesktopShortcut shortcut, {
    required Future<void> Function() onTriggered,
  }) async {
    if (succeed) {
      registered = shortcut;
      return true;
    }
    return false;
  }

  @override
  Future<void> unregister() async {
    registered = null;
  }
}

class _FakeAppLaunchService extends DesktopAppLaunchService {
  _FakeAppLaunchService({required this.launchedAtLogin});

  final bool launchedAtLogin;

  @override
  Future<bool> wasLaunchedAtLogin() async => launchedAtLogin;

  @override
  Future<bool> isLoginItemEnabled() async => false;

  @override
  Future<bool> setLoginItemEnabled(bool enabled) async => true;
}

class _FakeTrayService extends TrayService {
  DesktopMenuState? lastState;
  int initCalls = 0;
  int destroyCalls = 0;
  int updateCalls = 0;

  @override
  Future<void> init({
    required Future<void> Function() onQuickCapture,
    required Future<void> Function() onOpenLaterBox,
    required Future<void> Function() onOpenSettings,
    required Future<void> Function() onQuit,
  }) async {
    initCalls++;
  }

  @override
  Future<void> updateMenu(DesktopMenuState state) async {
    lastState = state;
    updateCalls++;
  }

  @override
  Future<void> destroy() async {
    destroyCalls++;
  }
}

import 'dart:async';

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:menu_base/menu_base.dart';
import 'package:tray_manager/tray_manager.dart';

import 'tray_menu_state.dart';

/// Menu-bar (macOS) / system tray (Windows/Linux) integration.
///
/// Owns a [TrayListener] for the entire app lifetime so clicks and menu items
/// keep working after the window is hidden. The menu is rebuilt whenever
/// [updateMenu] is called with fresh account/sync state.
class TrayService {
  bool _initialized = false;
  DesktopMenuState _menuState = DesktopMenuState(
    accountStatus: DesktopMenuAccountStatus.guest,
    quickCaptureShortcutLabel: '⌥ Space',
  );
  final _listener = _TrayListener();

  Future<void> init({
    required Future<void> Function() onQuickCapture,
    required Future<void> Function() onOpenLaterBox,
    required Future<void> Function() onOpenSettings,
    required Future<void> Function() onQuit,
  }) async {
    if (_initialized) return;
    _initialized = true;

    _listener.onQuickCapture = onQuickCapture;
    _listener.onOpenLaterBox = onOpenLaterBox;
    _listener.onOpenSettings = onOpenSettings;
    _listener.onQuit = onQuit;
    trayManager.addListener(_listener);

    try {
      await trayManager.setIcon(
        'assets/branding/laterbox-menu-icon.png',
        isTemplate: Platform.isMacOS,
        iconSize: 16,
      );
      await trayManager.setToolTip('LaterBox');
      await _applyMenu();
      debugPrint('[LaterBox Desktop] tray initialized');
    } on PlatformException catch (error) {
      debugPrint('LaterBox tray could not be created: ${error.message}');
    }
  }

  /// Refreshes the account/sync section and the shortcut label in the menu.
  Future<void> updateMenu(DesktopMenuState state) async {
    _menuState = state;
    if (_initialized) {
      await _applyMenu();
    }
  }

  Future<void> _applyMenu() async {
    final state = _menuState;
    final statusLines = state.statusLines();
    final items = <MenuItem>[
      MenuItem(key: 'title', label: 'LaterBox', disabled: true),
      MenuItem(
        key: 'quick_capture',
        label: 'Quick Capture   ${state.quickCaptureShortcutLabel}',
      ),
      MenuItem(key: 'open_laterbox', label: 'Open LaterBox'),
      MenuItem.separator(),
      for (final line in statusLines)
        MenuItem(key: 'status_$line', label: line, disabled: true),
      MenuItem.separator(),
      MenuItem(key: 'settings', label: 'Settings…'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit LaterBox   ⌘Q'),
    ];
    await trayManager.setContextMenu(Menu(items: items));
  }

  Future<void> destroy() async {
    if (!_initialized) return;
    trayManager.removeListener(_listener);
    await trayManager.destroy();
    _initialized = false;
  }
}

class _TrayListener extends TrayListener {
  Future<void> Function()? onQuickCapture;
  Future<void> Function()? onOpenLaterBox;
  Future<void> Function()? onOpenSettings;
  Future<void> Function()? onQuit;

  @override
  void onTrayIconMouseDown() {
    debugPrint('[LaterBox Desktop] tray clicked');
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem item) {
    debugPrint('[LaterBox Desktop] tray menu: ${item.key}');
    void run(Future<void> Function()? callback) {
      callback?.call().catchError(
            (Object error, StackTrace stackTrace) {
              debugPrint('[LaterBox Desktop] tray action FAILED: $error');
              debugPrintStack(stackTrace: stackTrace);
            },
          );
    }

    switch (item.key) {
      case 'quick_capture':
        debugPrint('[LaterBox Desktop] invoking quick capture callback');
        run(onQuickCapture);
        break;
      case 'open_laterbox':
        debugPrint('[LaterBox Desktop] invoking open laterbox callback');
        run(onOpenLaterBox);
        break;
      case 'settings':
        debugPrint('[LaterBox Desktop] invoking open settings callback');
        run(onOpenSettings);
        break;
      case 'quit':
        run(onQuit);
        break;
    }
  }
}
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:menu_base/menu_base.dart';
import 'package:tray_manager/tray_manager.dart';

/// Menu-bar (macOS) / system tray (Windows/Linux) integration.
///
/// Owns a [TrayListener] for the entire app lifetime so clicks and menu items
/// keep working after the window is hidden.
class TrayService {
  bool _initialized = false;
  final _listener = _TrayListener();

  Future<void> init({
    required Future<void> Function() onQuickCapture,
    required Future<void> Function() onOpenLaterBox,
    required Future<void> Function() onQuit,
  }) async {
    if (_initialized) return;
    _initialized = true;

    _listener.onQuickCapture = onQuickCapture;
    _listener.onOpenLaterBox = onOpenLaterBox;
    _listener.onQuit = onQuit;
    trayManager.addListener(_listener);

    try {
      await trayManager.setIcon(
        'assets/branding/laterbox-menu-icon.png',
        isTemplate: Platform.isMacOS,
        iconSize: 16,
      );
      await trayManager.setToolTip('LaterBox');
      await trayManager.setContextMenu(
        Menu(items: [
          MenuItem(key: 'quick_capture', label: 'Quick Capture'),
          MenuItem(key: 'open_laterbox', label: 'Open LaterBox'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: 'Quit LaterBox'),
        ]),
      );
      debugPrint('[LaterBox Desktop] tray initialized');
    } on PlatformException catch (error) {
      debugPrint('LaterBox tray could not be created: ${error.message}');
    }
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
  Future<void> Function()? onQuit;

  @override
  void onTrayIconMouseDown() {
    debugPrint('[LaterBox Desktop] tray clicked');
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem item) {
    debugPrint('[LaterBox Desktop] tray menu: ${item.key}');
    switch (item.key) {
      case 'quick_capture':
        debugPrint('[LaterBox Desktop] invoking quick capture callback');
        onQuickCapture?.call().catchError(
              (Object error, StackTrace stackTrace) {
                debugPrint(
                  '[LaterBox Desktop] tray quick capture FAILED: $error',
                );
                debugPrintStack(stackTrace: stackTrace);
              },
            );
        break;
      case 'open_laterbox':
        debugPrint('[LaterBox Desktop] invoking open laterbox callback');
        onOpenLaterBox?.call().catchError(
              (Object error, StackTrace stackTrace) {
                debugPrint(
                  '[LaterBox Desktop] tray open laterbox FAILED: $error',
                );
                debugPrintStack(stackTrace: stackTrace);
              },
            );
        break;
      case 'quit':
        onQuit?.call().catchError(
              (Object error, StackTrace stackTrace) {
                debugPrint('[LaterBox Desktop] tray quit FAILED: $error');
                debugPrintStack(stackTrace: stackTrace);
              },
            );
        break;
    }
  }
}
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:menu_base/menu_base.dart';
import 'package:tray_manager/tray_manager.dart';

/// Menu-bar (macOS) / system tray (Windows/Linux) integration.
class TrayService {
  bool _initialized = false;
  final _listener = _TrayListener();

  Future<void> init({
    required void Function() onQuickCapture,
    required void Function() onOpenLaterBox,
    required void Function() onQuit,
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
        isTemplate: true,
        iconSize: 16,
      );
      await trayManager.setToolTip('LaterBox');
      await trayManager.setContextMenu(
        Menu(items: [
          MenuItem(
            key: 'quick-capture',
            label: 'Quick Capture',
            onClick: (_) => onQuickCapture(),
          ),
          MenuItem(
            key: 'open-laterbox',
            label: 'Open LaterBox',
            onClick: (_) => onOpenLaterBox(),
          ),
          MenuItem.separator(),
          MenuItem(
            key: 'quit',
            label: 'Quit LaterBox',
            onClick: (_) => onQuit(),
          ),
        ]),
      );
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
  void Function()? onQuickCapture;
  void Function()? onOpenLaterBox;
  void Function()? onQuit;

  @override
  void onTrayIconMouseDown() => onQuickCapture?.call();
}
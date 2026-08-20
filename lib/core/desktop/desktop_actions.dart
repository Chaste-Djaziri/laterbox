import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/router/app_router.dart';
import '../../core/settings/desktop_settings.dart';
import '../../core/settings/desktop_shortcut.dart';
import '../../core/settings/settings_providers.dart';
import 'desktop_providers.dart';
import 'tray_menu_state.dart';

/// Single owner of every desktop action.
///
/// The global hotkey and the tray both call back into this object; no other
/// code decides what “quick capture”, “open laterbox” or “settings” means.
/// Startup wires the current settings into the hotkey, the menu-bar menu, the
/// launch-at-login preference and the window-close policy.
class DesktopActions {
  DesktopActions(this.ref);

  final Ref ref;

  DesktopSettings _settings = DesktopSettings.defaults();

  DesktopSettings get settings => _settings;

  /// One-time desktop startup: apply persisted settings, then register the
  /// hotkey, tray and window-close policy. Hides the main window when the app
  /// was started by the login item so it runs quietly in the menu bar.
  Future<void> applyStartup() async {
    debugPrint('[LaterBox Desktop] applying startup settings');
    _settings = await ref.read(desktopSettingsStoreProvider).load();
    final desktop = ref.read(desktopServiceProvider);
    await desktop.initialize();

    final controller = ref.read(quickCaptureControllerProvider);
    controller.enableBlurClose = _settings.closeOnFocusLoss;

    await ref
        .read(globalHotkeyServiceProvider)
        .register(_settings.quickCaptureShortcut, onTriggered: openQuickCapture);

    if (_settings.showInMenuBar) {
      await ref
          .read(trayServiceProvider)
          .init(
            onQuickCapture: openQuickCapture,
            onOpenLaterBox: openLaterBox,
            onOpenSettings: openSettings,
            onQuit: ref.read(desktopServiceProvider).quit,
          );
    }

    ref.listen(authStateProvider, (_, __) {
      unawaited(refreshTrayMenu());
    });
    unawaited(_watchConnectivity());

    // The window only needs to appear when the user explicitly opens LaterBox.
    if (await ref.read(desktopAppLaunchServiceProvider).wasLaunchedAtLogin()) {
      await desktop.hideMainWindow();
    }

    desktop.addWindowCloseListener(_onMainWindowClose);
    await refreshTrayMenu();
    debugPrint('[LaterBox Desktop] startup complete');
  }

  void _onMainWindowClose() {
    final controller = ref.read(quickCaptureControllerProvider);
    final desktop = ref.read(desktopServiceProvider);
    if (controller.isActive) {
      unawaited(finishQuickCapture());
    } else if (_settings.keepRunningOnWindowClose) {
      unawaited(desktop.hideMainWindow());
    } else {
      unawaited(desktop.quit());
    }
  }

  Future<void> _watchConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.none)) {
        await refreshTrayMenu();
      }
      Connectivity().onConnectivityChanged.listen((_) async {
        await refreshTrayMenu();
      });
    } on Object catch (error, stackTrace) {
      debugPrint('[LaterBox Desktop] connectivity watch failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Rebuilds the account/sync section of the menu-bar menu.
  Future<void> refreshTrayMenu() async {
    try {
      final auth = ref.read(authStateProvider).asData?.value;
      final isAuthenticated = auth?.isAuthenticated ?? false;
      final results = await Connectivity().checkConnectivity();
      final online = !results.contains(ConnectivityResult.none);

      final DesktopMenuAccountStatus status;
      if (!isAuthenticated) {
        status = DesktopMenuAccountStatus.guest;
      } else if (online) {
        status = DesktopMenuAccountStatus.synced;
      } else {
        status = DesktopMenuAccountStatus.offline;
      }

      final state = DesktopMenuState(
        accountStatus: status,
        quickCaptureShortcutLabel: _settings.quickCaptureShortcut.displayLabel,
        email: auth?.email,
      );
      await ref.read(trayServiceProvider).updateMenu(state);
    } on Object catch (error, stackTrace) {
      debugPrint('[LaterBox Desktop] tray menu refresh FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// ⌥Space / tray “Quick Capture”: resolve the capture context, enter capture
  /// mode, then show the window.
  Future<void> openQuickCapture() async {
    debugPrint('[LaterBox Desktop] openQuickCapture requested');

    try {
      final context = await ref
          .read(desktopCaptureContextResolverProvider)
          .resolve(useSelection: _settings.useSelectedText);
      debugPrint(
        '[LaterBox Desktop] context: ${context.type}'
        '${context.sourceApplication == null ? '' : ' from ${context.sourceApplication}'}'
        ' (${context.value.length} chars)',
      );

      final controller = ref.read(quickCaptureControllerProvider);
      final desktop = ref.read(desktopServiceProvider);

      debugPrint('[LaterBox Desktop] entering quick capture mode');
      await controller.open(context: context);
      debugPrint('[LaterBox Desktop] controller opened');

      await desktop.showQuickCapture();
      debugPrint('[LaterBox Desktop] openQuickCapture complete');
    } catch (error, stackTrace) {
      debugPrint('[LaterBox Desktop] openQuickCapture FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Tray “Open LaterBox”: close any capture state and show the main window.
  Future<void> openLaterBox() async {
    debugPrint('[LaterBox Desktop] openLaterBox requested');

    try {
      final controller = ref.read(quickCaptureControllerProvider);
      final desktop = ref.read(desktopServiceProvider);

      await controller.close();
      await desktop.showMainWindow();
      debugPrint('[LaterBox Desktop] openLaterBox complete');
    } catch (error, stackTrace) {
      debugPrint('[LaterBox Desktop] openLaterBox FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// After a save or `Esc`: restore the pre-capture window, or hide it if the
  /// main window was hidden before quick capture.
  Future<void> finishQuickCapture() async {
    debugPrint('[LaterBox Desktop] finishQuickCapture requested');

    try {
      await ref.read(desktopServiceProvider).finishQuickCapture();
      debugPrint('[LaterBox Desktop] finishQuickCapture complete');
    } catch (error, stackTrace) {
      debugPrint('[LaterBox Desktop] finishQuickCapture FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Tray “Settings…”: close capture state, show the window and open Settings.
  Future<void> openSettings() async {
    debugPrint('[LaterBox Desktop] openSettings requested');

    try {
      final controller = ref.read(quickCaptureControllerProvider);
      final desktop = ref.read(desktopServiceProvider);

      await controller.close();
      await desktop.showMainWindow();
      await ref.read(appRouterProvider).push('/settings');
      debugPrint('[LaterBox Desktop] openSettings complete');
    } catch (error, stackTrace) {
      debugPrint('[LaterBox Desktop] openSettings FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  /// Atomically switches the quick capture shortcut.
  ///
  /// Registers the replacement first and only unregisters the old shortcut
  /// (and persists) once the new one is confirmed. On failure the existing
  /// shortcut keeps working untouched.
  Future<bool> changeQuickCaptureShortcut(DesktopShortcut shortcut) async {
    final hotkey = ref.read(globalHotkeyServiceProvider);
    if (hotkey.isRegistered && hotkey.current.isSameAs(shortcut)) {
      return true;
    }

    final registered = await hotkey.register(shortcut, onTriggered: openQuickCapture);
    if (!registered) {
      debugPrint('[LaterBox Desktop] shortcut change rejected: ${shortcut.displayLabel}');
      return false;
    }

    _settings = _settings.copyWith(quickCaptureShortcut: shortcut);
    await ref
        .read(desktopSettingsStoreProvider)
        .setQuickCaptureShortcut(shortcut);
    await refreshTrayMenu();
    debugPrint('[LaterBox Desktop] shortcut changed to: ${shortcut.displayLabel}');
    return true;
  }

  Future<void> setLaunchAtLogin(bool enabled) async {
    _settings = _settings.copyWith(launchAtLogin: enabled);
    await ref.read(desktopSettingsStoreProvider).setLaunchAtLogin(enabled);
    await ref.read(desktopAppLaunchServiceProvider).setLoginItemEnabled(enabled);
  }

  Future<void> setKeepRunningOnWindowClose(bool enabled) async {
    _settings = _settings.copyWith(keepRunningOnWindowClose: enabled);
    await ref
        .read(desktopSettingsStoreProvider)
        .setKeepRunningOnWindowClose(enabled);
  }

  Future<void> setShowInMenuBar(bool enabled) async {
    _settings = _settings.copyWith(showInMenuBar: enabled);
    await ref.read(desktopSettingsStoreProvider).setShowInMenuBar(enabled);
    if (!enabled) {
      await ref.read(trayServiceProvider).destroy();
    }
  }

  Future<void> setUseSelectedText(bool enabled) async {
    _settings = _settings.copyWith(useSelectedText: enabled);
    await ref.read(desktopSettingsStoreProvider).setUseSelectedText(enabled);
  }

  Future<void> setCloseOnFocusLoss(bool enabled) async {
    _settings = _settings.copyWith(closeOnFocusLoss: enabled);
    await ref.read(desktopSettingsStoreProvider).setCloseOnFocusLoss(enabled);
    ref.read(quickCaptureControllerProvider).enableBlurClose = enabled;
  }
}

final desktopActionsProvider = Provider<DesktopActions>((ref) {
  return DesktopActions(ref);
});
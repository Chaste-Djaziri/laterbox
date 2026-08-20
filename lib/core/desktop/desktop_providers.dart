import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/capture/domain/capture_providers.dart';
import '../auth/auth_provider.dart';
import '../settings/desktop_settings.dart';
import '../settings/settings_providers.dart';
import 'clipboard_capture_service.dart';
import 'desktop_app_launch_service.dart';
import 'desktop_capture_context_resolver.dart';
import 'desktop_service.dart';
import 'global_hotkey_service.dart';
import 'quick_capture_controller.dart';
import 'selection_capture_service.dart';
import 'tray_menu_state.dart';
import 'tray_service.dart';

final desktopServiceProvider = Provider<DesktopService>((ref) {
  final service = DesktopService();
  ref.onDispose(service.dispose);
  return service;
});

final globalHotkeyServiceProvider = Provider<GlobalHotkeyService>((ref) {
  return GlobalHotkeyService();
});

final trayServiceProvider = Provider<TrayService>((ref) {
  return TrayService();
});

final clipboardCaptureServiceProvider =
    Provider<ClipboardCaptureService>((ref) {
  return const ClipboardCaptureService();
});

final selectionCaptureServiceProvider = Provider<SelectionCaptureService>(
  (ref) => const SelectionCaptureService(),
);

final desktopCaptureContextResolverProvider =
    Provider<DesktopCaptureContextResolver>((ref) {
  return DesktopCaptureContextResolver(
    selectionService: ref.watch(selectionCaptureServiceProvider),
    clipboardService: ref.watch(clipboardCaptureServiceProvider),
  );
});

final desktopAppLaunchServiceProvider =
    Provider<DesktopAppLaunchService>((ref) {
  return const DesktopAppLaunchService();
});

/// Whether the host app holds Accessibility permission (`AXIsProcessTrusted`).
final accessibilityTrustedProvider = FutureProvider<bool>((ref) {
  return ref.watch(selectionCaptureServiceProvider).isAccessibilityTrusted();
});

final quickCaptureControllerProvider =
    ChangeNotifierProvider<QuickCaptureController>((ref) {
  // ChangeNotifierProvider disposes its notifier automatically; do not
  // register an additional `ref.onDispose(controller.dispose)` here or the
  // controller is disposed twice.
  final controller = QuickCaptureController(
    desktopService: ref.watch(desktopServiceProvider),
    clipboardService: ref.watch(clipboardCaptureServiceProvider),
    captureService: ref.watch(captureServiceProvider),
  );

  // Sync blurClose setting from DesktopSettings
  final settings = ref.watch(desktopSettingsProvider).valueOrNull ?? DesktopSettings.defaults();
  controller.enableBlurClose = settings.closeOnFocusLoss;

  return controller;
});

final desktopMenuStateProvider = Provider<DesktopMenuState>((ref) {
  final settings = ref.watch(desktopSettingsProvider).valueOrNull ?? DesktopSettings.defaults();
  final authAsync = ref.watch(authStateProvider);
  final isGuest = ref.watch(guestModeProvider);

  final authState = authAsync.valueOrNull;
  final email = authState?.email;

  final DesktopMenuAccountStatus status;
  if (authState != null && authState.isAuthenticated) {
    status = DesktopMenuAccountStatus.synced;
  } else if (isGuest) {
    status = DesktopMenuAccountStatus.guest;
  } else {
    status = DesktopMenuAccountStatus.offline;
  }

  return DesktopMenuState(
    accountStatus: status,
    quickCaptureShortcutLabel: settings.quickCaptureShortcut.displayLabel,
    email: email,
  );
});
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/capture/domain/capture_providers.dart';
import 'clipboard_capture_service.dart';
import 'desktop_service.dart';
import 'global_hotkey_service.dart';
import 'quick_capture_controller.dart';
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

final quickCaptureControllerProvider =
    ChangeNotifierProvider<QuickCaptureController>((ref) {
  final controller = QuickCaptureController(
    desktopService: ref.watch(desktopServiceProvider),
    clipboardService: ref.watch(clipboardCaptureServiceProvider),
    captureService: ref.watch(captureServiceProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
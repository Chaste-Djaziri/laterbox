import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

import 'desktop_capabilities.dart';
import 'selection_capture_service.dart';

enum NotchDisplayMode {
  fullWindow,
  notchPill,
  notchIsland,
}

const notchPillSize = Size(280, 44);
const notchIslandSize = Size(520, 240);
const defaultMainWindowSize = Size(1100, 720);
const defaultMainWindowMinimumSize = Size(480, 400);

class DesktopNotchService extends ChangeNotifier {
  DesktopNotchService([SelectionCaptureService? captureService])
      : _captureService = captureService ?? const SelectionCaptureService();

  final SelectionCaptureService _captureService;

  NotchDisplayMode _mode = NotchDisplayMode.fullWindow;
  Rect? _savedBounds;
  bool _savedWasMaximized = false;

  NotchDisplayMode get mode => _mode;
  bool get isDockedToNotch =>
      _mode == NotchDisplayMode.notchPill || _mode == NotchDisplayMode.notchIsland;
  bool get isIslandExpanded => _mode == NotchDisplayMode.notchIsland;

  /// Docks the LaterBox window directly under the top screen notch (macOS).
  Future<void> dockToNotch({bool expandIsland = false}) async {
    if (!isDesktopSupported) return;

    try {
      // Save current full window state if we are transitioning from full window.
      if (_mode == NotchDisplayMode.fullWindow) {
        _savedBounds = await windowManager.getBounds();
        _savedWasMaximized = await windowManager.isMaximized();
      }

      final targetMode =
          expandIsland ? NotchDisplayMode.notchIsland : NotchDisplayMode.notchPill;
      final targetSize =
          expandIsland ? notchIslandSize : notchPillSize;

      _mode = targetMode;
      notifyListeners();

      if (await windowManager.isMinimized()) {
        await windowManager.restore();
      }

      final targetPos = await _calculateNotchPosition(targetSize.width);

      await windowManager.setMinimumSize(targetSize);
      await windowManager.setSize(targetSize, animate: false);
      await windowManager.setPosition(targetPos, animate: false);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.show();
      await windowManager.focus();
    } catch (e, stack) {
      debugPrint('[LaterBox Notch] failed to dock to notch: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  /// Expands the notch pill into the rich Dynamic Island card.
  Future<void> expandIsland() async {
    if (!isDesktopSupported) return;
    if (_mode == NotchDisplayMode.notchIsland) return;

    try {
      _mode = NotchDisplayMode.notchIsland;
      notifyListeners();

      final targetPos = await _calculateNotchPosition(notchIslandSize.width);
      await windowManager.setMinimumSize(notchIslandSize);
      await windowManager.setSize(notchIslandSize, animate: false);
      await windowManager.setPosition(targetPos, animate: false);
      await windowManager.setAlwaysOnTop(true);
      await windowManager.focus();
    } catch (e) {
      debugPrint('[LaterBox Notch] expandIsland failed: $e');
    }
  }

  /// Collapses the expanded island back into the sleek compact pill.
  Future<void> collapseToPill() async {
    if (!isDesktopSupported) return;
    if (_mode == NotchDisplayMode.notchPill) return;

    try {
      _mode = NotchDisplayMode.notchPill;
      notifyListeners();

      final targetPos = await _calculateNotchPosition(notchPillSize.width);
      await windowManager.setMinimumSize(notchPillSize);
      await windowManager.setSize(notchPillSize, animate: false);
      await windowManager.setPosition(targetPos, animate: false);
      await windowManager.setAlwaysOnTop(true);
    } catch (e) {
      debugPrint('[LaterBox Notch] collapseToPill failed: $e');
    }
  }

  /// Toggles between collapsed pill and expanded island.
  Future<void> toggleIsland() async {
    if (_mode == NotchDisplayMode.notchIsland) {
      await collapseToPill();
    } else {
      await expandIsland();
    }
  }

  /// Restores LaterBox to its full standard window.
  Future<void> expandToFullWindow() async {
    if (!isDesktopSupported) return;

    try {
      _mode = NotchDisplayMode.fullWindow;
      notifyListeners();

      await windowManager.setAlwaysOnTop(false);
      await windowManager.setMinimumSize(defaultMainWindowMinimumSize);

      if (_savedBounds != null) {
        await windowManager.setBounds(_savedBounds!, animate: false);
        if (_savedWasMaximized && await windowManager.isMaximizable()) {
          await windowManager.maximize();
        }
      } else {
        await windowManager.setSize(defaultMainWindowSize, animate: false);
        await windowManager.center();
      }

      await windowManager.show();
      await windowManager.focus();
    } catch (e) {
      debugPrint('[LaterBox Notch] expandToFullWindow failed: $e');
    }
  }

  Future<Offset> _calculateNotchPosition(double windowWidth) async {
    double screenWidth = 1440.0;
    try {
      if (Platform.isMacOS) {
        final geometry = await _captureService.getScreenGeometry();
        if (geometry != null && geometry['screenWidth'] is num) {
          screenWidth = (geometry['screenWidth'] as num).toDouble();
        }
      }
    } catch (_) {}

    final x = (screenWidth - windowWidth) / 2.0;
    return Offset(x, 0);
  }
}

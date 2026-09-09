import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'macos_companion.dart';
import 'selection_capture_service.dart';

enum NotchDisplayMode {
  fullWindow,
  notchPill,
  notchIsland,
}

class DesktopNotchService extends ChangeNotifier {
  DesktopNotchService([SelectionCaptureService? captureService])
      : captureService = captureService ?? const SelectionCaptureService();

  final SelectionCaptureService captureService;

  NotchDisplayMode _mode = NotchDisplayMode.fullWindow;

  NotchDisplayMode get mode => _mode;
  bool get isDockedToNotch =>
      _mode == NotchDisplayMode.notchPill || _mode == NotchDisplayMode.notchIsland;
  bool get isIslandExpanded => _mode == NotchDisplayMode.notchIsland;

  /// Shows the native floating notch companion panel on macOS.
  Future<void> dockToNotch({bool expandIsland = false}) async {
    _mode =
        expandIsland ? NotchDisplayMode.notchIsland : NotchDisplayMode.notchPill;
    notifyListeners();

    if (Platform.isMacOS) {
      await MacOSCompanion.showNotch();
    }
  }

  /// Expands the notch pill into the rich Dynamic Island card.
  Future<void> expandIsland() async {
    if (_mode == NotchDisplayMode.notchIsland) return;
    _mode = NotchDisplayMode.notchIsland;
    notifyListeners();
    if (Platform.isMacOS) {
      await MacOSCompanion.showNotch();
    }
  }

  /// Collapses the expanded island back into the sleek compact pill.
  Future<void> collapseToPill() async {
    if (_mode == NotchDisplayMode.notchPill) return;
    _mode = NotchDisplayMode.notchPill;
    notifyListeners();
  }

  /// Toggles between collapsed pill and expanded island.
  Future<void> toggleIsland() async {
    if (_mode == NotchDisplayMode.notchIsland) {
      await collapseToPill();
    } else {
      await expandIsland();
    }
  }

  /// Restores LaterBox to its full standard window (hiding the notch companion).
  Future<void> expandToFullWindow() async {
    _mode = NotchDisplayMode.fullWindow;
    notifyListeners();

    if (Platform.isMacOS) {
      await MacOSCompanion.hideNotch();
    }
  }
}

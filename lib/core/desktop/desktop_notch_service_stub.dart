import 'package:flutter/foundation.dart';

import 'selection_capture_service.dart';

enum NotchDisplayMode {
  fullWindow,
  notchPill,
  notchIsland,
}

class DesktopNotchService extends ChangeNotifier {
  DesktopNotchService([SelectionCaptureService? captureService]);

  NotchDisplayMode get mode => NotchDisplayMode.fullWindow;
  bool get isDockedToNotch => false;
  bool get isIslandExpanded => false;

  Future<void> dockToNotch({bool expandIsland = false}) async {}
  Future<void> expandIsland() async {}
  Future<void> collapseToPill() async {}
  Future<void> expandToFullWindow() async {}
  Future<void> toggleIsland() async {}
}

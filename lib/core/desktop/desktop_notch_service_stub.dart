import 'dart:ui';
import 'package:flutter/foundation.dart';

enum NotchDisplayMode {
  fullWindow,
  notchPill,
  notchIsland,
}

class DesktopNotchService extends ChangeNotifier {
  NotchDisplayMode get mode => NotchDisplayMode.fullWindow;
  bool get isDockedToNotch => false;
  bool get isIslandExpanded => false;

  Future<void> dockToNotch({bool expandIsland = false}) async {}
  Future<void> expandIsland() async {}
  Future<void> collapseToPill() async {}
  Future<void> expandToFullWindow() async {}
  Future<void> toggleIsland() async {}
}

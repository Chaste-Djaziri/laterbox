import 'package:flutter/foundation.dart';

/// Whether the current platform supports native desktop integration
/// (global hotkeys, window control, tray).
///
/// Safe to call on web and mobile; no `dart:io` is used here.
bool get isDesktopSupported {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux;
}

enum DesktopPlatform { macOS, windows, linux, unsupported }

DesktopPlatform get currentDesktopPlatform {
  if (kIsWeb) return DesktopPlatform.unsupported;
  switch (defaultTargetPlatform) {
    case TargetPlatform.macOS:
      return DesktopPlatform.macOS;
    case TargetPlatform.windows:
      return DesktopPlatform.windows;
    case TargetPlatform.linux:
      return DesktopPlatform.linux;
    default:
      return DesktopPlatform.unsupported;
  }
}
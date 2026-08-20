import 'dart:convert';

import 'desktop_shortcut.dart';

/// Persisted keys for the [AppSettings] key–value table.
abstract final class DesktopSettingsKeys {
  static const quickCaptureShortcut = 'desktop_quick_capture_shortcut';
  static const launchAtLogin = 'desktop_launch_at_login';
  static const keepRunningOnWindowClose = 'desktop_keep_running_on_window_close';
  static const showInMenuBar = 'desktop_show_in_menu_bar';
  static const useSelectedText = 'desktop_use_selected_text';
  static const closeOnFocusLoss = 'desktop_close_on_focus_loss';
}

/// The desktop-specific preferences behind the Settings screen.
class DesktopSettings {
  const DesktopSettings({
    required this.quickCaptureShortcut,
    required this.launchAtLogin,
    required this.keepRunningOnWindowClose,
    required this.showInMenuBar,
    required this.useSelectedText,
    required this.closeOnFocusLoss,
  });

  factory DesktopSettings.defaults() {
    return DesktopSettings(
      quickCaptureShortcut: DesktopShortcut.defaultQuickCapture(),
      launchAtLogin: false,
      keepRunningOnWindowClose: true,
      showInMenuBar: true,
      useSelectedText: true,
      closeOnFocusLoss: false,
    );
  }

  final DesktopShortcut quickCaptureShortcut;
  final bool launchAtLogin;
  final bool keepRunningOnWindowClose;
  final bool showInMenuBar;
  final bool useSelectedText;
  final bool closeOnFocusLoss;

  DesktopSettings copyWith({
    DesktopShortcut? quickCaptureShortcut,
    bool? launchAtLogin,
    bool? keepRunningOnWindowClose,
    bool? showInMenuBar,
    bool? useSelectedText,
    bool? closeOnFocusLoss,
  }) {
    return DesktopSettings(
      quickCaptureShortcut:
          quickCaptureShortcut ?? this.quickCaptureShortcut,
      launchAtLogin: launchAtLogin ?? this.launchAtLogin,
      keepRunningOnWindowClose:
          keepRunningOnWindowClose ?? this.keepRunningOnWindowClose,
      showInMenuBar: showInMenuBar ?? this.showInMenuBar,
      useSelectedText: useSelectedText ?? this.useSelectedText,
      closeOnFocusLoss: closeOnFocusLoss ?? this.closeOnFocusLoss,
    );
  }

  Map<String, String?> toKeyValues() => {
        DesktopSettingsKeys.quickCaptureShortcut:
            jsonEncode(quickCaptureShortcut.toJson()),
        DesktopSettingsKeys.launchAtLogin: launchAtLogin.toString(),
        DesktopSettingsKeys.keepRunningOnWindowClose:
            keepRunningOnWindowClose.toString(),
        DesktopSettingsKeys.showInMenuBar: showInMenuBar.toString(),
        DesktopSettingsKeys.useSelectedText: useSelectedText.toString(),
        DesktopSettingsKeys.closeOnFocusLoss: closeOnFocusLoss.toString(),
      };

  /// Merges a stored key–value snapshot over the [defaults], falling back to
  /// defaults for keys that are absent or malformed.
  factory DesktopSettings.fromKeyValues(Map<String, String?> values) {
    final defaults = DesktopSettings.defaults();

    DesktopShortcut shortcut() {
      final raw = values[DesktopSettingsKeys.quickCaptureShortcut];
      if (raw == null) return defaults.quickCaptureShortcut;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) return defaults.quickCaptureShortcut;
        return DesktopShortcut.fromJson(decoded);
      } on FormatException {
        return defaults.quickCaptureShortcut;
      }
    }

    bool boolFor(String key, bool fallback) {
      final raw = values[key];
      return raw == null ? fallback : (raw == 'true');
    }

    return DesktopSettings(
      quickCaptureShortcut: shortcut(),
      launchAtLogin: boolFor(
        DesktopSettingsKeys.launchAtLogin,
        defaults.launchAtLogin,
      ),
      keepRunningOnWindowClose: boolFor(
        DesktopSettingsKeys.keepRunningOnWindowClose,
        defaults.keepRunningOnWindowClose,
      ),
      showInMenuBar: boolFor(
        DesktopSettingsKeys.showInMenuBar,
        defaults.showInMenuBar,
      ),
      useSelectedText: boolFor(
        DesktopSettingsKeys.useSelectedText,
        defaults.useSelectedText,
      ),
      closeOnFocusLoss: boolFor(
        DesktopSettingsKeys.closeOnFocusLoss,
        defaults.closeOnFocusLoss,
      ),
    );
  }
}
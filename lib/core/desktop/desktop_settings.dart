import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DesktopShortcut {
  const DesktopShortcut({
    required this.key,
    required this.modifiers,
  });

  final PhysicalKeyboardKey key;
  final List<HotKeyModifier> modifiers;

  HotKey toHotKey() {
    return HotKey(
      key,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );
  }

  String get label {
    final buffer = StringBuffer();
    for (final mod in modifiers) {
      switch (mod) {
        case HotKeyModifier.alt:
          buffer.write('⌥ ');
          break;
        case HotKeyModifier.control:
          buffer.write('⌃ ');
          break;
        case HotKeyModifier.meta:
          buffer.write('⌘ ');
          break;
        case HotKeyModifier.shift:
          buffer.write('⇧ ');
          break;
      }
    }
    final rawName = key.debugName ?? '';
    final cleanName = rawName.isEmpty ? 'Space' : rawName.replaceAll('Key ', '');
    buffer.write(cleanName);
    return buffer.toString().trim();
  }

  Map<String, dynamic> toJson() {
    return {
      'usbHidUsage': key.usbHidUsage,
      'modifiers': modifiers.map((m) => m.name).toList(),
    };
  }

  factory DesktopShortcut.fromJson(Map<String, dynamic> json) {
    final usbHid = json['usbHidUsage'] as int? ?? PhysicalKeyboardKey.space.usbHidUsage;
    final modNames = (json['modifiers'] as List<dynamic>?)?.cast<String>() ?? ['alt'];
    final mods = modNames
        .map((n) {
          switch (n) {
            case 'alt':
              return HotKeyModifier.alt;
            case 'control':
              return HotKeyModifier.control;
            case 'meta':
              return HotKeyModifier.meta;
            case 'shift':
              return HotKeyModifier.shift;
            default:
              return null;
          }
        })
        .whereType<HotKeyModifier>()
        .toList();

    return DesktopShortcut(
      key: PhysicalKeyboardKey.findKeyByCode(usbHid) ?? PhysicalKeyboardKey.space,
      modifiers: mods.isEmpty ? [HotKeyModifier.alt] : mods,
    );
  }

  static const defaultShortcut = DesktopShortcut(
    key: PhysicalKeyboardKey.space,
    modifiers: [HotKeyModifier.alt],
  );
}

class DesktopSettings {
  const DesktopSettings({
    this.shortcut = DesktopShortcut.defaultShortcut,
    this.keepRunningOnClose = true,
    this.launchAtLogin = false,
    this.showInMenuBar = true,
    this.useSelectedText = true,
    this.blurCloseOnFocusLost = false,
  });

  final DesktopShortcut shortcut;
  final bool keepRunningOnClose;
  final bool launchAtLogin;
  final bool showInMenuBar;
  final bool useSelectedText;
  final bool blurCloseOnFocusLost;

  DesktopSettings copyWith({
    DesktopShortcut? shortcut,
    bool? keepRunningOnClose,
    bool? launchAtLogin,
    bool? showInMenuBar,
    bool? useSelectedText,
    bool? blurCloseOnFocusLost,
  }) {
    return DesktopSettings(
      shortcut: shortcut ?? this.shortcut,
      keepRunningOnClose: keepRunningOnClose ?? this.keepRunningOnClose,
      launchAtLogin: launchAtLogin ?? this.launchAtLogin,
      showInMenuBar: showInMenuBar ?? this.showInMenuBar,
      useSelectedText: useSelectedText ?? this.useSelectedText,
      blurCloseOnFocusLost: blurCloseOnFocusLost ?? this.blurCloseOnFocusLost,
    );
  }
}

class DesktopSettingsNotifier extends StateNotifier<DesktopSettings> {
  DesktopSettingsNotifier([SharedPreferences? prefs])
      : _prefs = prefs,
        super(const DesktopSettings()) {
    _loadSettings();
  }

  final SharedPreferences? _prefs;

  static const _keyShortcut = 'desktop_shortcut';
  static const _keyKeepRunning = 'desktop_keep_running';
  static const _keyLaunchAtLogin = 'desktop_launch_at_login';
  static const _keyShowInMenuBar = 'desktop_show_in_menu_bar';
  static const _keyUseSelectedText = 'desktop_use_selected_text';
  static const _keyBlurClose = 'desktop_blur_close';

  Future<void> _loadSettings() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();

    DesktopShortcut shortcut = DesktopShortcut.defaultShortcut;
    final shortcutJsonStr = prefs.getString(_keyShortcut);
    if (shortcutJsonStr != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(shortcutJsonStr);
        shortcut = DesktopShortcut.fromJson(json);
      } catch (_) {}
    }

    state = DesktopSettings(
      shortcut: shortcut,
      keepRunningOnClose: prefs.getBool(_keyKeepRunning) ?? true,
      launchAtLogin: prefs.getBool(_keyLaunchAtLogin) ?? false,
      showInMenuBar: prefs.getBool(_keyShowInMenuBar) ?? true,
      useSelectedText: prefs.getBool(_keyUseSelectedText) ?? true,
      blurCloseOnFocusLost: prefs.getBool(_keyBlurClose) ?? false,
    );
  }

  Future<void> updateShortcut(DesktopShortcut newShortcut) async {
    state = state.copyWith(shortcut: newShortcut);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyShortcut, jsonEncode(newShortcut.toJson()));
  }

  Future<void> setKeepRunningOnClose(bool value) async {
    state = state.copyWith(keepRunningOnClose: value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyKeepRunning, value);
  }

  Future<void> setLaunchAtLogin(bool value) async {
    state = state.copyWith(launchAtLogin: value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyLaunchAtLogin, value);
  }

  Future<void> setShowInMenuBar(bool value) async {
    state = state.copyWith(showInMenuBar: value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowInMenuBar, value);
  }

  Future<void> setUseSelectedText(bool value) async {
    state = state.copyWith(useSelectedText: value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseSelectedText, value);
  }

  Future<void> setBlurCloseOnFocusLost(bool value) async {
    state = state.copyWith(blurCloseOnFocusLost: value);
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(_keyBlurClose, value);
  }
}

final desktopSettingsProvider =
    StateNotifierProvider<DesktopSettingsNotifier, DesktopSettings>((ref) {
  return DesktopSettingsNotifier();
});

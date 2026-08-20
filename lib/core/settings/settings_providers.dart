import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_providers.dart';
import 'desktop_settings.dart';
import 'desktop_shortcut.dart';

final desktopSettingsStoreProvider = Provider<DesktopSettingsStore>((ref) {
  return DesktopSettingsStore(ref.watch(appDatabaseProvider));
});

/// Emits the merged desktop settings whenever any stored value changes.
final desktopSettingsProvider = StreamProvider<DesktopSettings>((ref) {
  return ref.watch(desktopSettingsStoreProvider).watch();
});

/// Loads and persists the desktop settings through the app's key–value store.
class DesktopSettingsStore {
  DesktopSettingsStore(this._db);

  final AppDatabase _db;

  Future<DesktopSettings> load() async {
    final values = await _readAll();
    return DesktopSettings.fromKeyValues(values);
  }

  Stream<DesktopSettings> watch() {
    return _db.watchAllSettings().map((rows) {
      final values = {for (final row in rows) row.key: row.value};
      return DesktopSettings.fromKeyValues(values);
    });
  }

  Future<void> setQuickCaptureShortcut(DesktopShortcut shortcut) {
    return _db.writeSetting(
      DesktopSettingsKeys.quickCaptureShortcut,
      jsonEncode(shortcut.toJson()),
    );
  }

  Future<void> setLaunchAtLogin(bool enabled) {
    return _db.writeSetting(
      DesktopSettingsKeys.launchAtLogin,
      enabled.toString(),
    );
  }

  Future<void> setKeepRunningOnWindowClose(bool enabled) {
    return _db.writeSetting(
      DesktopSettingsKeys.keepRunningOnWindowClose,
      enabled.toString(),
    );
  }

  Future<void> setShowInMenuBar(bool enabled) {
    return _db.writeSetting(DesktopSettingsKeys.showInMenuBar, enabled.toString());
  }

  Future<void> setUseSelectedText(bool enabled) {
    return _db.writeSetting(
      DesktopSettingsKeys.useSelectedText,
      enabled.toString(),
    );
  }

  Future<void> setCloseOnFocusLoss(bool enabled) {
    return _db.writeSetting(DesktopSettingsKeys.closeOnFocusLoss, enabled.toString());
  }

  Future<Map<String, String?>> _readAll() async {
    final rows = await _db.watchAllSettings().first;
    return {for (final row in rows) row.key: row.value};
  }
}
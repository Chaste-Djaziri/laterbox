import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../database/database_providers.dart';

const itemViewModeSettingKey = 'item_view_mode';

/// Visual display modes for item lists across LaterBox.
enum ItemViewMode {
  cards,
  list;

  bool get isCards => this == ItemViewMode.cards;
  bool get isList => this == ItemViewMode.list;

  String get label => switch (this) {
        ItemViewMode.cards => 'Cards',
        ItemViewMode.list => 'List',
      };

  IconData get icon => switch (this) {
        ItemViewMode.cards => Icons.grid_view_rounded,
        ItemViewMode.list => Icons.view_list_rounded,
      };

  String get tooltip => switch (this) {
        ItemViewMode.cards => 'Cards view',
        ItemViewMode.list => 'List view',
      };
}

final itemViewModeProvider =
    StateNotifierProvider<ItemViewModeNotifier, ItemViewMode>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ItemViewModeNotifier(db);
});

class ItemViewModeNotifier extends StateNotifier<ItemViewMode> {
  ItemViewModeNotifier(this._db) : super(ItemViewMode.cards) {
    _init();
  }

  final AppDatabase _db;
  StreamSubscription<List<AppSetting>>? _sub;

  void _init() {
    _sub = _db.watchAllSettings().listen((rows) {
      for (final row in rows) {
        if (row.key == itemViewModeSettingKey) {
          final mode = ItemViewMode.values.firstWhere(
            (m) => m.name == row.value,
            orElse: () => ItemViewMode.cards,
          );
          if (state != mode) {
            state = mode;
          }
          return;
        }
      }
    });
  }

  Future<void> setViewMode(ItemViewMode mode) async {
    if (state == mode) return;
    state = mode;
    await _db.writeSetting(itemViewModeSettingKey, mode.name);
  }

  Future<void> toggle() async {
    final next =
        state == ItemViewMode.cards ? ItemViewMode.list : ItemViewMode.cards;
    await setViewMode(next);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

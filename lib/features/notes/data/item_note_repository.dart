import 'dart:async';

import '../../../core/database/app_database.dart';
import 'local_item_note_data_source.dart';

/// Local-first note operations. Every mutation writes straight to Drift (so
/// the UI updates instantly and offline) and then nudges sync, never the
/// other way around.
class ItemNoteRepository {
  factory ItemNoteRepository(
    LocalItemNoteDataSource local, {
    required String? userId,
    required Future<void> Function() onChanged,
  }) => ItemNoteRepository._(local, userId, onChanged);

  ItemNoteRepository._(this._local, this._userId, this._onChanged);

  final LocalItemNoteDataSource _local;
  final String? _userId;
  final Future<void> Function() _onChanged;

  Stream<ItemNote?> watchNote(String itemId) {
    return _local.watchNote(itemId, _userId);
  }

  /// Saves a note. A blank note is deleted (tombstoned) instead, so an empty
  /// editor can never resurrect content on another device.
  Future<void> save(String itemId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      await _local.delete(itemId);
    } else {
      await _local.save(itemId, _userId, trimmed);
    }
    unawaited(_onChanged());
  }

  Future<void> delete(String itemId) async {
    await _local.delete(itemId);
    unawaited(_onChanged());
  }
}
import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_status.dart';
import '../../../shared/models/laterbox_item.dart';
import 'local_item_data_source.dart';

class ItemRepository {
  factory ItemRepository(
    LocalItemDataSource local, {
    required String? userId,
    required Future<void> Function() onSaved,
    Uuid uuid = const Uuid(),
  }) => ItemRepository._(local, userId, onSaved, uuid);

  ItemRepository._(this._local, this._userId, this._onSaved, this._uuid);

  final LocalItemDataSource _local;
  final String? _userId;
  final Future<void> Function() _onSaved;
  final Uuid _uuid;

  Stream<List<LaterBoxItem>> watchInboxItems() {
    return _local
        .watchInboxItems(_userId)
        .map(
          (rows) => rows
              .map(
                (row) => LaterBoxItem(
                  id: row.id,
                  url: row.url,
                  title: row.title,
                  text: row.textContent,
                  type: row.type,
                  favorite: row.favorite,
                  archived: row.archived,
                  createdAt: row.createdAt,
                ),
              )
              .toList(),
        );
  }

  Future<void> save(String value, {String? id, DateTime? createdAt}) async {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Paste a URL or some text to save.');
    }

    final itemId = id ?? _uuid.v4();
    if (id != null && await _local.exists(itemId)) return;

    final uri = Uri.tryParse(normalized);
    final isUrl = uri != null && uri.hasScheme && uri.host.isNotEmpty;
    final now = createdAt ?? DateTime.now();

    await _local.insert(
      ItemsCompanion.insert(
        id: itemId,
        userId: Value(_userId),
        url: Value(isUrl ? normalized : null),
        textContent: Value(isUrl ? null : normalized),
        type: Value(isUrl ? 'link' : 'text'),
        createdAt: now,
        updatedAt: now,
        syncStatus: Value(SyncStatus.pending.databaseValue),
      ),
    );
    unawaited(_onSaved());
  }
}

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_status.dart';
import '../../../shared/models/item_status.dart';
import '../../../shared/models/laterbox_item.dart';
import '../../enrichment/domain/url_utils.dart';
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
    return _local.watchInboxItemsWithMetadata(_userId).map(_toItems);
  }

  Stream<List<LaterBoxItem>> watchAllItems() {
    return _local.watchAllItemsWithMetadata(_userId).map(_toItems);
  }

  Stream<List<LaterBoxItem>> watchFavorites() {
    return _local.watchFavoriteItemsWithMetadata(_userId).map(_toItems);
  }

  Stream<List<LaterBoxItem>> watchArchived() {
    return _local.watchItemsWithStatus(_userId, 'archived').map(_toItems);
  }

  Stream<LaterBoxItem?> watchItem(String id) {
    return _local.watchItemWithMetadata(id).map(
      (row) => row == null ? null : LaterBoxItem.fromDriftRows(row.$1, row.$2),
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
        url: Value(isUrl ? normalizeUrl(normalized) : null),
        textContent: Value(isUrl ? null : normalized),
        type: Value(isUrl ? 'link' : 'text'),
        createdAt: now,
        updatedAt: now,
        syncStatus: Value(SyncStatus.pending.databaseValue),
      ),
    );
    unawaited(_onSaved());
  }

  Future<void> setFavorite(String id, bool favorite) async {
    await _local.updateFavorite(id, favorite);
    unawaited(_onSaved());
  }

  Future<void> setStatus(String id, ItemStatus status) async {
    await _local.updateStatus(id, status.databaseValue);
    unawaited(_onSaved());
  }

  Future<void> keep(String id) => setStatus(id, ItemStatus.saved);

  Future<void> archive(String id) => setStatus(id, ItemStatus.archived);

  Future<void> markSeen(String id) => archive(id);

  Future<void> markUnseen(String id) => setStatus(id, ItemStatus.inbox);

  Future<void> delete(String id) async {
    await _local.softDelete(id);
    unawaited(_onSaved());
  }

  List<LaterBoxItem> _toItems(List<(Item, ItemMetadataData?)> rows) {
    return rows
        .map((row) => LaterBoxItem.fromDriftRows(row.$1, row.$2))
        .toList();
  }
}

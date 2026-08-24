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

  Future<void> save(
    String value, {
    String? id,
    DateTime? createdAt,
    String? textContent,
    String? url,
  }) async {
    final normalized = value.trim();
    if (normalized.isEmpty &&
        (url == null || url.isEmpty) &&
        (textContent == null || textContent.isEmpty)) {
      throw const FormatException('Paste a URL or some text to save.');
    }

    final itemId = id ?? _uuid.v4();
    if (id != null && await _local.exists(itemId)) return;

    final targetUrl = (url != null && url.isNotEmpty)
        ? url
        : (Uri.tryParse(normalized)?.hasScheme == true ? normalized : null);

    final uri = targetUrl != null ? Uri.tryParse(targetUrl) : null;
    final isUrl = uri != null && uri.hasScheme && uri.host.isNotEmpty;
    final normalizedUrl = isUrl ? normalizeUrl(targetUrl!) : null;
    final bodyText = textContent?.trim().isNotEmpty == true
        ? textContent!.trim()
        : (normalizedUrl != null && normalizedUrl.contains(':~:text=')
            ? () {
                try {
                  final raw =
                      normalizedUrl.split(':~:text=').last.split('&').first;
                  final decoded = Uri.decodeComponent(raw);
                  return decoded
                      .replaceAll(RegExp(r'^[^\-,]+-,'), '')
                      .replaceAll(RegExp(r',-[^\-,]+$'), '');
                } catch (_) {
                  return null;
                }
              }()
            : (isUrl ? null : normalized));
    final now = createdAt ?? DateTime.now();

    final existing = await _local.findActiveInboxItem(
      _userId,
      url: normalizedUrl,
      textContent: bodyText,
    );
    if (existing != null) {
      return;
    }

    await _local.insert(
      ItemsCompanion.insert(
        id: itemId,
        userId: Value(_userId),
        url: Value(normalizedUrl),
        textContent: Value(bodyText),
        type: Value(isUrl ? (bodyText != null && bodyText.isNotEmpty ? 'quote' : 'link') : 'text'),
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
    final seenIds = <String>{};
    final seenKeys = <String>{};
    final items = <LaterBoxItem>[];

    for (final row in rows) {
      final item = row.$1;
      if (!seenIds.add(item.id)) continue;

      final key = item.url != null && item.url!.isNotEmpty
          ? 'url:${item.url}'
          : (item.textContent != null && item.textContent!.isNotEmpty
              ? 'text:${item.textContent}'
              : null);
      if (key != null && !seenKeys.add(key)) {
        continue;
      }

      items.add(LaterBoxItem.fromDriftRows(item, row.$2));
    }
    return items;
  }
}

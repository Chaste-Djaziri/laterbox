import 'dart:async';

import 'package:uuid/uuid.dart';

import 'local_collection_data_source.dart';

/// Local-first collection operations. Every mutation writes straight to Drift
/// (so the UI updates instantly and offline) and then nudges sync, never the
/// other way around.
class CollectionRepository {
  factory CollectionRepository(
    LocalCollectionDataSource local, {
    required String? userId,
    required Future<void> Function() onChanged,
    Uuid uuid = const Uuid(),
  }) => CollectionRepository._(local, userId, onChanged, uuid);

  CollectionRepository._(
    this._local,
    this._userId,
    this._onChanged,
    this._uuid,
  );

  final LocalCollectionDataSource _local;
  final String? _userId;
  final Future<void> Function() _onChanged;
  final Uuid _uuid;

  Future<String> create(String name) async {
    final id = _uuid.v4();
    await _local.create(id, _userId, name.trim());
    unawaited(_onChanged());
    return id;
  }

  Future<void> rename(String id, String name) async {
    await _local.rename(id, name.trim());
    unawaited(_onChanged());
  }

  Future<void> delete(String id) async {
    await _local.delete(id);
    unawaited(_onChanged());
  }

  Future<void> addItem(String collectionId, String itemId) async {
    await _local.addItem(collectionId, itemId);
    unawaited(_onChanged());
  }

  Future<void> removeItem(String collectionId, String itemId) async {
    await _local.removeItem(collectionId, itemId);
    unawaited(_onChanged());
  }

  Future<void> setItemMembership(
    String collectionId,
    String itemId,
    bool member,
  ) {
    return member
        ? addItem(collectionId, itemId)
        : removeItem(collectionId, itemId);
  }
}
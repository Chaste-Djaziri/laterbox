import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';

abstract interface class RemoteCollectionDataSource {
  Future<List<RemoteCollection>> fetchCollections(String userId);

  Future<void> upsertCollection(Collection collection);

  Future<List<RemoteCollectionItem>> fetchCollectionItems(String userId);

  Future<void> upsertCollectionItem(CollectionItem item);
}

class SupabaseRemoteCollectionDataSource implements RemoteCollectionDataSource {
  const SupabaseRemoteCollectionDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RemoteCollection>> fetchCollections(String userId) async {
    final rows = await _client
        .from('collections')
        .select()
        .eq('user_id', userId)
        .order('updated_at');

    return rows.map(RemoteCollection.fromJson).toList();
  }

  @override
  Future<void> upsertCollection(Collection collection) async {
    await _client
        .from('collections')
        .upsert(collection.toRemoteJson(), onConflict: 'id');
  }

  @override
  Future<List<RemoteCollectionItem>> fetchCollectionItems(String userId) async {
    final rows = await _client
        .from('collection_items')
        .select()
        .eq('user_id', userId)
        .order('updated_at');

    return rows.map(RemoteCollectionItem.fromJson).toList();
  }

  @override
  Future<void> upsertCollectionItem(CollectionItem item) async {
    await _client.from('collection_items').upsert(
      item.toRemoteJson(),
      onConflict: 'collection_id,item_id',
    );
  }
}

class RemoteCollection {
  const RemoteCollection({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory RemoteCollection.fromJson(Map<String, dynamic> json) {
    return RemoteCollection(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String).toUtc(),
    );
  }

  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

class RemoteCollectionItem {
  const RemoteCollectionItem({
    required this.collectionId,
    required this.itemId,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory RemoteCollectionItem.fromJson(Map<String, dynamic> json) {
    return RemoteCollectionItem(
      collectionId: json['collection_id'] as String,
      itemId: json['item_id'] as String,
      userId: json['user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String).toUtc(),
    );
  }

  final String collectionId;
  final String itemId;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

extension on Collection {
  Map<String, Object?> toRemoteJson() => {
    'id': id,
    'user_id': userId,
    'name': name,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };
}

extension on CollectionItem {
  Map<String, Object?> toRemoteJson() => {
    'collection_id': collectionId,
    'item_id': itemId,
    'user_id': userId,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';

abstract interface class RemoteItemDataSource {
  Future<List<RemoteItem>> fetchItems(String userId);
  Future<void> upsertItem(Item item);
}

class SupabaseRemoteItemDataSource implements RemoteItemDataSource {
  const SupabaseRemoteItemDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RemoteItem>> fetchItems(String userId) async {
    final rows = await _client
        .from('items')
        .select()
        .eq('user_id', userId)
        .order('updated_at');

    return rows.map(RemoteItem.fromJson).toList();
  }

  @override
  Future<void> upsertItem(Item item) async {
    await _client.from('items').upsert(item.toRemoteJson(), onConflict: 'id');
  }
}

class RemoteItem {
  const RemoteItem({
    required this.id,
    required this.userId,
    this.url,
    this.title,
    this.textContent,
    required this.type,
    required this.favorite,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory RemoteItem.fromJson(Map<String, dynamic> json) {
    return RemoteItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      url: json['url'] as String?,
      title: json['title'] as String?,
      textContent: json['text_content'] as String?,
      type: json['type'] as String,
      favorite: json['favorite'] as bool,
      status: json['status'] as String? ?? 'inbox',
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String).toUtc(),
    );
  }

  final String id;
  final String userId;
  final String? url;
  final String? title;
  final String? textContent;
  final String type;
  final bool favorite;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

extension on Item {
  Map<String, Object?> toRemoteJson() => {
    'id': id,
    'user_id': userId,
    'url': url,
    'title': title,
    'text_content': textContent,
    'type': type,
    'favorite': favorite,
    'status': status,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };
}

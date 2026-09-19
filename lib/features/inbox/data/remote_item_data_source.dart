import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../core/notifications/notification_identity.dart';
import '../../../core/notifications/notification_service.dart';

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
    await InboxNotificationService.instance.prepareUpload(item.id);
    await _client.from('items').upsert({
      ...item.toRemoteJson(),
      'origin_installation_id': await NotificationIdentity.installationId(),
    }, onConflict: 'id');
  }
}

class RemoteItem {
  const RemoteItem({
    required this.id,
    required this.userId,
    this.url,
    this.title,
    this.textContent,
    this.textSelector,
    required this.type,
    required this.favorite,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.returnAt,
  });

  factory RemoteItem.fromJson(Map<String, dynamic> json) {
    return RemoteItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      url: json['url'] as String?,
      title: json['title'] as String?,
      textContent: json['text_content'] as String?,
      textSelector: json['text_selector'] as String?,
      type: json['type'] as String,
      favorite: json['favorite'] as bool,
      status: json['status'] as String? ?? 'inbox',
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      returnAt: json['return_at'] == null
          ? null
          : DateTime.parse(json['return_at'] as String).toUtc(),
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
  final String? textSelector;
  final String type;
  final bool favorite;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime? returnAt;
}

extension on Item {
  Map<String, Object?> toRemoteJson() => {
    'id': id,
    'user_id': userId,
    'url': url,
    'title': title,
    'text_content': textContent,
    'text_selector': textSelector,
    'type': type,
    'favorite': favorite,
    'status': status,
    'return_at': returnAt?.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };
}

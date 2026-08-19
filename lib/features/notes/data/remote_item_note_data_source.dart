import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';

abstract interface class RemoteItemNoteDataSource {
  Future<List<RemoteItemNote>> fetchNotes(String userId);

  Future<void> upsertNote(ItemNote note);
}

class SupabaseRemoteItemNoteDataSource implements RemoteItemNoteDataSource {
  const SupabaseRemoteItemNoteDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RemoteItemNote>> fetchNotes(String userId) async {
    final rows = await _client
        .from('item_notes')
        .select()
        .eq('user_id', userId)
        .order('updated_at');

    return rows.map(RemoteItemNote.fromJson).toList();
  }

  @override
  Future<void> upsertNote(ItemNote note) async {
    await _client.from('item_notes').upsert(
      note.toRemoteJson(),
      onConflict: 'item_id',
    );
  }
}

class RemoteItemNote {
  const RemoteItemNote({
    required this.itemId,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory RemoteItemNote.fromJson(Map<String, dynamic> json) {
    return RemoteItemNote(
      itemId: json['item_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String).toUtc(),
    );
  }

  final String itemId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
}

extension on ItemNote {
  Map<String, Object?> toRemoteJson() => {
    'item_id': itemId,
    'user_id': userId,
    'content': content,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };
}
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';

abstract interface class RemoteAttachmentDataSource {
  Future<List<RemoteAttachment>> fetchAttachments(String userId);
  Future<void> upsertAttachment(Attachment attachment);
}

class SupabaseRemoteAttachmentDataSource implements RemoteAttachmentDataSource {
  const SupabaseRemoteAttachmentDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RemoteAttachment>> fetchAttachments(String userId) async {
    final rows = await _client
        .from('attachments')
        .select()
        .eq('user_id', userId)
        .order('updated_at');
    return rows.map(RemoteAttachment.fromJson).toList();
  }

  @override
  Future<void> upsertAttachment(Attachment attachment) async {
    await _client
        .from('attachments')
        .upsert(attachment.toRemoteJson(), onConflict: 'id');
  }
}

class RemoteAttachment {
  const RemoteAttachment({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.originalFileName,
    required this.fileExtension,
    required this.mimeType,
    required this.byteSize,
    required this.sha256,
    required this.r2ObjectKey,
    required this.width,
    required this.height,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  factory RemoteAttachment.fromJson(Map<String, dynamic> json) {
    return RemoteAttachment(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      userId: json['user_id'] as String,
      originalFileName: json['original_file_name'] as String,
      fileExtension: json['file_extension'] as String,
      mimeType: json['mime_type'] as String,
      byteSize: json['byte_size'] as int,
      sha256: json['sha256'] as String,
      r2ObjectKey: json['r2_object_key'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String).toUtc(),
    );
  }

  final String id;
  final String itemId;
  final String userId;
  final String originalFileName;
  final String fileExtension;
  final String mimeType;
  final int byteSize;
  final String sha256;
  final String? r2ObjectKey;
  final int? width;
  final int? height;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  AttachmentsCompanion toLocalCompanion(DateTime syncedAt) {
    return AttachmentsCompanion.insert(
      id: id,
      itemId: itemId,
      userId: Value(userId),
      originalFileName: originalFileName,
      fileExtension: fileExtension,
      mimeType: mimeType,
      byteSize: byteSize,
      sha256: sha256,
      r2ObjectKey: Value(r2ObjectKey),
      width: Value(width),
      height: Value(height),
      uploadStatus: Value(r2ObjectKey == null ? 'local' : 'uploaded'),
      downloadStatus: const Value('remote'),
      syncStatus: const Value('synced'),
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: Value(deletedAt),
      lastSyncedAt: Value(syncedAt),
    );
  }
}

extension on Attachment {
  Map<String, Object?> toRemoteJson() => {
    'id': id,
    'item_id': itemId,
    'user_id': userId,
    'original_file_name': originalFileName,
    'file_extension': fileExtension,
    'mime_type': mimeType,
    'byte_size': byteSize,
    'sha256': sha256,
    'r2_object_key': r2ObjectKey,
    'width': width,
    'height': height,
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
    'deleted_at': deletedAt?.toUtc().toIso8601String(),
  };
}

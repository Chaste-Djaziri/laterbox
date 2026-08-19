import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../domain/item_metadata.dart';

abstract interface class RemoteMetadataDataSource {
  /// Invokes the `enrich-url` edge function for a normalized URL.
  Future<EnrichedMetadata> fetch(String url);

  Future<List<RemoteItemMetadata>> fetchMetadata(String userId);

  Future<void> upsertMetadata(ItemMetadataData metadata);
}

class SupabaseRemoteMetadataDataSource implements RemoteMetadataDataSource {
  const SupabaseRemoteMetadataDataSource(this._client);

  final SupabaseClient _client;

  @override
  Future<EnrichedMetadata> fetch(String url) async {
    final response = await _client.functions.invoke(
      'enrich-url',
      body: {'url': url},
    );
    final data = response.data;
    if (data is! Map) {
      throw const FunctionsHttpException(
        status: 500,
        reasonPhrase: 'Unexpected response from enrich-url',
      );
    }
    return EnrichedMetadata.fromRemoteJson(data.cast<String, dynamic>());
  }

  @override
  Future<List<RemoteItemMetadata>> fetchMetadata(String userId) async {
    final rows = await _client
        .from('item_metadata')
        .select()
        .eq('user_id', userId)
        .order('updated_at');
    return rows.map(RemoteItemMetadata.fromJson).toList();
  }

  @override
  Future<void> upsertMetadata(ItemMetadataData metadata) async {
    await _client
        .from('item_metadata')
        .upsert(metadata.toRemoteJson(), onConflict: 'item_id');
  }
}

class RemoteItemMetadata {
  const RemoteItemMetadata({
    required this.itemId,
    required this.userId,
    this.domain,
    this.siteName,
    this.title,
    this.description,
    this.faviconUrl,
    this.previewImageUrl,
    required this.status,
    required this.attemptCount,
    this.lastError,
    required this.metadataVersion,
    this.enrichedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RemoteItemMetadata.fromJson(Map<String, dynamic> json) {
    return RemoteItemMetadata(
      itemId: json['item_id'] as String,
      userId: json['user_id'] as String,
      domain: json['domain'] as String?,
      siteName: json['site_name'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      faviconUrl: json['favicon_url'] as String?,
      previewImageUrl: json['preview_image_url'] as String?,
      status: json['status'] as String,
      attemptCount: json['attempt_count'] as int,
      lastError: json['last_error'] as String?,
      metadataVersion: json['metadata_version'] as int,
      enrichedAt: json['enriched_at'] == null
          ? null
          : DateTime.parse(json['enriched_at'] as String).toUtc(),
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toUtc(),
    );
  }

  final String itemId;
  final String userId;
  final String? domain;
  final String? siteName;
  final String? title;
  final String? description;
  final String? faviconUrl;
  final String? previewImageUrl;
  final String status;
  final int attemptCount;
  final String? lastError;
  final int metadataVersion;
  final DateTime? enrichedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}

extension on ItemMetadataData {
  Map<String, Object?> toRemoteJson() => {
    'item_id': itemId,
    'user_id': userId,
    'domain': domain,
    'site_name': siteName,
    'title': title,
    'description': description,
    'favicon_url': faviconUrl,
    'preview_image_url': previewImageUrl,
    'status': status,
    'attempt_count': attemptCount,
    'last_error': lastError,
    'metadata_version': metadataVersion,
    'enriched_at': enrichedAt?.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}
import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/content_type.dart';
import '../domain/item_metadata.dart';
import '../domain/url_utils.dart';
import 'remote_metadata_data_source.dart';

class LocalMetadataDataSource {
  const LocalMetadataDataSource(this._database);

  final AppDatabase _database;

  Future<ItemMetadataData?> metadataForItem(String itemId) {
    return _database.metadataById(itemId);
  }

  Future<void> ensurePending(
    String itemId,
    String url,
    String? userId,
  ) {
    final now = DateTime.now();
    return _database.upsertMetadata(
      ItemMetadataCompanion.insert(
        itemId: itemId,
        userId: Value(userId),
        domain: Value(extractDomain(url)),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> markEnriching(String itemId, int attemptCount, String? userId) {
    return _database.updateMetadata(
      itemId,
      ItemMetadataCompanion(
        userId: Value(userId),
        status: const Value('enriching'),
        attemptCount: Value(attemptCount),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> saveEnriched(
    String itemId,
    EnrichedMetadata metadata,
    String? userId,
  ) {
    final now = DateTime.now();
    return _database.updateMetadata(
      itemId,
      ItemMetadataCompanion(
        userId: Value(userId),
        status: const Value('enriched'),
        domain: Value(metadata.domain),
        siteName: Value(metadata.siteName),
        title: Value(metadata.title),
        description: Value(metadata.description),
        faviconUrl: Value(metadata.faviconUrl),
        previewImageUrl: Value(metadata.previewImageUrl),
        contentType: Value(metadata.classification?.type.value ?? 'link'),
        classificationSource:
            Value(metadata.classification?.source.value),
        classificationConfidence:
            Value(metadata.classification?.confidence ?? 0),
        structuredData: Value(
          ClassificationCodec.encode(metadata.classification?.structuredData),
        ),
        lastError: const Value(null),
        enrichedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markFailed(String itemId, String error, String? userId) {
    return _database.updateMetadata(
      itemId,
      ItemMetadataCompanion(
        userId: Value(userId),
        status: const Value('failed'),
        lastError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markUnsupported(String itemId, String error, String? userId) {
    return _database.updateMetadata(
      itemId,
      ItemMetadataCompanion(
        userId: Value(userId),
        status: const Value('unsupported'),
        lastError: Value(error),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<ItemMetadataData?> enrichedForUrl(String url) {
    return _database.enrichedMetadataForUrl(url);
  }

  Future<List<(Item, ItemMetadataData?)>> itemsToEnrich(String? userId) {
    return _database.itemsToEnrich(userId);
  }

  Future<void> resetStuckEnriching() {
    return _database.resetStuckEnriching();
  }

  Future<List<ItemMetadataData>> metadataNeedingSync(String userId) {
    return _database.metadataNeedingSync(userId);
  }

  Future<bool> applyRemoteMetadata(
    RemoteItemMetadata remote,
    DateTime syncedAt,
  ) async {
    final local = await _database.metadataById(remote.itemId);
    if (local != null && local.updatedAt.isAfter(remote.updatedAt)) {
      return false;
    }
    await _database.upsertMetadata(
      ItemMetadataCompanion.insert(
        itemId: remote.itemId,
        userId: Value(remote.userId),
        domain: Value(remote.domain),
        siteName: Value(remote.siteName),
        title: Value(remote.title),
        description: Value(remote.description),
        faviconUrl: Value(remote.faviconUrl),
        previewImageUrl: Value(remote.previewImageUrl),
        status: Value(remote.status),
        attemptCount: Value(remote.attemptCount),
        lastError: Value(remote.lastError),
        metadataVersion: Value(remote.metadataVersion),
        enrichedAt: Value(remote.enrichedAt),
        contentType: Value(remote.contentType ?? 'link'),
        classificationSource: Value(remote.classificationSource),
        classificationConfidence:
            Value(remote.classificationConfidence ?? 0),
        structuredData: Value(remote.structuredData),
        createdAt: local?.createdAt ?? remote.createdAt,
        updatedAt: remote.updatedAt,
      ),
    );
    return true;
  }
}
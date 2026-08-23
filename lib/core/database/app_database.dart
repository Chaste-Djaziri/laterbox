import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part 'app_database.g.dart';

class Items extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get textContent => text().nullable()();
  TextColumn get textSelector => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('unknown'))();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('inbox'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@TableIndex(name: 'attachments_item_id_idx', columns: {#itemId})
@TableIndex(name: 'attachments_user_id_idx', columns: {#userId})
@TableIndex(name: 'attachments_sha256_idx', columns: {#sha256})
@TableIndex(name: 'attachments_upload_status_idx', columns: {#uploadStatus})
@TableIndex(name: 'attachments_sync_status_idx', columns: {#syncStatus})
@TableIndex(name: 'attachments_deleted_at_idx', columns: {#deletedAt})
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(Items, #id)();
  TextColumn get userId => text().nullable()();
  TextColumn get originalFileName => text()();
  TextColumn get fileExtension => text().customConstraint(
    "NOT NULL CHECK(file_extension <> '' AND "
    "file_extension = lower(file_extension) AND file_extension NOT LIKE '.%')",
  )();
  TextColumn get mimeType => text()();
  IntColumn get byteSize => integer().customConstraint(
    'NOT NULL CHECK(byte_size BETWEEN 0 AND 5368709120)',
  )();
  TextColumn get sha256 => text().customConstraint(
    "NOT NULL CHECK(length(sha256) = 64 AND "
    "sha256 NOT GLOB '*[^0-9a-f]*')",
  )();
  TextColumn get localPath => text().nullable().unique()();
  BlobColumn get localBytes => blob().nullable()();
  TextColumn get r2ObjectKey => text().nullable().unique()();
  IntColumn get width => integer().nullable().customConstraint(
    'NULL CHECK(width IS NULL OR width > 0)',
  )();
  IntColumn get height => integer().nullable().customConstraint(
    'NULL CHECK(height IS NULL OR height > 0)',
  )();
  TextColumn get uploadStatus => text().customConstraint(
    "NOT NULL DEFAULT 'local' CHECK(upload_status IN "
    "('local', 'pending', 'uploading', 'uploaded', 'failed'))",
  )();
  IntColumn get uploadAttempts => integer().customConstraint(
    'NOT NULL DEFAULT 0 CHECK(upload_attempts >= 0)',
  )();
  TextColumn get uploadLastError => text().nullable()();
  TextColumn get downloadStatus => text().customConstraint(
    "NOT NULL DEFAULT 'downloaded' CHECK(download_status IN "
    "('remote', 'downloading', 'downloaded', 'failed'))",
  )();
  TextColumn get previewStatus => text().customConstraint(
    "NOT NULL DEFAULT 'none' CHECK(preview_status IN "
    "('none', 'pending', 'processing', 'ready', 'failed'))",
  )();
  TextColumn get previewKind => text().customConstraint(
    "NOT NULL DEFAULT 'generic' CHECK(preview_kind IN "
    "('image', 'pdf', 'text', 'code', 'spreadsheet', 'document', 'presentation', 'audio', 'video', 'archive', 'ebook', 'model3d', 'font', 'generic'))",
  )();
  TextColumn get previewObjectKey => text().nullable()();
  TextColumn get thumbnailObjectKey => text().nullable()();
  TextColumn get extractedTextObjectKey => text().nullable()();
  TextColumn get previewError => text().nullable()();
  IntColumn get previewVersion => integer().customConstraint(
    'NOT NULL DEFAULT 0 CHECK(preview_version >= 0)',
  )();
  TextColumn get syncStatus => text().customConstraint(
    "NOT NULL DEFAULT 'pending' "
    "CHECK(sync_status IN ('pending', 'synced', 'failed'))",
  )();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AttachmentUploadParts extends Table {
  TextColumn get attachmentId => text().references(Attachments, #id)();
  IntColumn get partNumber => integer()();
  TextColumn get etag => text()();
  IntColumn get byteStart => integer()();
  IntColumn get byteEnd => integer()();
  DateTimeColumn get uploadedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {attachmentId, partNumber};
}

class Collections extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CollectionItems extends Table {
  TextColumn get collectionId =>
      text().references(Collections, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {collectionId, itemId};
}

class ItemNotes extends Table {
  TextColumn get itemId =>
      text().references(Items, #id, onDelete: KeyAction.cascade)();
  TextColumn get userId => text().nullable()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {itemId};
}

/// Simple key–value store for app preferences (desktop settings etc.).
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class ItemMetadata extends Table {
  TextColumn get itemId => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get domain => text().nullable()();
  TextColumn get siteName => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get faviconUrl => text().nullable()();
  TextColumn get previewImageUrl => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get attemptCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  IntColumn get metadataVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get enrichedAt => dateTime().nullable()();
  TextColumn get contentType => text().withDefault(const Constant('link'))();
  TextColumn get classificationSource => text().nullable()();
  RealColumn get classificationConfidence =>
      real().withDefault(const Constant(0))();
  TextColumn get structuredData => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {itemId};
}

@DriftDatabase(
  tables: [
    Items,
    Attachments,
    AttachmentUploadParts,
    ItemMetadata,
    Collections,
    CollectionItems,
    ItemNotes,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'laterbox',
              web: kIsWeb
                  ? DriftWebOptions(
                      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                      driftWorker: Uri.parse('drift_worker.dart.js'),
                    )
                  : null,
            ),
      );

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(items, items.userId);
        await migrator.addColumn(items, items.lastSyncedAt);
        await migrator.addColumn(items, items.deletedAt);
      }
      if (from < 3) {
        await migrator.createTable(itemMetadata);
      }
      if (from < 4) {
        await migrator.addColumn(items, items.status);
        await migrator.createTable(collections);
        await migrator.createTable(collectionItems);
        await migrator.database.customStatement(
          "UPDATE items SET status = 'archived' WHERE archived = 1",
        );
        await migrator.database.customStatement(
          'ALTER TABLE items DROP COLUMN archived',
        );
      }
      if (from < 5) {
        // Defensive: a crash or stale version stamp can leave the v5 columns
        // behind while user_version still reports 4, which would otherwise
        // fail with "duplicate column name". Check each column first.
        final collectionColumns = await _columnNames('collections');
        final itemColumns = await _columnNames('collection_items');
        if (!collectionColumns.contains('sync_status')) {
          await migrator.addColumn(collections, collections.syncStatus);
        }
        if (!collectionColumns.contains('last_synced_at')) {
          await migrator.addColumn(collections, collections.lastSyncedAt);
        }
        if (!itemColumns.contains('user_id')) {
          await migrator.addColumn(collectionItems, collectionItems.userId);
        }
        if (!itemColumns.contains('deleted_at')) {
          await migrator.addColumn(collectionItems, collectionItems.deletedAt);
        }
        if (!itemColumns.contains('sync_status')) {
          await migrator.addColumn(collectionItems, collectionItems.syncStatus);
        }
        if (!itemColumns.contains('last_synced_at')) {
          await migrator.addColumn(
            collectionItems,
            collectionItems.lastSyncedAt,
          );
        }
        if (!itemColumns.contains('updated_at')) {
          // SQLite forbids non-constant defaults (CURRENT_TIMESTAMP) in
          // ADD COLUMN, so add it plain and backfill from created_at.
          await migrator.database.customStatement(
            'ALTER TABLE collection_items ADD COLUMN updated_at TIMESTAMP',
          );
        }
        await migrator.database.customStatement(
          'UPDATE collection_items SET updated_at = created_at '
          'WHERE updated_at IS NULL',
        );
      }
      if (from < 6) {
        await migrator.createTable(itemNotes);
      }
      if (from < 7) {
        final metadataColumns = await _columnNames('item_metadata');
        if (!metadataColumns.contains('content_type')) {
          await migrator.addColumn(itemMetadata, itemMetadata.contentType);
        }
        if (!metadataColumns.contains('classification_source')) {
          await migrator.addColumn(
            itemMetadata,
            itemMetadata.classificationSource,
          );
        }
        if (!metadataColumns.contains('classification_confidence')) {
          await migrator.addColumn(
            itemMetadata,
            itemMetadata.classificationConfidence,
          );
        }
        if (!metadataColumns.contains('structured_data')) {
          await migrator.addColumn(itemMetadata, itemMetadata.structuredData);
        }
      }
      if (from < 8) {
        final itemColumns = await _columnNames('items');
        if (!itemColumns.contains('text_selector')) {
          await migrator.addColumn(items, items.textSelector);
        }
      }
      if (from < 9) {
        await migrator.createTable(appSettings);
      }
      if (from < 10) {
        await migrator.createTable(attachments);
      }
      if (from < 11) {
        await migrator.alterTable(TableMigration(attachments));
      }
      if (from < 12) {
        final attachmentColumns = await _columnNames('attachments');
        if (!attachmentColumns.contains('local_bytes')) {
          await migrator.addColumn(attachments, attachments.localBytes);
        }
      }
      if (from < 13) {
        final attachmentColumns = await _columnNames('attachments');
        if (!attachmentColumns.contains('preview_status')) {
          await migrator.addColumn(attachments, attachments.previewStatus);
        }
        if (!attachmentColumns.contains('preview_kind')) {
          await migrator.addColumn(attachments, attachments.previewKind);
        }
        if (!attachmentColumns.contains('preview_object_key')) {
          await migrator.addColumn(attachments, attachments.previewObjectKey);
        }
        if (!attachmentColumns.contains('thumbnail_object_key')) {
          await migrator.addColumn(attachments, attachments.thumbnailObjectKey);
        }
        if (!attachmentColumns.contains('extracted_text_object_key')) {
          await migrator.addColumn(
            attachments,
            attachments.extractedTextObjectKey,
          );
        }
        if (!attachmentColumns.contains('preview_error')) {
          await migrator.addColumn(attachments, attachments.previewError);
        }
        if (!attachmentColumns.contains('preview_version')) {
          await migrator.addColumn(attachments, attachments.previewVersion);
        }
        await migrator.createTable(attachmentUploadParts);
      }
    },
  );

  Future<Set<String>> _columnNames(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows.map((row) => row.data['name'] as String).toSet();
  }

  Stream<List<Item>> watchInboxItems(String? userId) {
    return (select(items)
          ..where(
            (item) =>
                item.status.equals('inbox') &
                item.deletedAt.isNull() &
                (userId == null
                    ? item.userId.isNull()
                    : item.userId.equals(userId)),
          )
          ..orderBy([(item) => OrderingTerm.desc(item.createdAt)]))
        .watch();
  }

  Future<void> saveItem(ItemsCompanion item) => into(items).insert(item);

  Future<List<Item>> itemsNeedingSync(String userId) async {
    await transaction(() async {
      final guestItemIds =
          await (selectOnly(items)
                ..addColumns([items.id])
                ..where(items.userId.isNull()))
              .map((row) => row.read(items.id)!)
              .get();
      if (guestItemIds.isNotEmpty) {
        await (update(items)
              ..where((item) => item.id.isIn(guestItemIds)))
            .write(ItemsCompanion(userId: Value(userId)));
      }
      
      await (update(attachments)
            ..where((attachment) => attachment.userId.isNull()))
          .write(AttachmentsCompanion(userId: Value(userId)));
    });

    final unuploadedItemIds = await (selectOnly(attachments)
          ..addColumns([attachments.itemId])
          ..where(
            attachments.userId.equals(userId) &
                attachments.deletedAt.isNull() &
                attachments.r2ObjectKey.isNull(),
          ))
        .map((row) => row.read(attachments.itemId)!)
        .get();

    return (select(items)..where(
          (item) =>
              item.userId.equals(userId) &
              item.syncStatus.isIn(const ['pending', 'failed']) &
              (unuploadedItemIds.isEmpty
                  ? const Constant(true)
                  : item.id.isNotIn(unuploadedItemIds)),
        ))
        .get();
  }

  Future<Item?> itemById(String id) {
    return (select(
      items,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
  }

  Future<Item?> findActiveInboxItem(
    String? userId, {
    String? url,
    String? textContent,
  }) {
    if (url == null && textContent == null) return Future.value(null);
    final query = select(items)
      ..where(
        (item) =>
            item.deletedAt.isNull() &
            item.status.equals('inbox') &
            (userId == null
                ? item.userId.isNull()
                : item.userId.equals(userId)) &
            (url != null
                ? item.url.equals(url)
                : item.textContent.equals(textContent!)),
      )
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<void> upsertRemoteItem(ItemsCompanion item) {
    return into(items).insertOnConflictUpdate(item);
  }

  Future<void> markSynced(String id, DateTime syncedAt) {
    return (update(items)..where((item) => item.id.equals(id))).write(
      ItemsCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(syncedAt),
      ),
    );
  }

  Future<void> markFailed(String id) {
    return (update(items)..where((item) => item.id.equals(id))).write(
      const ItemsCompanion(syncStatus: Value('failed')),
    );
  }

  Stream<List<(Item, ItemMetadataData?)>> watchInboxItemsWithMetadata(
    String? userId,
  ) {
    final query = _itemsWithMetadataQuery(userId)
      ..where(items.status.equals('inbox'))
      ..orderBy([OrderingTerm.desc(items.createdAt)]);
    return query.watch().map(_mapJoinedRows);
  }

  /// All non-deleted items (including archived), newest first.
  Stream<List<(Item, ItemMetadataData?)>> watchAllItemsWithMetadata(
    String? userId,
  ) {
    final query = _itemsWithMetadataQuery(userId)
      ..orderBy([OrderingTerm.desc(items.createdAt)]);
    return query.watch().map(_mapJoinedRows);
  }

  /// Non-deleted items with the given status, newest first.
  Stream<List<(Item, ItemMetadataData?)>> watchItemsWithStatus(
    String? userId,
    String status,
  ) {
    final query = _itemsWithMetadataQuery(userId)
      ..where(items.status.equals(status))
      ..orderBy([OrderingTerm.desc(items.createdAt)]);
    return query.watch().map(_mapJoinedRows);
  }

  /// Non-deleted favorites, newest first.
  Stream<List<(Item, ItemMetadataData?)>> watchFavoriteItemsWithMetadata(
    String? userId,
  ) {
    final query = _itemsWithMetadataQuery(userId)
      ..where(items.favorite.equals(true))
      ..orderBy([OrderingTerm.desc(items.createdAt)]);
    return query.watch().map(_mapJoinedRows);
  }

  /// Live (content_type, count) of the current user's non-deleted items that
  /// already carry an enriched content type, sorted by count descending.
  Stream<List<(String, int)>> watchTypeCounts(String? userId) {
    final String userIdColumn = userId == null
        ? 'i.user_id IS NULL'
        : "i.user_id = '${userId.replaceAll("'", "''")}'";
    return customSelect(
      'SELECT im.content_type AS type, COUNT(*) AS count '
      'FROM item_metadata im '
      'JOIN items i ON i.id = im.item_id '
      'WHERE i.deleted_at IS NULL AND $userIdColumn '
      'AND im.content_type IS NOT NULL '
      'GROUP BY im.content_type',
    ).watch().map(
      (rows) =>
          rows
              .map((row) => (row.read<String>("type"), row.read<int>("count")))
              .toList()
            ..sort((a, b) => b.$2.compareTo(a.$2)),
    );
  }

  /// Non-deleted items of a given content type, newest first. Joins metadata
  /// so the type filter reads the enriched content_type column.
  Stream<List<(Item, ItemMetadataData?)>> watchItemsByType(
    String? userId,
    String type,
  ) {
    final query = _itemsWithMetadataQuery(userId)
      ..where(itemMetadata.contentType.equals(type))
      ..orderBy([OrderingTerm.desc(items.createdAt)]);
    return query.watch().map(_mapJoinedRows);
  }

  /// A single item (with its metadata) that stays live as rows change.
  Stream<(Item, ItemMetadataData?)?> watchItemWithMetadata(String id) {
    final query = select(items).join([
      leftOuterJoin(itemMetadata, itemMetadata.itemId.equalsExp(items.id)),
    ])..where(items.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null
          ? null
          : (row.readTable(items), row.readTableOrNull(itemMetadata)),
    );
  }

  /// Local-only LIKE search across item text, URL, enriched metadata
  /// (title, description, domain, site name) and the user's personal note.
  /// SQLite LIKE is case-insensitive for ASCII, which is adequate until FTS
  /// is introduced.
  Stream<List<(Item, ItemMetadataData?, ItemNote?)>> searchItems(
    String? userId,
    String query, {
    String? contentType,
  }) {
    final pattern = '%$query%';
    final match =
        items.title.like(pattern) |
        items.url.like(pattern) |
        items.textContent.like(pattern) |
        itemMetadata.title.like(pattern) |
        itemMetadata.description.like(pattern) |
        itemMetadata.domain.like(pattern) |
        itemMetadata.siteName.like(pattern) |
        itemNotes.content.like(pattern);
    final typeFilter = contentType == null
        ? const Constant<bool>(true)
        : itemMetadata.contentType.equals(contentType);
    final statement =
        select(items).join([
            leftOuterJoin(
              itemMetadata,
              itemMetadata.itemId.equalsExp(items.id),
            ),
            leftOuterJoin(itemNotes, itemNotes.itemId.equalsExp(items.id)),
          ])
          ..where(
            items.deletedAt.isNull() &
                (userId == null
                    ? items.userId.isNull()
                    : items.userId.equals(userId)) &
                typeFilter &
                match,
          )
          ..orderBy([OrderingTerm.desc(items.createdAt)]);
    return statement.watch().map(_mapSearchRows);
  }

  List<(Item, ItemMetadataData?, ItemNote?)> _mapSearchRows(
    List<TypedResult> rows,
  ) {
    return rows
        .map(
          (row) => (
            row.readTable(items),
            row.readTableOrNull(itemMetadata),
            row.readTableOrNull(itemNotes),
          ),
        )
        .toList();
  }

  JoinedSelectStatement<HasResultSet, dynamic> _itemsWithMetadataQuery(
    String? userId,
  ) {
    return select(items).join([
      leftOuterJoin(itemMetadata, itemMetadata.itemId.equalsExp(items.id)),
    ])..where(
      items.deletedAt.isNull() &
          (userId == null
              ? items.userId.isNull()
              : items.userId.equals(userId)),
    );
  }

  List<(Item, ItemMetadataData?)> _mapJoinedRows(List<TypedResult> rows) {
    return rows
        .map((row) => (row.readTable(items), row.readTableOrNull(itemMetadata)))
        .toList();
  }

  Future<ItemMetadataData?> metadataById(String itemId) {
    return (select(
      itemMetadata,
    )..where((metadata) => metadata.itemId.equals(itemId))).getSingleOrNull();
  }

  Future<void> upsertMetadata(ItemMetadataCompanion metadata) {
    return into(itemMetadata).insertOnConflictUpdate(metadata);
  }

  Future<void> updateMetadata(String itemId, ItemMetadataCompanion metadata) {
    return (update(
      itemMetadata,
    )..where((m) => m.itemId.equals(itemId))).write(metadata);
  }

  Future<ItemMetadataData?> enrichedMetadataForUrl(String url) async {
    final query =
        select(itemMetadata)
            .join([innerJoin(items, items.id.equalsExp(itemMetadata.itemId))])
          ..where(
            itemMetadata.status.equals('enriched') & items.url.equals(url),
          )
          ..limit(1);
    final rows = await query.get();
    if (rows.isEmpty) return null;
    return rows.first.readTable(itemMetadata);
  }

  Future<List<(Item, ItemMetadataData?)>> itemsToEnrich(String? userId) async {
    final query =
        select(items).join([
          leftOuterJoin(itemMetadata, itemMetadata.itemId.equalsExp(items.id)),
        ])..where(
          items.status.isNotValue('archived') &
              items.deletedAt.isNull() &
              items.url.isNotNull() &
              (userId == null
                  ? items.userId.isNull()
                  : items.userId.equals(userId)) &
              (itemMetadata.itemId.isNull() |
                  (itemMetadata.status.isIn(const ['pending', 'failed']) &
                      itemMetadata.attemptCount.isSmallerThanValue(4))),
        );
    return (await query.get())
        .map((row) => (row.readTable(items), row.readTableOrNull(itemMetadata)))
        .toList();
  }

  Future<void> resetStuckEnriching() {
    return (update(itemMetadata)..where((m) => m.status.equals('enriching')))
        .write(const ItemMetadataCompanion(status: Value('pending')));
  }

  Future<List<ItemMetadataData>> metadataNeedingSync(String userId) {
    return (select(
      itemMetadata,
    )..where((metadata) => metadata.userId.equals(userId))).get();
  }

  Future<void> updateItemStatus(String id, String status) {
    return (update(items)..where((item) => item.id.equals(id))).write(
      ItemsCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<void> updateItemFavorite(String id, bool favorite) {
    return (update(items)..where((item) => item.id.equals(id))).write(
      ItemsCompanion(
        favorite: Value(favorite),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<void> softDeleteItem(String id) {
    final now = DateTime.now();
    return transaction(() async {
      await (update(items)..where((item) => item.id.equals(id))).write(
        ItemsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(now),
          syncStatus: const Value('pending'),
        ),
      );
      await (update(attachments)..where(
            (attachment) =>
                attachment.itemId.equals(id) & attachment.deletedAt.isNull(),
          ))
          .write(
            AttachmentsCompanion(
              deletedAt: Value(now),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );
    });
  }

  Future<void> saveItemWithAttachments(
    ItemsCompanion item,
    List<AttachmentsCompanion> attachmentRows,
  ) {
    return transaction(() async {
      await into(items).insert(item);
      await batch((batch) => batch.insertAll(attachments, attachmentRows));
    });
  }

  Stream<List<Attachment>> watchAttachmentsForItem(
    String itemId,
    String? userId,
  ) {
    return (select(attachments)
          ..where(
            (attachment) =>
                attachment.itemId.equals(itemId) &
                attachment.deletedAt.isNull() &
                (userId == null
                    ? attachment.userId.isNull()
                    : attachment.userId.equals(userId)),
          )
          ..orderBy([(attachment) => OrderingTerm.asc(attachment.createdAt)]))
        .watch();
  }

  Future<Set<String>> attachmentIds() async {
    final rows = await (selectOnly(
      attachments,
    )..addColumns([attachments.id])).get();
    return rows.map((row) => row.read(attachments.id)!).toSet();
  }

  Future<List<Attachment>> attachmentsForItem(String itemId) {
    return (select(
      attachments,
    )..where((attachment) => attachment.itemId.equals(itemId))).get();
  }

  Future<List<Attachment>> attachmentsNeedingUpload(String userId) {
    return (select(attachments)..where(
          (attachment) =>
              attachment.userId.equals(userId) &
              attachment.deletedAt.isNull() &
              (attachment.localPath.isNotNull() |
                  attachment.localBytes.isNotNull()) &
              attachment.r2ObjectKey.isNull() &
              attachment.uploadStatus.isIn(const [
                'local',
                'pending',
                'uploading',
                'failed',
              ]),
        ))
        .get();
  }

  Future<List<Attachment>> attachmentsNeedingSync(String userId) {
    return (select(attachments)..where(
          (attachment) =>
              attachment.userId.equals(userId) &
              attachment.syncStatus.isIn(const ['pending', 'failed']) &
              (attachment.deletedAt.isNotNull() |
                  attachment.r2ObjectKey.isNotNull()),
        ))
        .get();
  }

  Future<void> markAttachmentUploading(String id) {
    return (update(attachments)..where((row) => row.id.equals(id))).write(
      const AttachmentsCompanion(uploadStatus: Value('uploading')),
    );
  }

  Future<void> markAttachmentUploaded(String id, String objectKey, String userId) {
    return (update(attachments)..where((row) => row.id.equals(id))).write(
      AttachmentsCompanion(
        userId: Value(userId),
        r2ObjectKey: Value(objectKey),
        uploadStatus: const Value('uploaded'),
        uploadAttempts: const Value(0),
        uploadLastError: const Value(null),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markAttachmentUploadFailed(String id, String error) async {
    final row = await (select(
      attachments,
    )..where((attachment) => attachment.id.equals(id))).getSingle();
    await (update(
      attachments,
    )..where((attachment) => attachment.id.equals(id))).write(
      AttachmentsCompanion(
        uploadStatus: const Value('failed'),
        uploadAttempts: Value(row.uploadAttempts + 1),
        uploadLastError: Value(error),
      ),
    );
  }

  Future<void> retryAttachmentUpload(String id) {
    return (update(attachments)..where((row) => row.id.equals(id))).write(
      const AttachmentsCompanion(
        uploadStatus: Value('pending'),
        uploadLastError: Value(null),
        syncStatus: Value('pending'),
      ),
    );
  }

  Future<void> markAttachmentSynced(String id, DateTime syncedAt) {
    return (update(attachments)..where((row) => row.id.equals(id))).write(
      AttachmentsCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(syncedAt),
      ),
    );
  }

  Future<void> markAttachmentSyncFailed(String id) {
    return (update(attachments)..where((row) => row.id.equals(id))).write(
      const AttachmentsCompanion(syncStatus: Value('failed')),
    );
  }

  Future<void> upsertRemoteAttachment(AttachmentsCompanion remote) async {
    final id = remote.id.value;
    final existing = await (select(
      attachments,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    await into(attachments).insertOnConflictUpdate(
      remote.copyWith(
        localPath: Value(existing?.localPath),
        localBytes: Value(existing?.localBytes),
        downloadStatus: Value(
          existing?.localPath == null && existing?.localBytes == null
              ? 'remote'
              : 'downloaded',
        ),
      ),
    );
  }

  Future<void> markAttachmentDownloading(String id) {
    return (update(attachments)..where((row) => row.id.equals(id))).write(
      const AttachmentsCompanion(downloadStatus: Value('downloading')),
    );
  }

  Future<void> markAttachmentDownloaded(String id, String localPath) {
    return (update(attachments)..where((row) => row.id.equals(id))).write(
      AttachmentsCompanion(
        localPath: Value(localPath),
        downloadStatus: const Value('downloaded'),
      ),
    );
  }

  Future<void> markAttachmentDownloadFailed(String id) {
    return (update(attachments)..where((row) => row.id.equals(id))).write(
      const AttachmentsCompanion(downloadStatus: Value('failed')),
    );
  }

  Future<void> createCollection(String id, String? userId, String name) {
    final now = DateTime.now();
    return into(collections).insert(
      CollectionsCompanion.insert(
        id: id,
        userId: Value(userId),
        name: name,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> renameCollection(String id, String name) {
    return (update(collections)..where((c) => c.id.equals(id))).write(
      CollectionsCompanion(
        name: Value(name),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<void> softDeleteCollection(String id) {
    return (update(collections)..where((c) => c.id.equals(id))).write(
      CollectionsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Adds an item to a collection. If the membership was previously removed
  /// (soft deleted) it is restored rather than re-inserted, keeping its
  /// original userId and createdAt.
  Future<void> addItemToCollection(String collectionId, String itemId) async {
    final now = DateTime.now();
    final existing = await collectionItemById(collectionId, itemId);
    if (existing == null) {
      await into(collectionItems).insert(
        CollectionItemsCompanion.insert(
          collectionId: collectionId,
          itemId: itemId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await (update(collectionItems)..where(
            (row) =>
                row.collectionId.equals(collectionId) &
                row.itemId.equals(itemId),
          ))
          .write(
            CollectionItemsCompanion(
              deletedAt: const Value(null),
              updatedAt: Value(now),
              syncStatus: const Value('pending'),
            ),
          );
    }
  }

  /// Removes an item from a collection by soft deleting the membership
  /// (tombstone), so a later sync can never resurrect it accidentally.
  Future<void> removeItemFromCollection(String collectionId, String itemId) {
    return (update(collectionItems)..where(
          (row) =>
              row.collectionId.equals(collectionId) & row.itemId.equals(itemId),
        ))
        .write(
          CollectionItemsCompanion(
            deletedAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
            syncStatus: const Value('pending'),
          ),
        );
  }

  Stream<List<Collection>> watchCollections(String? userId) {
    return (select(collections)
          ..where(
            (collection) =>
                collection.deletedAt.isNull() &
                (userId == null
                    ? collection.userId.isNull()
                    : collection.userId.equals(userId)),
          )
          ..orderBy([(collection) => OrderingTerm.asc(collection.createdAt)]))
        .watch();
  }

  Stream<List<Collection>> watchCollectionsForItem(
    String itemId,
    String? userId,
  ) {
    final query =
        select(collections).join([
            innerJoin(
              collectionItems,
              collectionItems.collectionId.equalsExp(collections.id),
            ),
          ])
          ..where(
            collectionItems.itemId.equals(itemId) &
                collectionItems.deletedAt.isNull() &
                collections.deletedAt.isNull() &
                (userId == null
                    ? collections.userId.isNull()
                    : collections.userId.equals(userId)),
          )
          ..orderBy([OrderingTerm.asc(collections.createdAt)]);
    return query.watch().map(
      (rows) => rows.map((row) => row.readTable(collections)).toList(),
    );
  }

  /// Non-deleted collections with the number of non-deleted items each
  /// currently contains.
  Stream<List<(Collection, int)>> watchCollectionCounts(String? userId) {
    final count = collectionItems.itemId.count(
      filter: collectionItems.deletedAt.isNull(),
    );
    final query =
        select(collections).join([
            leftOuterJoin(
              collectionItems,
              collectionItems.collectionId.equalsExp(collections.id),
            ),
          ])
          ..where(
            collections.deletedAt.isNull() &
                (userId == null
                    ? collections.userId.isNull()
                    : collections.userId.equals(userId)),
          )
          ..addColumns([count])
          ..groupBy([collections.id])
          ..orderBy([OrderingTerm.asc(collections.createdAt)]);
    return query.watch().map(
      (rows) => rows
          .map((row) => (row.readTable(collections), row.read(count) ?? 0))
          .toList(),
    );
  }

  Stream<List<(Item, ItemMetadataData?)>> watchItemsInCollection(
    String collectionId,
    String? userId,
  ) {
    final query =
        select(items).join([
            innerJoin(
              collectionItems,
              collectionItems.itemId.equalsExp(items.id),
            ),
            leftOuterJoin(
              itemMetadata,
              itemMetadata.itemId.equalsExp(items.id),
            ),
          ])
          ..where(
            collectionItems.collectionId.equals(collectionId) &
                collectionItems.deletedAt.isNull() &
                items.deletedAt.isNull() &
                (userId == null
                    ? items.userId.isNull()
                    : items.userId.equals(userId)),
          )
          ..orderBy([OrderingTerm.desc(collectionItems.createdAt)]);
    return query.watch().map(_mapJoinedRows);
  }

  Future<Collection?> collectionById(String id) {
    return (select(
      collections,
    )..where((collection) => collection.id.equals(id))).getSingleOrNull();
  }

  Future<CollectionItem?> collectionItemById(
    String collectionId,
    String itemId,
  ) {
    return (select(collectionItems)..where(
          (row) =>
              row.collectionId.equals(collectionId) & row.itemId.equals(itemId),
        ))
        .getSingleOrNull();
  }

  /// Claims pending guest collections for the signed-in user, then returns
  /// every collection still waiting to be pushed.
  Future<List<Collection>> collectionsNeedingSync(String userId) async {
    await (update(collections)..where(
          (collection) =>
              collection.userId.isNull() &
              collection.syncStatus.isIn(const ['pending', 'failed']),
        ))
        .write(CollectionsCompanion(userId: Value(userId)));

    return (select(collections)..where(
          (collection) =>
              collection.userId.equals(userId) &
              collection.syncStatus.isIn(const ['pending', 'failed']),
        ))
        .get();
  }

  /// Claims pending guest memberships for the signed-in user, then returns
  /// every membership still waiting to be pushed.
  Future<List<CollectionItem>> collectionItemsNeedingSync(String userId) async {
    await (update(collectionItems)..where(
          (row) =>
              row.userId.isNull() &
              row.syncStatus.isIn(const ['pending', 'failed']),
        ))
        .write(CollectionItemsCompanion(userId: Value(userId)));

    return (select(collectionItems)..where(
          (row) =>
              row.userId.equals(userId) &
              row.syncStatus.isIn(const ['pending', 'failed']),
        ))
        .get();
  }

  Future<void> upsertRemoteCollection(CollectionsCompanion collection) {
    return into(collections).insertOnConflictUpdate(collection);
  }

  Future<void> upsertRemoteCollectionItem(CollectionItemsCompanion row) {
    return into(collectionItems).insertOnConflictUpdate(row);
  }

  Future<void> markCollectionSynced(String id, DateTime syncedAt) {
    return (update(collections)..where((c) => c.id.equals(id))).write(
      CollectionsCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(syncedAt),
      ),
    );
  }

  Future<void> markCollectionFailed(String id) {
    return (update(collections)..where((c) => c.id.equals(id))).write(
      const CollectionsCompanion(syncStatus: Value('failed')),
    );
  }

  Future<void> markCollectionItemSynced(
    String collectionId,
    String itemId,
    DateTime syncedAt,
  ) {
    return (update(collectionItems)..where(
          (row) =>
              row.collectionId.equals(collectionId) & row.itemId.equals(itemId),
        ))
        .write(
          CollectionItemsCompanion(
            syncStatus: const Value('synced'),
            lastSyncedAt: Value(syncedAt),
          ),
        );
  }

  Future<void> markCollectionItemFailed(String collectionId, String itemId) {
    return (update(collectionItems)..where(
          (row) =>
              row.collectionId.equals(collectionId) & row.itemId.equals(itemId),
        ))
        .write(const CollectionItemsCompanion(syncStatus: Value('failed')));
  }

  /// The current user's non-deleted note for a live item, as a stream. Notes
  /// of deleted items are hidden so a removed item never resurfaces a note.
  Stream<ItemNote?> watchNote(String itemId, String? userId) {
    return (select(itemNotes)
            .join([innerJoin(items, items.id.equalsExp(itemNotes.itemId))])
          ..where(
            itemNotes.itemId.equals(itemId) &
                itemNotes.deletedAt.isNull() &
                items.deletedAt.isNull() &
                (userId == null
                    ? itemNotes.userId.isNull()
                    : itemNotes.userId.equals(userId)),
          ))
        .watchSingleOrNull()
        .map((row) => row?.readTable(itemNotes));
  }

  /// The raw note row for an item (tombstones included), used by sync.
  Future<ItemNote?> noteById(String itemId) {
    return (select(
      itemNotes,
    )..where((note) => note.itemId.equals(itemId))).getSingleOrNull();
  }

  /// Reads a single settings value, or `null` when the key has never been set.
  Future<String?> readSetting(String key) async {
    final row = await (select(
      appSettings,
    )..where((setting) => setting.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Upserts a settings value; `null` removes the key.
  Future<void> writeSetting(String key, String? value) async {
    if (value == null) {
      await (delete(
        appSettings,
      )..where((setting) => setting.key.equals(key))).go();
      return;
    }
    await into(appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: Value(value)),
    );
  }

  /// Live stream of every stored setting, emitted when any value changes.
  Stream<List<AppSetting>> watchAllSettings() => select(appSettings).watch();

  /// Creates or restores the note for an item. A previously tombstoned note
  /// is revived, keeping its original userId.
  Future<void> saveNote(String itemId, String? userId, String content) async {
    final now = DateTime.now();
    final existing = await noteById(itemId);
    if (existing == null) {
      await into(itemNotes).insert(
        ItemNotesCompanion.insert(
          itemId: itemId,
          userId: Value(userId),
          content: content,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      await (update(
        itemNotes,
      )..where((note) => note.itemId.equals(itemId))).write(
        ItemNotesCompanion(
          userId: Value(userId),
          content: Value(content),
          updatedAt: Value(now),
          deletedAt: const Value(null),
          syncStatus: const Value('pending'),
        ),
      );
    }
  }

  /// Tombstones the note so an old device can never resurrect it.
  Future<void> deleteNote(String itemId) {
    return (update(
      itemNotes,
    )..where((note) => note.itemId.equals(itemId))).write(
      ItemNotesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
    );
  }

  /// Claims pending guest notes for the signed-in user, then returns every
  /// note still waiting to be pushed.
  Future<List<ItemNote>> notesNeedingSync(String userId) async {
    await (update(itemNotes)..where(
          (note) =>
              note.userId.isNull() &
              note.syncStatus.isIn(const ['pending', 'failed']),
        ))
        .write(ItemNotesCompanion(userId: Value(userId)));

    return (select(itemNotes)..where(
          (note) =>
              note.userId.equals(userId) &
              note.syncStatus.isIn(const ['pending', 'failed']),
        ))
        .get();
  }

  Future<void> upsertRemoteNote(ItemNotesCompanion note) {
    return into(itemNotes).insertOnConflictUpdate(note);
  }

  Future<void> markNoteSynced(String itemId, DateTime syncedAt) {
    return (update(
      itemNotes,
    )..where((note) => note.itemId.equals(itemId))).write(
      ItemNotesCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(syncedAt),
      ),
    );
  }

  Future<void> markNoteFailed(String itemId) {
    return (update(itemNotes)..where((note) => note.itemId.equals(itemId)))
        .write(const ItemNotesCompanion(syncStatus: Value('failed')));
  }

  Stream<SyncStatsData> watchSyncStats(String? userId) {
    if (userId == null || userId.isEmpty) {
      return customSelect(
        '''
        SELECT 
          (SELECT COUNT(*) FROM items WHERE user_id IS NULL) as total_items,
          0 as pending_items,
          (SELECT COUNT(*) FROM attachments WHERE user_id IS NULL) as total_attachments,
          0 as pending_attachments
        ''',
        readsFrom: {items, attachments},
      ).watchSingle().map((row) {
        return SyncStatsData(
          totalItems: row.read<int>('total_items'),
          pendingItems: 0,
          totalAttachments: row.read<int>('total_attachments'),
          pendingAttachments: 0,
        );
      });
    }

    return customSelect(
      '''
      SELECT 
        (SELECT COUNT(*) FROM items WHERE user_id = :userId) as total_items,
        (SELECT COUNT(*) FROM items WHERE user_id = :userId AND sync_status IN ('pending', 'failed')) as pending_items,
        (SELECT COUNT(*) FROM attachments WHERE user_id = :userId) as total_attachments,
        (SELECT COUNT(*) FROM attachments WHERE user_id = :userId AND (r2_object_key IS NULL OR sync_status IN ('pending', 'failed'))) as pending_attachments
      ''',
      variables: [Variable.withString(userId)],
      readsFrom: {items, attachments},
    ).watchSingle().map((row) {
      final totalItems = row.read<int>('total_items');
      final pendingItems = row.read<int>('pending_items');
      final totalAttachments = row.read<int>('total_attachments');
      final pendingAttachments = row.read<int>('pending_attachments');
      return SyncStatsData(
        totalItems: totalItems,
        pendingItems: pendingItems,
        totalAttachments: totalAttachments,
        pendingAttachments: pendingAttachments,
      );
    });
  }
}

class SyncStatsData {
  const SyncStatsData({
    required this.totalItems,
    required this.pendingItems,
    required this.totalAttachments,
    required this.pendingAttachments,
  });

  final int totalItems;
  final int pendingItems;
  final int totalAttachments;
  final int pendingAttachments;

  int get totalCount => totalItems + totalAttachments;
  int get pendingCount => pendingItems + pendingAttachments;
  int get syncedCount => (totalCount - pendingCount).clamp(0, totalCount);

  double get progressFraction =>
      totalCount == 0 ? 1.0 : (syncedCount / totalCount).clamp(0.0, 1.0);

  int get percentage => (progressFraction * 100).round();
}

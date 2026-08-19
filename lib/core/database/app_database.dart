import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Items extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get textContent => text().nullable()();
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
  TextColumn get collectionId => text().references(
        Collections,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get itemId => text().references(
        Items,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {collectionId, itemId};
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
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {itemId};
}

@DriftDatabase(tables: [Items, ItemMetadata, Collections, CollectionItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'laterbox'));

  @override
  int get schemaVersion => 5;

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
        await migrator.database
            .customStatement('ALTER TABLE items DROP COLUMN archived');
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
    await (update(items)..where(
          (item) =>
              item.userId.isNull() &
              item.syncStatus.isIn(const ['pending', 'failed']),
        ))
        .write(ItemsCompanion(userId: Value(userId)));

    return (select(items)..where(
          (item) =>
              item.userId.equals(userId) &
              item.syncStatus.isIn(const ['pending', 'failed']),
        ))
        .get();
  }

  Future<Item?> itemById(String id) {
    return (select(
      items,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
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

  /// A single item (with its metadata) that stays live as rows change.
  Stream<(Item, ItemMetadataData?)?> watchItemWithMetadata(String id) {
    final query = select(items).join([
      leftOuterJoin(itemMetadata, itemMetadata.itemId.equalsExp(items.id)),
    ])
      ..where(items.id.equals(id));
    return query
        .watchSingleOrNull()
        .map((row) => row == null
            ? null
            : (
                row.readTable(items),
                row.readTableOrNull(itemMetadata),
              ));
  }

  /// Local-only LIKE search across item text, URL and enriched metadata
  /// (title, description, domain, site name). SQLite LIKE is case-insensitive
  /// for ASCII, which is adequate until FTS is introduced.
  Stream<List<(Item, ItemMetadataData?)>> searchItems(
    String? userId,
    String query,
  ) {
    final pattern = '%$query%';
    final match =
        items.title.like(pattern) |
        items.url.like(pattern) |
        items.textContent.like(pattern) |
        itemMetadata.title.like(pattern) |
        itemMetadata.description.like(pattern) |
        itemMetadata.domain.like(pattern) |
        itemMetadata.siteName.like(pattern);
    final statement = _itemsWithMetadataQuery(userId)
      ..where(match)
      ..orderBy([OrderingTerm.desc(items.createdAt)]);
    return statement.watch().map(_mapJoinedRows);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _itemsWithMetadataQuery(
    String? userId,
  ) {
    return select(items).join([
      leftOuterJoin(itemMetadata, itemMetadata.itemId.equalsExp(items.id)),
    ])
      ..where(
        items.deletedAt.isNull() &
            (userId == null
                ? items.userId.isNull()
                : items.userId.equals(userId)),
      );
  }

  List<(Item, ItemMetadataData?)> _mapJoinedRows(List<TypedResult> rows) {
    return rows
        .map(
          (row) => (
            row.readTable(items),
            row.readTableOrNull(itemMetadata),
          ),
        )
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
    return (update(itemMetadata)..where((m) => m.itemId.equals(itemId))).write(
      metadata,
    );
  }

  Future<ItemMetadataData?> enrichedMetadataForUrl(String url) async {
    final query = select(itemMetadata).join([
      innerJoin(items, items.id.equalsExp(itemMetadata.itemId)),
    ])
      ..where(
        itemMetadata.status.equals('enriched') & items.url.equals(url),
      )
      ..limit(1);
    final rows = await query.get();
    if (rows.isEmpty) return null;
    return rows.first.readTable(itemMetadata);
  }

  Future<List<(Item, ItemMetadataData?)>> itemsToEnrich(String? userId) async {
    final query = select(items).join([
      leftOuterJoin(itemMetadata, itemMetadata.itemId.equalsExp(items.id)),
    ])
      ..where(
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
        .map(
          (row) => (
            row.readTable(items),
            row.readTableOrNull(itemMetadata),
          ),
        )
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
    return (update(items)..where((item) => item.id.equals(id))).write(
      ItemsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value('pending'),
      ),
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
      await (update(collectionItems)
            ..where(
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
    return (update(collectionItems)
          ..where(
            (row) =>
                row.collectionId.equals(collectionId) &
                row.itemId.equals(itemId),
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
    final query = select(collections).join([
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
    final count =
        collectionItems.itemId.count(filter: collectionItems.deletedAt.isNull());
    final query = select(collections).join([
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
          .map(
            (row) => (
              row.readTable(collections),
              row.read(count) ?? 0,
            ),
          )
          .toList(),
    );
  }

  Stream<List<(Item, ItemMetadataData?)>> watchItemsInCollection(
    String collectionId,
    String? userId,
  ) {
    final query = select(items).join([
      innerJoin(
        collectionItems,
        collectionItems.itemId.equalsExp(items.id),
      ),
      leftOuterJoin(itemMetadata, itemMetadata.itemId.equalsExp(items.id)),
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
    return (select(
      collectionItems,
    )..where(
        (row) =>
            row.collectionId.equals(collectionId) & row.itemId.equals(itemId),
      )).getSingleOrNull();
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
    return (update(collectionItems)
          ..where(
            (row) =>
                row.collectionId.equals(collectionId) &
                row.itemId.equals(itemId),
          ))
        .write(
      CollectionItemsCompanion(
        syncStatus: const Value('synced'),
        lastSyncedAt: Value(syncedAt),
      ),
    );
  }

  Future<void> markCollectionItemFailed(String collectionId, String itemId) {
    return (update(collectionItems)
          ..where(
            (row) =>
                row.collectionId.equals(collectionId) &
                row.itemId.equals(itemId),
          ))
        .write(const CollectionItemsCompanion(syncStatus: Value('failed')));
  }
}

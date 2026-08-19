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
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
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

@DriftDatabase(tables: [Items, ItemMetadata])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'laterbox'));

  @override
  int get schemaVersion => 3;

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
    },
  );

  Stream<List<Item>> watchInboxItems(String? userId) {
    return (select(items)
          ..where(
            (item) =>
                item.archived.equals(false) &
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
    final query = select(items).join([
      leftOuterJoin(itemMetadata, itemMetadata.itemId.equalsExp(items.id)),
    ])
      ..where(
        items.archived.equals(false) &
            items.deletedAt.isNull() &
            (userId == null
                ? items.userId.isNull()
                : items.userId.equals(userId)),
      )
      ..orderBy([OrderingTerm.desc(items.createdAt)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => (
              row.readTable(items),
              row.readTableOrNull(itemMetadata),
            ),
          )
          .toList(),
    );
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
        items.archived.equals(false) &
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
}

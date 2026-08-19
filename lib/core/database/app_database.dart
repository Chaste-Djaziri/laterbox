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

@DriftDatabase(tables: [Items])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'laterbox'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(items, items.userId);
        await migrator.addColumn(items, items.lastSyncedAt);
        await migrator.addColumn(items, items.deletedAt);
      }
    },
  );

  Stream<List<Item>> watchInboxItems() {
    return (select(items)
          ..where(
            (item) => item.archived.equals(false) & item.deletedAt.isNull(),
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
}

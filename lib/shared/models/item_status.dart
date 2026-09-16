/// Where an item sits in its lifecycle.
///
/// New captures enter `deferred`; Inbox visibility is derived from return time.
/// `inbox` remains readable for legacy clients. "Keep" moves an item to `saved`, which is the
/// state of anything deliberately kept in the library. Archiving marks it as
/// `archived`. Favoriting is orthogonal and stored separately.
enum ItemStatus {
  inbox,
  deferred,
  saved,
  archived;

  String get databaseValue => name;

  static ItemStatus fromDatabase(String value) {
    return ItemStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => ItemStatus.inbox,
    );
  }
}
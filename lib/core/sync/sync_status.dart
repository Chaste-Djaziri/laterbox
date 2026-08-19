enum SyncStatus {
  pending,
  synced,
  failed;

  String get databaseValue => name;
}

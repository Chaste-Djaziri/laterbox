import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/inbox/data/local_item_data_source.dart';
import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final localItemDataSourceProvider = Provider<LocalItemDataSource>((ref) {
  return LocalItemDataSource(ref.watch(appDatabaseProvider));
});

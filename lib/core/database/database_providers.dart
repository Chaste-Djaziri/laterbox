import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/inbox/data/item_repository.dart';
import 'app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository(ref.watch(appDatabaseProvider));
});

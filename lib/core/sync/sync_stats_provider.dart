import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../database/app_database.dart';
import '../database/database_providers.dart';

final syncStatsProvider = StreamProvider<SyncStatsData>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final userId = ref.watch(currentUserIdProvider);
  return db.watchSyncStats(userId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../database/app_database.dart';
import '../database/database_providers.dart';

final syncStatsProvider = StreamProvider<SyncStatsData>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final authState = ref.watch(authStateProvider).asData?.value;
  final userId = authState?.user?.id;
  return db.watchSyncStats(userId);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../data/item_note_repository.dart';

final itemNoteRepositoryProvider = Provider<ItemNoteRepository>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return ItemNoteRepository(
    ref.watch(localItemNoteDataSourceProvider),
    userId: ref.watch(activeUserIdProvider),
    onChanged: () async => coordinator.requestSync(),
  );
});

/// The current user's non-deleted note for an item, as a live stream.
final itemNoteProvider = StreamProvider.family<ItemNote?, String>((ref, itemId) {
  return ref.watch(itemNoteRepositoryProvider).watchNote(itemId);
});
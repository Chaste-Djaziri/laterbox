import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../shared/models/laterbox_item.dart';
import '../data/item_repository.dart';

final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  final coordinator = ref.watch(syncCoordinatorProvider);
  return ItemRepository(
    ref.watch(localItemDataSourceProvider),
    onSaved: () async => coordinator.requestSync(),
  );
});

final inboxItemsProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchInboxItems();
});

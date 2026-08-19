import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../shared/models/laterbox_item.dart';

final inboxItemsProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchInboxItems();
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/laterbox_item.dart';
import '../../inbox/presentation/inbox_providers.dart';

/// Every saved item (including archived), newest first. Used by the Library
/// tab and the Search screen's recent list.
final allItemsProvider = StreamProvider<List<LaterBoxItem>>((ref) {
  return ref.watch(itemRepositoryProvider).watchAllItems();
});
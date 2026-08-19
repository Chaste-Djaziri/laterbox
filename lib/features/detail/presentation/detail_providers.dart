import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/laterbox_item.dart';
import '../../inbox/presentation/inbox_providers.dart';

/// Live view of a single item, so the detail screen reflects edits (favorite,
/// status, deletion) as they happen.
final itemDetailProvider =
    StreamProvider.family<LaterBoxItem?, String>((ref, itemId) {
  return ref.watch(itemRepositoryProvider).watchItem(itemId);
});
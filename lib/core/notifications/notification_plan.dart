import '../database/app_database.dart';

/// OS notification queues are bounded; plan only future, locally owned returns.
List<Item> planLocalReminders(
  List<Item> items, {
  required DateTime now,
  required bool enabled,
  required bool cloudActive,
  required Set<String> handedOff,
  int limit = 60,
}) {
  if (!enabled) return [];
  final candidates =
      items
          .where(
            (item) =>
                item.deletedAt == null &&
                (item.status == 'inbox' || item.status == 'deferred') &&
                item.returnAt != null &&
                item.returnAt!.isAfter(now) &&
                !(cloudActive &&
                    (item.lastSyncedAt != null || handedOff.contains(item.id))),
          )
          .toList()
        ..sort((a, b) {
          final byTime = a.returnAt!.compareTo(b.returnAt!);
          return byTime == 0 ? a.id.compareTo(b.id) : byTime;
        });
  return candidates.take(limit).toList();
}

bool retainDeliveredReminder(
  List<Item> items,
  String id,
  String revision,
  DateTime now,
) => items.any(
  (item) =>
      item.id == id &&
      item.deletedAt == null &&
      (item.status == 'inbox' || item.status == 'deferred') &&
      item.returnAt?.toUtc().toIso8601String() == revision &&
      !item.returnAt!.isAfter(now),
);

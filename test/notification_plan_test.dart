import 'package:flutter_test/flutter_test.dart';
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/notifications/notification_plan.dart';

void main() {
  final now = DateTime.utc(2026, 9, 19, 12);
  Item item(
    String id, {
    DateTime? due,
    String status = 'deferred',
    bool synced = false,
    bool deleted = false,
  }) => Item(
    id: id,
    type: 'note',
    favorite: false,
    status: status,
    createdAt: now.subtract(const Duration(days: 1)),
    updatedAt: now,
    returnAt: due,
    syncStatus: synced ? 'synced' : 'pending',
    lastSyncedAt: synced ? now : null,
    deletedAt: deleted ? now : null,
  );
  List<Item> plan(
    List<Item> items, {
    bool cloud = false,
    Set<String> handoff = const {},
    bool enabled = true,
  }) => planLocalReminders(
    items,
    now: now,
    enabled: enabled,
    cloudActive: cloud,
    handedOff: handoff,
  );

  test('future returns only; existing history and Someday never notify', () {
    final future = now.add(const Duration(hours: 1));
    expect(
      plan([
        item('future', due: future),
        item('old', due: now.subtract(const Duration(seconds: 1))),
        item('exact', due: now),
        item('someday'),
        item('archived', due: future, status: 'archived'),
        item('saved', due: future, status: 'saved'),
        item('deleted', due: future, deleted: true),
      ]).map((x) => x.id),
      ['future'],
    );
  });
  test('cloud ownership excludes synced and handed-off captures, preserving unsynced reminders', () {
    final future = now.add(const Duration(hours: 1));
    final items = [
      item('synced', due: future, synced: true),
      item('uploading', due: future),
      item('offline', due: future),
    ];
    expect(plan(items, cloud: true, handoff: {'uploading'}).map((x) => x.id), [
      'offline',
    ]);
    expect(plan(items, cloud: true).map((x) => x.id), ['offline', 'uploading']);
    expect(plan(items).length, 3);
    expect(plan(items, enabled: false), isEmpty);
  });
  test('bounded OS queue prioritizes earliest deadlines and replaces a rescheduled item', () {
    final items = List.generate(
      70,
      (i) => item('$i', due: now.add(Duration(minutes: i + 1))),
    );
    final planned = plan(items.reversed.toList());
    expect(planned.length, 60);
    expect(planned.first.id, '0');
    expect(planned.last.id, '59');
    final moved = items
        .map(
          (i) => i.id == '0'
              ? item('0', due: now.add(const Duration(days: 1)))
              : i,
        )
        .toList();
    expect(plan(moved).any((i) => i.id == '0'), false);
  });
  test('delivered notifications stay visible until the item is archived, removed or rescheduled', () {
    final due = now.subtract(const Duration(seconds: 1));
    final revision = due.toIso8601String();
    expect(
      retainDeliveredReminder([item('a', due: due)], 'a', revision, now),
      true,
    );
    expect(
      retainDeliveredReminder(
        [item('a', due: due, status: 'archived')],
        'a',
        revision,
        now,
      ),
      false,
    );
    expect(retainDeliveredReminder([], 'a', revision, now), false);
    expect(
      retainDeliveredReminder(
        [item('a', due: now.add(const Duration(hours: 1)))],
        'a',
        revision,
        now,
      ),
      false,
    );
  });
}

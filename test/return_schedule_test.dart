import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:laterbox/core/database/app_database.dart';
import 'package:laterbox/core/database/database_providers.dart';
import 'package:laterbox/core/auth/auth_provider.dart';
import 'package:laterbox/features/capture/domain/capture_payload.dart';
import 'package:laterbox/features/capture/domain/capture_service.dart';
import 'package:laterbox/features/inbox/data/item_repository.dart';
import 'package:laterbox/features/inbox/data/local_item_data_source.dart';
import 'package:laterbox/features/inbox/data/remote_item_data_source.dart';
import 'package:laterbox/features/inbox/presentation/inbox_providers.dart';
import 'package:laterbox/features/scheduling/domain/return_schedule.dart';
import 'package:laterbox/features/scheduling/presentation/schedule_providers.dart';
import 'package:laterbox/features/scheduling/presentation/return_time_picker.dart';
import 'package:laterbox/shared/models/item_status.dart';
import 'package:laterbox/shared/models/laterbox_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 9, 16, 23, 30);
  LaterBoxItem item(String id, DateTime? time, {ItemStatus status = ItemStatus.deferred}) =>
    LaterBoxItem(id: id, createdAt: now, returnAt: time, status: status);

  test('due-only Inbox keeps overdue and exact-deadline items', () {
    expect(item('future', now.add(const Duration(seconds: 1))).isDue(now), isFalse);
    expect(item('due', now).isDue(now), isTrue);
    expect(item('overdue', now.subtract(const Duration(days: 2))).isDue(now), isTrue);
    expect(item('someday', null).isDue(now), isFalse);
    expect(item('kept', now, status: ItemStatus.saved).isDue(now), isFalse);
    expect(item('done', now, status: ItemStatus.archived).isDue(now), isFalse);
    expect(item('legacy', null, status: ItemStatus.inbox).isDue(now), isTrue);
  });

  test('presets resolve in local time and are stored as UTC', () {
    expect(resolveReturnPreset(ReturnPreset.now, now), now.toUtc());
    expect(resolveReturnPreset(ReturnPreset.laterToday, now), now.add(const Duration(hours: 3)).toUtc());
    expect(resolveReturnPreset(ReturnPreset.tomorrow, now), DateTime(2026, 9, 17, 9).toUtc());
    expect(resolveReturnPreset(ReturnPreset.weekend, now), DateTime(2026, 9, 19, 9).toUtc());
    expect(resolveReturnPreset(ReturnPreset.weekend, DateTime(2026, 9, 19, 8)), DateTime(2026, 9, 26, 9).toUtc());
    expect(resolveReturnPreset(ReturnPreset.weekend, DateTime(2026, 9, 20)), DateTime(2026, 9, 26, 9).toUtc());
    expect(resolveReturnPreset(ReturnPreset.someday, now), isNull);
  });

  test('Today includes timed items only on the current local date', () {
    final list = [item('today', now), item('tomorrow', DateTime(2026, 9, 17, 9)), item('someday', null), item('archived', now, status: ItemStatus.archived)];
    expect(scheduleItems(list, ScheduleView.today, now).map((i) => i.id), ['today']);
    expect(scheduleItems(list, ScheduleView.today, DateTime(2026, 9, 17)).map((i) => i.id), ['tomorrow']);
    expect(scheduleItems(list, ScheduleView.upcoming, now).map((i) => i.id), ['tomorrow']);
    expect(scheduleItems(list, ScheduleView.someday, now).map((i) => i.id), ['someday']);
  });

  test('capture, duplicate, reschedule, complete and remote round trip', () async {
    final db = AppDatabase(NativeDatabase.memory()); addTearDown(db.close);
    final local = LocalItemDataSource(db);
    final repo = ItemRepository(local, userId: 'user-a', onSaved: () async {});
    final service = CaptureService(repo);
    await service.save(CapturePayload.fromValue('Do the thing', id: 'task', type: 'task', returnAt: now.toUtc()));
    var saved = (await repo.watchAllItems().first).single;
    expect(saved.type, 'task'); expect(saved.returnAt, now.toUtc()); expect(saved.isDue(now), isTrue);
    expect(await repo.save('Do the thing', returnAt: now.add(const Duration(days: 1))), 'task');
    expect((await db.itemById('task'))!.returnAt?.toUtc(), now.toUtc());
    await repo.reschedule('task', now.add(const Duration(days: 1)));
    saved = (await repo.watchAllItems().first).single;
    expect(saved.isDue(now), isFalse);
    expect((await db.itemById('task'))!.syncStatus, 'pending');
    await repo.reschedule('task', null);
    expect((await db.itemById('task'))!.returnAt, isNull);
    await repo.reschedule('task', now);
    await repo.archive('task');
    expect((await repo.watchAllItems().first).single.isDue(now), isFalse);
    final remote = RemoteItem.fromJson({'id': 'remote', 'user_id': 'user-b', 'type': 'link', 'favorite': false,
      'status': 'deferred', 'return_at': now.toUtc().toIso8601String(), 'created_at': now.toUtc().toIso8601String(),
      'updated_at': now.toUtc().toIso8601String()});
    await local.applyRemote(remote, now);
    expect((await db.itemById('remote'))!.returnAt?.toUtc(), now.toUtc());
    expect((await repo.watchAllItems().first).map((i) => i.id), ['task']);
    await service.save(CapturePayload.fromValue('Unscheduled share', id: 'share', source: CaptureSource.iosShare));
    expect((await db.itemById('share'))!.status, 'deferred');
    expect((await db.itemById('share'))!.returnAt, isNull);
  });

  test('v13 migration keeps old Inbox visible and saved/archived intact on restart', () async {
    final dir = await Directory.systemTemp.createTemp('return_schedule');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');
    final db = AppDatabase(NativeDatabase(file));
    for (final status in ['inbox', 'saved', 'archived']) {
      await db.saveItem(ItemsCompanion.insert(id: status, status: Value(status),
        createdAt: now, updatedAt: now));
    }
    await db.close();
    final raw = sqlite.sqlite3.open(file.path);
    raw.execute('ALTER TABLE items DROP COLUMN return_at');
    raw.execute('PRAGMA user_version = 13'); raw.close();
    final migrated = AppDatabase(NativeDatabase(file));
    expect((await migrated.itemById('inbox'))!.status, 'deferred');
    expect((await migrated.itemById('inbox'))!.returnAt, now);
    expect((await migrated.itemById('saved'))!.status, 'saved');
    expect((await migrated.itemById('archived'))!.status, 'archived');
    await migrated.close();
    final reopened = AppDatabase(NativeDatabase(file));
    expect((await reopened.itemById('inbox'))!.returnAt, now); await reopened.close();
  });

  testWidgets('clock wakes Inbox at deadline and on resume, rescheduling hides it', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    var current = DateTime(2026, 9, 16, 10);
    await db.saveItem(ItemsCompanion.insert(id: 'timed', status: const Value('deferred'),
      returnAt: Value(current.add(const Duration(minutes: 5))), createdAt: current, updatedAt: current));
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db), guestModeProvider.overrideWith((ref) => true),
      scheduleNowProvider.overrideWithValue(() => current),
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp(home: Consumer(
      builder: (_, ref, _) => Text('${ref.watch(inboxItemsProvider).valueOrNull?.length ?? 0} due')))));
    await tester.pumpAndSettle(); expect(find.text('0 due'), findsOneWidget);
    current = current.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5)); await tester.pumpAndSettle();
    expect(find.text('1 due'), findsOneWidget);
    await tester.runAsync(() => container.read(itemRepositoryProvider).reschedule('timed', current.add(const Duration(hours: 1))));
    await tester.pumpAndSettle(); expect(find.text('0 due'), findsOneWidget);
    current = current.add(const Duration(hours: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle(); expect(find.text('1 due'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink()); container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.runAsync(db.close);
  });

  testWidgets('picker defaults to Someday and displays resolved time', (tester) async {
    DateTime? value;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(builder: (context, setState) =>
      ReturnTimePicker(value: value, onChanged: (time) => setState(() => value = time))))));
    expect(find.text('Choose when · Someday'), findsOneWidget);
    await tester.tap(find.text('Tomorrow')); await tester.pumpAndSettle();
    expect(value, isNotNull); expect(value!.isUtc, isTrue); expect(value!.toLocal().hour, 9);
    await tester.tap(find.text('Someday')); await tester.pumpAndSettle(); expect(value, isNull);
  });
}
